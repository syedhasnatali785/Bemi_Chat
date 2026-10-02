// Cloudflare Worker — three endpoints, all requiring a Firebase ID token:
//
//   GET  /turn-credentials     -> Metered TURN credentials
//   POST /send-notification    -> sends an FCM push (replaces the two
//                                 Firestore-triggered Cloud Functions)
//   POST /ai-chat               -> chat completion via Cloudflare Workers AI
//
// Why a client-triggered Worker instead of a Firestore-triggered Cloud
// Function: Cloudflare has no Firestore trigger mechanism, so the thing
// that used to fire "on new chat message" / "on new call doc" now has to
// be an explicit call the client makes right after writing that document.
// Trade-off worth knowing: if the sender's app dies between writing the
// Firestore doc and this call completing, no push goes out — the message/
// call itself is still saved, only the notification is missed. A Cloud
// Function trigger doesn't have that gap, since it fires from Firestore
// itself, not from the client.
//
// /ai-chat needs no external API key — Workers AI is a native Cloudflare
// resource, billed to your Cloudflare account and invoked via an `AI`
// binding rather than a fetched-and-secret-stored key. Add this to
// wrangler.toml (or wrangler.jsonc):
//
//   [ai]
//   binding = "AI"
//
// The Firebase-auth check on this endpoint isn't for key-hiding, then —
// it's to stop a stranger from hitting your Worker directly and running
// up your Workers AI usage on your account.
//
// Setup:
//   npm install jose
//   wrangler secret put FIREBASE_PROJECT_ID
//   wrangler secret put METERED_API_KEY
//   wrangler secret put METERED_APP_NAME
//   wrangler secret put FCM_SERVICE_ACCOUNT_EMAIL     # from the service
//   wrangler secret put FCM_SERVICE_ACCOUNT_PRIVATE_KEY  # account JSON —
//     Firebase Console > Project Settings > Service Accounts >
//     Generate new private key. Paste client_email into the first secret
//     and the full private_key (including the BEGIN/END lines, real
//     newlines are fine — wrangler secret put accepts multi-line input)
//     into the second.
//   wrangler deploy
//
// The client calls all three endpoints with:  Authorization: Bearer <Firebase ID token>

import {
  importX509,
  jwtVerify,
  decodeProtectedHeader,
  SignJWT,
  importPKCS8,
} from "jose";

const AI_MODEL = "@cf/qwen/qwen3-30b-a3b-fp8";
const AI_SYSTEM_PROMPT =
  "You are a helpful, concise assistant inside a chat app. Keep replies " +
  "friendly and to the point.";
const AI_MAX_HISTORY_MESSAGES = 20; // basic cost/abuse guard
const AI_MAX_MESSAGE_LENGTH = 4000; // characters

const GOOGLE_CERTS_URL =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

async function verifyFirebaseIdToken(idToken, projectId) {
  const {kid} = decodeProtectedHeader(idToken);
  if (!kid) throw new Error("Token missing key id");

  const certsRes = await fetch(GOOGLE_CERTS_URL);
  const certs = await certsRes.json();
  const cert = certs[kid];
  if (!cert) throw new Error("Unknown signing key");

  const publicKey = await importX509(cert, "RS256");
  const {payload} = await jwtVerify(idToken, publicKey, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  return payload; // payload.sub is the Firebase uid
}

// ---------------------------------------------------------------------
// Service-account auth, shared by the FCM send and the Firestore lookup.
// cloud-platform scope covers both APIs with one token.
// ---------------------------------------------------------------------
async function getServiceAccountAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  const pem = env.FCM_SERVICE_ACCOUNT_PRIVATE_KEY
    .trim()
    .replace(/^["']|["',]$/g, "")   // stray quotes or trailing comma
    .replace(/\\n/g, "\n");         // literal \n -> real newline
  const privateKey = await importPKCS8(pem, "RS256");

  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/cloud-platform",
  })
    .setProtectedHeader({alg: "RS256"})
    .setIssuer(env.FCM_SERVICE_ACCOUNT_EMAIL)
    .setSubject(env.FCM_SERVICE_ACCOUNT_EMAIL)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`Failed to get access token: ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token;
}

// Looks the recipient's token up server-side rather than trusting a token
// string supplied by the client — the client only ever names *who* to
// notify (a uid), never *how* (a raw device token).
async function fetchFcmToken(env, accessToken, uid) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${uid}`,
    {headers: {Authorization: `Bearer ${accessToken}`}},
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Firestore lookup failed: ${await res.text()}`);
  const doc = await res.json();
  return doc.fields?.fcmToken?.stringValue || null;
}

async function sendFcmMessage(env, accessToken, {token, notification, data}) {
  const message = {
    message: {
      token,
      ...(notification ? {notification} : {}),
      data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)]),
      ),
      android: {priority: "high"},
      apns: {
        headers: {"apns-priority": "10"},
        payload: {
          aps: notification
            ? {sound: "default"}
            : {"content-available": 1}, // data-only push, e.g. an incoming call
        },
      },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    },
  );
  if (!res.ok) throw new Error(`FCM send failed: ${await res.text()}`);
  return res.json();
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    const authHeader = request.headers.get("Authorization") || "";
    const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    if (!idToken) return new Response("Missing bearer token", {status: 401});

    try {
      await verifyFirebaseIdToken(idToken, env.FIREBASE_PROJECT_ID);
    } catch (err) {
      return new Response(`Unauthorized: ${err.message}`, {status: 401});
    }

    // -------------------------------------------------------------
    // GET /turn-credentials
    // -------------------------------------------------------------
    if (url.pathname === "/turn-credentials" && request.method === "GET") {
      const meteredUrl =
        `https://${env.METERED_APP_NAME}.metered.live/api/v1/turn/credentials` +
        `?apiKey=${env.METERED_API_KEY}`;

      const meteredRes = await fetch(meteredUrl);
      if (!meteredRes.ok) {
        return new Response("Failed to fetch TURN credentials", {status: 502});
      }
      const iceServers = await meteredRes.json();
      return new Response(JSON.stringify({iceServers}), {
        headers: {"Content-Type": "application/json", "Cache-Control": "no-store"},
      });
    }

    // -------------------------------------------------------------
    // POST /send-notification
    // Body: { recipientUid, notification?: {title, body}, data: {...} }
    // Omit `notification` for a silent/data-only push (used for calls).
    // -------------------------------------------------------------
    if (url.pathname === "/send-notification" && request.method === "POST") {
      let body;
      try {
        body = await request.json();
      } catch {
        return new Response("Invalid JSON body", {status: 400});
      }

      const {recipientUid, notification, data} = body;
      if (!recipientUid || typeof recipientUid !== "string") {
        return new Response("Missing recipientUid", {status: 400});
      }

      try {
        const accessToken = await getServiceAccountAccessToken(env);
        const token = await fetchFcmToken(env, accessToken, recipientUid);
        if (!token) {
          // Recipient has no registered device — not an error, just nothing to do.
          return new Response(JSON.stringify({ok: true, skipped: "no-token"}), {
            headers: {"Content-Type": "application/json"},
          });
        }

        await sendFcmMessage(env, accessToken, {token, notification, data});
        return new Response(JSON.stringify({ok: true}), {
          headers: {"Content-Type": "application/json"},
        });
      } catch (err) {
        return new Response(`Failed to send notification: ${err.message}`, {
          status: 502,
        });
      }
    }

    // -------------------------------------------------------------
    // POST /ai-chat
    // Body: { messages: [{ role: 'user'|'assistant', content: string }, ...] }
    // Returns: { reply: string }
    // -------------------------------------------------------------
    if (url.pathname === "/ai-chat" && request.method === "POST") {
      let body;
      try {
        body = await request.json();
      } catch {
        return new Response("Invalid JSON body", {status: 400});
      }

      const history = Array.isArray(body.messages) ? body.messages : null;
      if (!history || history.length === 0) {
        return new Response("Missing messages", {status: 400});
      }
      if (history.length > AI_MAX_HISTORY_MESSAGES) {
        return new Response("Conversation too long", {status: 400});
      }
      for (const m of history) {
        if (
          typeof m.content !== "string" ||
          m.content.length > AI_MAX_MESSAGE_LENGTH ||
          (m.role !== "user" && m.role !== "assistant")
        ) {
          return new Response("Invalid message in history", {status: 400});
        }
      }

      try {
        const result = await env.AI.run(AI_MODEL, {
          messages: [
            {role: "system", content: AI_SYSTEM_PROMPT},
            ...history.map((m) => ({role: m.role, content: m.content})),
          ],
        });

        // Workers AI chat models return { response: "..." }.
        const reply = result.response ?? "";
        return new Response(JSON.stringify({reply}), {
          headers: {"Content-Type": "application/json"},
        });
      } catch (err) {
        return new Response(`AI request failed: ${err.message}`, {status: 502});
      }
    }

    return new Response("Not found", {status: 404});
  },
};