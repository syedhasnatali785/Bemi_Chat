import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus { ringing, accepted, declined, ended, missed }

CallStatus _statusFromString(String? s) {
  return CallStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => CallStatus.ended,
  );
}

/// A voice call document at calls/{callId}.
class CallModel {
  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String calleeName;
  final CallStatus status;
  final DateTime? createdAt;

  factory CallModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    return CallModel(
      id: doc.id,
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? '',
      calleeId: data['calleeId'] as String? ?? '',
      calleeName: data['calleeName'] as String? ?? '',
      status: _statusFromString(data['status'] as String?),
      createdAt: ts?.toDate(),
    );
  }
}
