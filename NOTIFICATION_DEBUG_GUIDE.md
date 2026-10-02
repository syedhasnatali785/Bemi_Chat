# Notification & Call Debug Guide

## Overview
Comprehensive logging has been added throughout the notification and call flow. Use these logs to diagnose why messages and calls aren't delivering notifications.

---

## What Was Added

### 1. **Token Sync Logging** 
   - **File:** `lib/services/notification_service.dart`
   - **Prefix:** 🔐 FCM TOKEN
   - **What it shows:** When token is fetched and saved to Firestore
   
   ```
   🔐 FCM TOKEN: Got token from Firebase Messaging: AbCdEf...
   🔐 FCM TOKEN: ✓ Saved token for user user123 to Firestore
   ```

### 2. **Push Request Logging**
   - **File:** `lib/services/push_notf_servic.dart`
   - **Prefix:** 🔔 PUSH
   - **What it shows:** Request sent to Worker and response received
   
   ```
   🔔 PUSH: Sending to Worker → recipient: user123, has_notification: true
   🔔 PUSH: ✓ Worker accepted ({"ok":true})
   ```

### 3. **Message Notification Logging**
   - **File:** `lib/repository/fb_chat_repo.dart`
   - **Prefix:** 📨 NOTIFICATION
   - **What it shows:** When chat notifications are triggered
   
   ```
   📨 NOTIFICATION: Sending push to user123 from Alice
   📨 NOTIFICATION: Push sent successfully to user123
   ❌ NOTIFICATION ERROR: Failed to send push: [error details]
   ```

### 4. **Call Logging**
   - **File:** `lib/services/call_services/call_service.dart`
   - **Prefix:** ☎️ CALL
   - **What it shows:** Call initiation and notification sending
   
   ```
   ☎️ CALL: Starting outgoing call to user456 (Bob)
   ☎️ CALL: Firestore call doc created, sending push notification
   ```

### 5. **Message Reception Logging**
   - **File:** `lib/services/notification_service.dart`
   - **Prefix:** 📬 MESSAGE / 📬 SHOW / 📬 SKIP
   - **What it shows:** When the app receives FCM messages
   
   ```
   📬 MESSAGE RECEIVED (foreground): msg123
   📬 → Chat notification from user456
   📬 SHOW: Title="Alice" Body="Hello there"
   ```

---

## How to Debug

### Scenario 1: Message Sent But No Notification on Recipient

**Steps:**
1. Open two phones/emulators (User A and User B)
2. Check logs on User B's device (look for 🔐 FCM TOKEN logs)
3. User A sends message to User B
4. Check User A's logs for 🔔 PUSH logs
5. Check User B's logs for 📬 MESSAGE logs

**What to look for:**

✅ **Token saved:**
```
🔐 FCM TOKEN: ✓ Saved token for user user_b_id to Firestore
```

✅ **Push sent successfully:**
```
🔔 PUSH: ✓ Worker accepted ({"ok":true})
📨 NOTIFICATION: Push sent successfully to user_b_id
```

✅ **Message received on B's device:**
```
📬 MESSAGE RECEIVED (foreground): msg_id
📬 SHOW: Title="Alice" Body="Hello there"
```

❌ **Problem: Token not saved (Token sync didn't complete)**
```
🔐 FCM TOKEN: ⚠️ No current user — skipping token save
```
→ User B wasn't authenticated when token sync ran

❌ **Problem: Worker couldn't find token**
```
🔔 PUSH: ✓ Worker accepted ({"ok":true,"skipped":"no-token"})
```
→ User B's token wasn't in Firestore yet

❌ **Problem: Message received but no notification shown**
```
📬 MESSAGE RECEIVED (foreground): msg_id
📬 SKIP: No notification block in message
```
→ Message was sent without notification (shouldn't happen for chat)

---

### Scenario 2: Call Initiated But Recipient Doesn't See CallKit

**Steps:**
1. User A initiates call to User B
2. Check User A's logs for ☎️ CALL logs
3. Check User B's logs for 📬 MESSAGE logs

**What to look for:**

✅ **Call initiated correctly:**
```
☎️ CALL: Starting outgoing call to user_b_id (Bob)
☎️ CALL: Firestore call doc created, sending push notification
🔔 PUSH: ✓ Worker accepted ({"ok":true})
```

✅ **CallKit shown on recipient:**
```
📬 MESSAGE RECEIVED (foreground): call_id
📬 → Call notification: callId=call_doc_123
```

❌ **Problem: Call initiated from inbox with empty otherUserId** (FIXED)
```
☎️ CALL: Starting outgoing call to  (empty!)
🔔 PUSH: Sending to Worker → recipient: , has_notification: false
🔔 PUSH: ✗ Failed with 400: Missing recipientUid
```
→ This was the bug we fixed—otherUserId is now passed correctly

---

## Critical Time Sequences to Check

### Time Sequence 1: Fresh Login → Call
```
[User launches app]
  ↓ [UI renders]
  ↓ [addPostFrameCallback → NotificationService.initialize()]
  ↓ [REQUEST PERMISSION - user grants] ← USER ACTION
  ↓ [_syncToken() fetches token]
  ↓ 🔐 FCM TOKEN: ✓ Saved token...
  ↓ [User clicks call button]
  ↓ ☎️ CALL: Starting outgoing call...
  ↓ 🔔 PUSH: ✓ Worker accepted
```
→ If push sent BEFORE 🔐 logs appear, Worker won't find token!

### Time Sequence 2: Message Sent to Offline User
```
[User B's device is off / logged out]
```
→ Token won't be in Firestore
→ Worker gets {ok: true, skipped: "no-token"}
→ FCM doesn't send anything
→ This is EXPECTED BEHAVIOR for offline users

---

## What Each Response From Worker Means

### `{"ok":true}` 
**Meaning:** Push was sent to FCM successfully
→ Notification should arrive (unless permission not granted)

### `{"ok":true,"skipped":"no-token"}`
**Meaning:** Recipient has no registered device token in Firestore
→ Recipient never logged in, OR token not synced yet, OR device uninstalled app
→ This is NOT an error, just nothing to do

### `{"statusCode":400,"message":"Missing recipientUid"}`
**Meaning:** Empty or missing recipientUid in request
→ Bug on Flutter side (e.g., empty otherUserId) ← **FIXED**

### `{"statusCode":502,"message":"Failed to send notification: ..."}`
**Meaning:** Worker error contacting FCM or Firestore
→ Check Worker configuration (credentials, permissions)

---

## Testing Checklist

- [ ] Fresh login, immediate call → notification arrives
- [ ] Message sent, recipient app in foreground → notification pops up
- [ ] Message sent, recipient app backgrounded → notification in tray
- [ ] Call initiated from inbox → CallKit rings (otherUserId bug FIXED)
- [ ] Call initiated from search → CallKit rings (should already work)
- [ ] Message sent before token synced → Check logs for skipped reason
- [ ] Permission denied on device → Logs show skipped notification
- [ ] Network error to Worker → Logs show retry behavior

---

## Example Log Output (Successful Flow)

### User B receives message from User A:

**User B's logs (at app startup):**
```
🔐 FCM TOKEN: Got token from Firebase Messaging: AbCdEf1234567890...
🔐 FCM TOKEN: ✓ Saved token for user user_b_id to Firestore
📱 Notification permission: AuthorizationStatus.authorized
```

**User A sends message:**
```
📨 NOTIFICATION: Sending push to user_b_id from Alice
🔔 PUSH: Sending to Worker → recipient: user_b_id, has_notification: true, endpoint: [worker]
🔔 PUSH: ✓ Worker accepted ({"ok":true})
📨 NOTIFICATION: Push sent successfully to user_b_id
```

**User B receives it (if app in foreground):**
```
📬 MESSAGE RECEIVED (foreground): abc123def456
📬 → Chat notification from user_a_id
📬 SHOW: Title="Alice" Body="Hello there"
[Notification pops up on User B's screen ✓]
```

---

## If Notifications Still Don't Work

### Step 1: Check Token Exists
```
Firestore Console → Collections → users → [user_id] → Check for "fcmToken" field
```
If missing: User's token never synced (auth timing issue)

### Step 2: Check Device Permissions
```
Android: Settings → Apps → BemiChat → Permissions → Notifications
iOS: Settings → Notifications → BemiChat → Allow Notifications
```

### Step 3: Check Android Notification Channel
```
Android: Settings → Apps → BemiChat → Notifications → Chat messages
```
Must be set to "On"

### Step 4: Recreate Scenario with Logs
1. Clear app cache/restart
2. Login and wait for 🔐 FCM TOKEN logs
3. Send message/call
4. Share ALL logs (🔔 🔐 📨 ☎️ 📬 prefixes) in bug report

---

## What These Fixes Accomplished

1. ✅ **Added comprehensive logging** to see exact failure points
2. ✅ **Fixed inbox otherUserId** (was empty string → now actual user ID)
3. ✅ **Exposed silent failures** (Worker "skipped" responses now visible)
4. ✅ **Clear error messages** (all errors logged, not swallowed)

The real issues were:
- **Hidden race condition** between token sync and message send
- **Silent failures** with no user/developer feedback
- **Empty otherUserId** in inbox navigation

All are now visible via logs and one is fixed!
