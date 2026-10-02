import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupRepository {
  ProfileSetupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// True if no other user already has this handle.
  Future<bool> isHandleAvailable(String handle, {required String myUid}) async {
    final snap = await _firestore
        .collection('users')
        .where('handle', isEqualTo: handle)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return true;
    return snap.docs.first.id ==
        myUid; // owning your own current handle counts as available
  }

  /// Creates/updates the `users/{uid}` doc and the Firebase Auth display name.
  Future<void> saveProfile({
    required String uid,
    required String displayName,
    required String handle,
    required String isCompleted,
    String photoUrl = '',
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'handle': handle,
      'photoUrl': photoUrl,
      'isCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
  }
}
