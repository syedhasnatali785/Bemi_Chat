# Testing Strategy - Step by Step

## What You Were Missing: A Complete View

You had THREE FAILURES happening at once:

```
┌─────────────────────────────────────────────────────────────┐
│                    User A Sends Message                     │
│                     to User B                               │
└────────────────┬────────────────────────────────────────────┘
                 ↓
         ┌───────────────────┐
         │ Is otherUserId   │
         │ empty string?     │
         └───┬───────────┬───┘
      YES │       │ NO
         ↓       ↓
    ❌ INBOX  ✅ SEARCH
    (empty)    (correct)
         │       │
         │       └─────────────┐
         │                     ↓
         │           ┌──────────────────────┐
         │           │ Send to Worker with  │
         │           │ recipientUid = "uid" │
         │           └─────────┬────────────┘
         │                     ↓
         │           ┌──────────────────────┐
         │           │ Is token in          │
         │           │ Firestore?           │
         │           └───┬────────────┬─────┘
         │          YES  │      │ NO
         │              ↓       ↓
         │           ✅ OK  ❌ SILENT FAIL
         │           FCM   (skipped)
         │           sends
         │              │       │
         │              ↓       ↓
         │           📬 NOTI.  No notif
         │           SHOWS     (user confused)
         │              │
         │              ↓
         │           ✅ USER SEES
         │              IT
         │
         ↓
    ❌ WORKER REJECTS
       (Missing recipientUid)
       = 400 ERROR
       = CALLER WAITS FOREVER
```

---

## The Real Issues - Now Visible

### Issue #1: Empty otherUserId ✅ FIXED
**Status:** You pass empty string from inbox
**Evidence:** Check inbox_screen.dart line 58
**Fix:** Now passes actual user ID

### Issue #2: Token Race ⚠️ HIDDEN (Now Loggable)
**Status:** Message sent before token synced
**Evidence:** Look for 🔔 PUSH logs with `skipped: no-token`
**Cause:** Token saved in addPostFrameCallback, not before UI renders

### Issue #3: Silent Failures ✅ NOW VISIBLE
**Status:** Errors swallowed, no logging
**Evidence:** No logs at all = something failed
**Fix:** Now logs everything with 🔐 🔔 📨 ☎️ 📬 prefixes

---

## Testing Plan - Execute in Order

### Test 1: Verify Inbox Fix
```
Setup:
  - Two devices: User A, User B
  - Both logged in, at inbox screen

Action:
  - User A clicks User B in inbox → Opens ChatScreen
  - Check URL bar: Should show otherUserId=<user_b_id>
  - NOT otherUserId= (empty)

Expected:
  - URL has correct otherUserId
  - Can tap call button without error

If Fails:
  - Check logs for ☎️ CALL errors
  - Check Worker logs for "Missing recipientUid"
```

### Test 2: Verify Call Works
```
Setup:
  - User A at ChatScreen with User B
  - User B has app open (or backgrounded)

Action:
  - User A taps call button

Expected Logs on User A's device:
  ☎️ CALL: Starting outgoing call to <user_b_id>
  ☎️ CALL: Firestore call doc created, sending push notification
  🔔 PUSH: Sending to Worker → recipient: <user_b_id>
  🔔 PUSH: ✓ Worker accepted ({"ok":true})

Expected on User B's device:
  📬 MESSAGE RECEIVED (foreground): <call_id>
  📬 → Call notification: callId=<call_id>
  [CallKit rings]

If Fails:
  - Check User A logs for 🔔 PUSH showing "skipped: no-token"
  - Check User B logs for 🔐 FCM TOKEN logs
  - If 🔐 logs come AFTER call was made → Race condition!
```

### Test 3: Verify Message Notification
```
Setup:
  - User A at ChatScreen with User B
  - User B has app open in foreground

Action:
  - User A types message and sends

Expected Logs on User A's device:
  📨 NOTIFICATION: Sending push to <user_b_id> from <user_a_name>
  🔔 PUSH: Sending to Worker → recipient: <user_b_id>, has_notification: true
  🔔 PUSH: ✓ Worker accepted ({"ok":true})
  📨 NOTIFICATION: Push sent successfully to <user_b_id>

Expected on User B's device:
  📬 MESSAGE RECEIVED (foreground): <msg_id>
  📬 → Chat notification from <user_a_id>
  📬 SHOW: Title="<user_a_name>" Body="<message>"
  [Notification banner pops up]

If Fails:
  - Check for 📬 MESSAGE RECEIVED at all
    - If NOT present: Network issue or permission denied
    - If present but 📬 SKIP: No notification block in message
  - Check for 🔔 PUSH showing "skipped: no-token"
    - If yes: Token not yet synced
```

### Test 4: Verify Token Sync Timing
```
Setup:
  - Fresh app install
  - No prior login

Action:
  1. Launch app
  2. Watch logs carefully
  3. Login
  4. Continue watching logs
  5. Immediately send message/call (within 2 seconds)

Expected Logs:
  [App renders]
  [Firebase init]
  [UI shows login screen]
  [User logs in]
  🔐 FCM TOKEN: Got token from Firebase Messaging: ...
  🔐 FCM TOKEN: ✓ Saved token for user <user_id> to Firestore

Then:
  [User sends message]
  📨 NOTIFICATION: Sending push...
  🔔 PUSH: ✓ Worker accepted ({"ok":true})

If Race Condition Detected:
  🔔 PUSH: ✓ Worker accepted ({"ok":true,"skipped":"no-token"})
  [appears before]
  🔐 FCM TOKEN: ✓ Saved token...
  
  → This means token sync hadn't completed yet!
```

### Test 5: Verify Permission Handling
```
Setup:
  - Fresh app install
  - Or revoked notification permission

Action:
  1. Launch app
  2. When prompted for permission
  3. Deny the permission
  4. Check logs
  5. Try to send message

Expected Logs:
  📱 Notification permission: <status>
  (If denied)
  📱 Notification permission: AuthorizationStatus.denied

Then:
  [Message sent]
  📨 NOTIFICATION: Sending push...
  🔔 PUSH: ✓ Worker accepted ({"ok":true})
  But:
  📬 MESSAGE NOT RECEIVED on recipient's device

Reason:
  - Permission denied = device won't show notification
  - This is OS-level, not your app's fault
  - But user should be told to enable permissions
```

---

## Log Reading Guide

### Good Signs (Notification Will Work)
```
✅ 🔐 FCM TOKEN: ✓ Saved token... [appears before message]
✅ 🔔 PUSH: ✓ Worker accepted ({"ok":true})
✅ 📨 NOTIFICATION: Push sent successfully to <user_id>
✅ 📬 MESSAGE RECEIVED (foreground): <id>
✅ 📬 SHOW: Title="..." Body="..."
✅ 📱 Notification permission: AuthorizationStatus.authorized
```

### Bad Signs (Notification Will NOT Work)
```
❌ 🔐 FCM TOKEN: ⚠️ No current user — skipping token save
   → User not authenticated, token not saved

❌ 🔔 PUSH: ✓ Worker accepted ({"ok":true,"skipped":"no-token"})
   → Token wasn't in Firestore yet (race condition)

❌ 🔔 PUSH: ✗ Failed with 400: Missing recipientUid
   → Empty otherUserId (should be fixed now)

❌ 🔔 PUSH: ✗ Failed with 502: FCM send failed...
   → Worker error, check Worker credentials

❌ 📬 SKIP: No notification block in message
   → Message sent without notification (shouldn't happen for chat)

❌ 📱 Notification permission: AuthorizationStatus.denied
   → User denied permission, OS won't show notifications

❌ [No logs at all for 📨 NOTIFICATION]
   → Message sending code didn't run at all
```

---

## Quick Diagnostic Checklist

Run through this when notifications fail:

```
[ ] Step 1: Check User B has token
    Firestore Console → collections → users → [user_b_id]
    → Should have "fcmToken" field with a string value
    → If missing: Token sync never completed or user not authenticated

[ ] Step 2: Check app logs for 🔔 PUSH response
    → {"ok":true} = Sent to FCM
    → {"ok":true,"skipped":"no-token"} = Token not found (race condition)
    → {"statusCode":400,...} = Invalid request (empty otherUserId, now fixed)
    → {"statusCode":502,...} = Worker error

[ ] Step 3: Check app logs for 📬 MESSAGE RECEIVED on recipient
    → If present: Device got FCM message, check if notification showed
    → If absent: Device didn't get FCM at all (check permissions, network)

[ ] Step 4: Check device notification settings
    Android: Settings → Apps → BemiChat → Notifications
    iOS: Settings → Notifications → BemiChat
    → If disabled: No notifications will show, even if sent

[ ] Step 5: Check if notification permission was granted
    Look for 📱 Notification permission: AuthorizationStatus logs
    → denied = Permission prompt wasn't shown or user rejected
    → authorized = Permission granted (good)

[ ] Step 6: Restart app and try again
    → Sometimes token gets stuck
    → Fresh start ensures clean initialization
```

---

## What Each Emoji Log Means

| Emoji | What It Means | Action |
|-------|--------------|--------|
| 🔐 FCM TOKEN | Token fetch/save progress | Good: Should appear early in logs |
| 🔔 PUSH | Request to Worker | Good: Should show ✓ Worker accepted |
| 📨 NOTIFICATION | Chat notification send | Good: Should show "Push sent successfully" |
| ☎️ CALL | Call initiation | Good: Should show correct calleeId |
| 📬 MESSAGE | FCM message received | Good: Should appear when device gets push |
| ❌ | Error | Bad: Indicates failure point |
| ⚠️ | Warning | Caution: Might cause issues |

---

## Example: Complete Success Flow

```
=== User B Logs (Fresh Login) ===
🔐 FCM TOKEN: Got token from Firebase Messaging: AbCdEf...
🔐 FCM TOKEN: ✓ Saved token for user user_b_id to Firestore
📱 Notification permission: AuthorizationStatus.authorized

=== User A Sends Message ===
📨 NOTIFICATION: Sending push to user_b_id from Alice
🔔 PUSH: Sending to Worker → recipient: user_b_id, has_notification: true
🔔 PUSH: ✓ Worker accepted ({"ok":true})
📨 NOTIFICATION: Push sent successfully to user_b_id

=== User B's Device ===
[Notification banner pops up: "Alice: Hello!"]
📬 MESSAGE RECEIVED (foreground): msg_123
📬 → Chat notification from user_a_id
📬 SHOW: Title="Alice" Body="Hello!"

=== Result ===
✅ User B sees notification immediately
✅ User B can tap and navigate to chat
✅ Everything works!
```

---

## How to Share Logs for Help

When something doesn't work:

1. **Clear app cache:**
   ```
   Android: Settings → Apps → BemiChat → Clear Cache
   iOS: Offload App, then reinstall
   ```

2. **Restart with fresh login**

3. **Reproduce the issue** (send message or make call)

4. **Copy ALL logs** with these prefixes:
   - 🔐 FCM TOKEN
   - 🔔 PUSH
   - 📨 NOTIFICATION
   - ☎️ CALL
   - 📬 MESSAGE
   - Any ❌ errors

5. **Include device info:**
   - Notification permission status
   - Android/iOS version
   - Whether app was foreground or background

6. **Share the logs in order with timestamps**

This will show exactly where and why the notification failed!
