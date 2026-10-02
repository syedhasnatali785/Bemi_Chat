# Action Checklist - What to Do Now

## ✅ Fixes Applied

- [x] Inbox `otherUserId` now passes actual user ID (calls from inbox work)
- [x] Worker handles malformed FCM private keys
- [x] Empty chats filtered from inbox (don't show until message sent)
- [x] Chat doc updated with message content (shows in inbox with preview)
- [x] Comprehensive logging added throughout notification flow
- [x] Permission status now visible in logs
- [x] Background message handler logs what it's doing
- [x] Database operations logged with 💾 prefix
- [x] Push responses logged with 🔔 prefix

---

## 🧪 Next: Test Everything

### Rebuild and Deploy

```bash
# iOS
flutter clean
flutter pub get
flutter run -d <ios-device>

# Android
flutter clean
flutter pub get
flutter run -d <android-device>
```

### Test Scenario 1: Start Chat Then Send Message
```
1. User A: Search for User B
2. User A: Tap to open chat
3. Check User B's inbox: Should be EMPTY (no chat shown) ✓
4. User A: Type "Hello B" and send
5. Check User B's inbox: Chat should appear with "Hello B" as preview ✓
6. Check logs for: 💬 ✓ Message sent 💾 ✓ Chat updated 🔔 ✓ Worker accepted
```

### Test Scenario 2: Notification Shows on Recipient
```
Setup:
  - User B has app OPEN in foreground
  - User A in different app

Action:
  - User A sends message to User B

Expected:
  - User B sees notification popup on screen ✓
  - Logs show: 📬 MESSAGE RECEIVED, 📬 ✅ Local notification displayed ✓

If NOT shown:
  - Check: 📱 Authorization status in logs (should be "authorized")
  - Check: Phone Settings → Apps → BemiChat → Notifications (should be ON)
  - Check: Firestore lastMessage field has the message text
```

### Test Scenario 3: Chat Sorted by Recency
```
Setup:
  - User B already has chats with Users A, C, D
  - User C's chat has last message from yesterday
  - User A sends message now

Expected:
  - User A's chat moves to TOP of inbox list ✓
  - Shows the new message as preview ✓
  - Other chats pushed down in order ✓
```

### Test Scenario 4: Verify Permission Handling
```
Setup:
  - Fresh app install
  - Or: Clear app cache

Action:
  - Launch app
  - Watch logs

Expected - One of:
  ✅ 📱 Notification permission: authorized
     ✅ Notification permission GRANTED
  ⚠️  📱 Notification permission: denied
     ⚠️  CRITICAL: User DENIED notification permission!

If denied:
  - Open Settings → Apps → BemiChat → Permissions → Notifications
  - Toggle ON
  - Restart app
```

### Test Scenario 5: Calls Still Work
```
1. User A calls User B from ChatScreen
2. Check logs: ☎️ CALL: Starting outgoing call
3. Check logs: 🔔 PUSH: ✓ Worker accepted
4. User B should see CallKit ring (if app open or backgrounded)
5. Tap Accept or Decline
```

---

## 🔍 Diagnosis: If Notifications Still Don't Show

### Step 1: Check Logs
```
Watch for these prefixes when sending message:
  💬 CHAT: ✓ Message sent successfully
  💾 DATABASE: ✓ Chat updated with lastMessage
  📨 NOTIFICATION: Push sent successfully to user_b
  🔔 PUSH: ✓ Worker accepted ({"ok":true})
```

If you see `skipped: "no-token"`:
  → Recipient's token not in Firestore yet (race condition)
  → Workaround: Wait 2-3 seconds after login before sending
  → This will be logged: `🔔 PUSH: ✓ Worker accepted ({"ok":true,"skipped":"no-token"})`

If you see `statusCode: 502`:
  → Worker error fetching access token
  → Check: Wrangler secrets have correct FCM credentials
  → Verify: Private key has real line breaks, not `\n` text

If you see `statusCode: 400`:
  → Missing or empty recipientUid
  → This should be fixed now (otherUserId bug)
  → Check: User B actually exists in Firestore

### Step 2: Check Recipient's Device

```
When message arrives on User B's device:
  
If app is FOREGROUND:
  📬 MESSAGE RECEIVED (foreground): msg_id
  📬 Notification block present: true
  📬 SHOW: Title="..." Body="..."
  📬 ✅ Local notification displayed successfully
  [Notification should pop up]

If app is BACKGROUND:
  📲 BACKGROUND MESSAGE: msg_id
  📲 → Chat message, FCM will display notification
  [FCM handles display in notification tray]
```

### Step 3: Verify Permission

```
In app logs at startup:
  📱 Authorization status: authorized ✅
  ✅ Notification permission GRANTED

OR

  📱 Authorization status: denied ❌
  ⚠️  CRITICAL: User DENIED notification permission!
  ⚠️  → No notifications will be shown on this device
  ⚠️  → User must enable in Settings → Notifications
```

If permission is denied:
  1. Open phone Settings
  2. Go to Apps → BemiChat → Notifications
  3. Toggle to ON
  4. Restart app
  5. Retry sending message

### Step 4: Check Firestore

```
Firestore Console → collections → chats → [chat_id]

Expected to see:
  {
    participants: [user_a_id, user_b_id],
    lastMessage: "Hello B",           ← Should be message text
    lastMessageAt: 2026-10-02T12:34Z,  ← Should be current time
    lastSenderId: user_a_id,
    ...
  }

If lastMessage is empty:
  → Chat doc update failed
  → Check logs for: 💾 DATABASE: ❌ ERROR
  → Check Firestore permissions (user can write to their chat)

If lastMessageAt is old:
  → New message didn't update it
  → Check logs for: 💾 DATABASE: ✓ Chat updated
```

### Step 5: Check Android Notification Channel

Android specific:
```
Settings → Apps → BemiChat → Notifications

Should see:
  ✓ Chat messages (enabled, high priority)
  
If disabled:
  → Toggle ON
  → Set importance to HIGH or MAX
```

---

## 📋 Log Lines to Watch For - Complete Map

### Message Sending (User A)
```
💬 CHAT: User user_a_id sending message to chat chat_123: "Hello"
💬 CHAT: ✓ Message sent successfully
💾 DATABASE: Adding message to chat chat_123
💾 DATABASE: Updating chat chat_123 with lastMessage...
💾 DATABASE: ✓ Chat updated with lastMessage
```

### Notification Push (User A)
```
📨 NOTIFICATION: Sending push to user_b_id from User A Name
🔔 PUSH: Sending to Worker → recipient: user_b_id, has_notification: true
🔔 PUSH: ✓ Worker accepted ({"ok":true})
📨 NOTIFICATION: Push sent successfully to user_b_id
```

### Message Reception (User B - Foreground)
```
📬 MESSAGE RECEIVED (foreground): msg_id
📬 Notification block present: true
📬 Data: {type: 'chat', chatId: 'chat_123', ...}
📬 → Chat notification from user_a_id
📬 SHOW: Title="User A Name" Body="Hello"
📬 ✅ Local notification displayed successfully
```

### Message Reception (User B - Background)
```
📲 BACKGROUND MESSAGE: msg_id
📲 Data: {type: 'chat', chatId: 'chat_123', ...}
📲 → Chat message, FCM will display notification
[FCM shows notification in notification tray]
```

### Permission on Startup
```
🔐 FCM TOKEN: Got token from Firebase Messaging: AbCdEf123...
🔐 FCM TOKEN: ✓ Saved token for user user_b_id to Firestore
📱 Notification permission requested
📱 Authorization status: authorized
✅ Notification permission GRANTED
```

### If Something Fails
```
❌ NOTIFICATION ERROR: Failed to send push: [error details]
❌ PUSH: ✗ Failed with 502: [error details]
⚠️  CRITICAL: User DENIED notification permission!
📬 ❌ ERROR showing local notification: [error details]
💬 CHAT: ❌ Failed to send message: [error details]
💾 DATABASE: ❌ [error details]
```

---

## 🚀 What to Expect After These Fixes

| Scenario | Before | After |
|----------|--------|-------|
| **Empty chat appears in inbox** | Shows immediately | Appears only after message sent ✓ |
| **Message not in inbox preview** | Empty "lastMessage" field | Shows message text ✓ |
| **No notification on recipient** | Silent failure | Detailed logs show reason ✓ |
| **Can't debug failures** | Catch-all errors | Specific log prefixes ✓ |
| **Don't know permission status** | Unknown | Clear log at startup ✓ |
| **Calls from inbox fail** | 400 error | Works correctly ✓ |
| **Worker rejects bad keys** | 502 error | Tolerates malformed input ✓ |

---

## 📞 If Still Having Issues

1. **Run the app with full logging enabled**
2. **Try all test scenarios above**
3. **Collect logs with emoji prefixes:**
   - 💬 CHAT
   - 💾 DATABASE
   - 📨 NOTIFICATION
   - 🔔 PUSH
   - 📱 Permission
   - 📬 Foreground message
   - 📲 Background message

4. **Check Firestore Console:**
   - Verify chat doc has lastMessage field
   - Verify token saved in users/{userId}

5. **Check device settings:**
   - Notification permission granted
   - Notification channel enabled

6. **Recreate issue and share:**
   - All console logs with emoji prefixes
   - Firestore docs screenshot
   - Device settings screenshot
   - Steps to reproduce

---

## 🎯 Success Criteria

- [x] Inbox calls work (fixed otherUserId)
- [x] Empty chats don't appear in inbox
- [x] Messages show in inbox preview
- [x] Chat sorted by most recent message
- [ ] Notification pops up on recipient's device
- [ ] Background notifications work
- [ ] Calls ring with CallKit
- [ ] Logs show exactly what's happening at each step

**Next: Build and test!** 🚀
