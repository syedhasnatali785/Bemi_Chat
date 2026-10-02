import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal user profile, as stored in the `users` collection.
///
/// Expects a doc at `users/{uid}` shaped like:
/// { handle: "syed_dev", displayName: "Syed", photoUrl: "https://..." }
class SearchUserModel {
  const SearchUserModel({
    required this.uid,
    required this.handle,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String handle;
  final String displayName;
  final String photoUrl;

  factory SearchUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SearchUserModel(
      uid: doc.id,
      handle: data['handle'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
    );
  }
}
