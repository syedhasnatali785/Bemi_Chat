import 'dart:async';

import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/models/call_model.dart';
import 'package:bemichat/services/push_notf_servic.dart';
import 'package:bemichat/services/turn_credential_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Voice-only call state exposed to the UI.
enum CallState { idle, calling, ringing, connected, ended }

/// Handles WebRTC voice calls, using Firestore purely as a signaling
/// channel (exchanging the SDP offer/answer and ICE candidates) and
/// Metered-issued TURN servers for actual media relay when a direct
/// peer-to-peer path isn't possible (most mobile networks/NATs).
///
/// Firestore shape:
///   calls/{callId}
///     callerId, callerName, calleeId, calleeName, status, createdAt
///     offer: {sdp, type}, answer: {sdp, type}
///     callerCandidates/{autoId}, calleeCandidates/{autoId}
class CallService {
  CallService({
    required TurnCredentialsService turnCredentials,
    PushNotificationClient? pushClient,
  }) : _turnCredentials = turnCredentials,
       _pushClient =
           pushClient ??
           PushNotificationClient(workerBaseUrl: AppConfig.workerBaseUrl) {
    _activeInstance = this;
  }

  static CallService? _activeInstance;
  static CallService get active {
    final instance = _activeInstance;
    if (instance == null) {
      throw StateError('CallService has not been created yet');
    }
    return instance;
  }

  final TurnCredentialsService _turnCredentials;
  final PushNotificationClient _pushClient;
  final _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  String? _currentCallId;
  StreamSubscription? _callDocSub;
  StreamSubscription? _remoteCandidatesSub;

  final _stateController = StreamController<CallState>.broadcast();
  Stream<CallState> get stateStream => _stateController.stream;
  CallState _state = CallState.idle;
  CallState get state => _state;

  void _setState(CallState s) {
    _state = s;
    _stateController.add(s);
  }

  String? get currentCallId => _currentCallId;
  bool get isMuted =>
      _localStream?.getAudioTracks().firstOrNull?.enabled == false;

  /// Live stream of incoming calls for the signed-in user
  /// (status == 'ringing' and they're the callee).
  Stream<CallModel?> incomingCalls() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return Stream.value(null);

    return _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.isEmpty ? null : CallModel.fromDoc(snap.docs.first),
        );
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final iceServers = await _turnCredentials.fetchIceServers();
    final pc = await createPeerConnection({
      'iceServers': iceServers.map((s) => s.toMap()).toList(),
      'sdpSemantics': 'unified-plan',
    });

    pc.onTrack = (event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        // Remote audio is handled by the WebRTC media stream internally.
      }
    };

    return pc;
  }

  Future<MediaStream> _getLocalAudioStream() {
    return navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  // -------------------------------------------------------------------
  // Outgoing call
  // -------------------------------------------------------------------
  Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String myName,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) throw Exception('Not signed in');

    // ignore: avoid_print
    print('☎️ CALL: Starting outgoing call to $calleeId ($calleeName)');

    _setState(CallState.calling);

    _peerConnection = await _createPeerConnection();
    _localStream = await _getLocalAudioStream();
    for (final track in _localStream!.getAudioTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    final callDoc = _firestore.collection('calls').doc();
    _currentCallId = callDoc.id;

    // ignore: avoid_print
    print('☎️ CALL: Generated call ID: ${callDoc.id}');

    await _showOutgoingCallkit(callId: callDoc.id, calleeName: calleeName);

    // Write our ICE candidates as they're discovered.
    _peerConnection!.onIceCandidate = (candidate) {
      callDoc.collection('callerCandidates').add(candidate.toMap());
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'callerId': myUid,
      'callerName': myName,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'status': 'ringing',
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ignore: avoid_print
    print('☎️ CALL: Firestore call doc created, sending push notification');

    // Data-only push (no `notification` block) so the recipient's
    // NotificationService shows CallKit instead of a plain banner —
    // this is what actually rings their device.
    unawaited(
      _pushClient.sendNotification(
        recipientUid: calleeId,
        data: {
          'type': 'call',
          'callId': callDoc.id,
          'callerId': myUid,
          'callerName': myName,
        },
      ),
    );

    _listenForRemoteAnswerAndCandidates(callDoc, isCaller: true);
    return callDoc.id;
  }

  // -------------------------------------------------------------------
  // Incoming call
  // -------------------------------------------------------------------
  Future<void> answerCall(String callId) async {
    final callDoc = _firestore.collection('calls').doc(callId);
    final snap = await callDoc.get();
    final data = snap.data();
    if (data == null || data['offer'] == null) {
      throw Exception('Call no longer available');
    }

    _currentCallId = callId;
    _peerConnection = await _createPeerConnection();
    _localStream = await _getLocalAudioStream();
    for (final track in _localStream!.getAudioTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (candidate) {
      callDoc.collection('calleeCandidates').add(candidate.toMap());
    };

    final offer = data['offer'] as Map<String, dynamic>;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'] as String, offer['type'] as String),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await callDoc.update({
      'status': 'accepted',
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });

    _setState(CallState.connected);
    _listenForRemoteAnswerAndCandidates(callDoc, isCaller: false);
  }

  Future<void> declineCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'declined',
    });
    await FlutterCallkitIncoming.endCall(callId);
  }

  // -------------------------------------------------------------------
  // Shared signaling listeners
  // -------------------------------------------------------------------
  void _listenForRemoteAnswerAndCandidates(
    DocumentReference<Map<String, dynamic>> callDoc, {
    required bool isCaller,
  }) {
    _callDocSub?.cancel();
    _callDocSub = callDoc.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null) return;

      final status = data['status'] as String?;

      // Caller: once the callee answers, apply their SDP answer.
      if (isCaller && status == 'accepted' && data['answer'] != null) {
        final pc = _peerConnection;
        if (pc != null && (await pc.getRemoteDescription()) == null) {
          final answer = data['answer'] as Map<String, dynamic>;
          await pc.setRemoteDescription(
            RTCSessionDescription(
              answer['sdp'] as String,
              answer['type'] as String,
            ),
          );
          _setState(CallState.connected);
        }
      }

      if (status == 'declined' || status == 'ended') {
        _setState(CallState.ended);
        final callId = _currentCallId;
        if (callId != null) await FlutterCallkitIncoming.endCall(callId);
        await _cleanup(deleteDoc: false);
      }
    });

    final remoteCandidatesCollection = callDoc.collection(
      isCaller ? 'calleeCandidates' : 'callerCandidates',
    );

    _remoteCandidatesSub?.cancel();
    _remoteCandidatesSub = remoteCandidatesCollection.snapshots().listen((
      snap,
    ) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        _peerConnection?.addCandidate(
          RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          ),
        );
      }
    });
  }

  // -------------------------------------------------------------------
  // In-call controls
  // -------------------------------------------------------------------
  void toggleMute() {
    final track = _localStream?.getAudioTracks().firstOrNull;
    if (track != null) track.enabled = !track.enabled;
  }

  Future<void> setSpeakerphone(bool on) {
    return Helper.setSpeakerphoneOn(on);
  }

  Future<void> hangUp() async {
    final callId = _currentCallId;
    if (callId != null) {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'ended',
      });
      await FlutterCallkitIncoming.endCall(callId);
    }
    _setState(CallState.ended);
    await _cleanup(deleteDoc: false);
  }

  Future<void> _cleanup({required bool deleteDoc}) async {
    await _callDocSub?.cancel();
    await _remoteCandidatesSub?.cancel();
    _callDocSub = null;
    _remoteCandidatesSub = null;

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _currentCallId = null;
  }

  void dispose() {
    _cleanup(deleteDoc: false);
    _stateController.close();
  }

  // ---------------------------------------------------------------------
  // CallKit — native call UI (rings even from background/terminated,
  // shown on the lock screen, uses the system ringtone).
  // ---------------------------------------------------------------------
  Future<void> _showOutgoingCallkit({
    required String callId,
    required String calleeName,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: calleeName,
      handle: calleeName,
      type: 0, // 0 = audio call
      extra: {'callId': callId, 'direction': 'outgoing'},
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  /// Call this from the FCM message handler (foreground AND background —
  /// see NotificationService) whenever a `type: call` data message
  /// arrives. This is what actually rings the callee's device.
  static Future<void> showIncomingCallkit({
    required String callId,
    required String callerId,
    required String callerName,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      handle: callerName,
      type: 0,
      extra: {'callId': callId, 'callerId': callerId, 'direction': 'incoming'},
      android: const AndroidParams(isCustomNotification: true),
      ios: const IOSParams(supportsVideo: false),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Single app-wide CallService instance. Using a Provider (not
/// autoDispose) is intentional — a call's state must survive navigating
/// away from CallScreen and back (e.g. the app briefly backgrounded).

// ---------------------------------------------------------------------------
// Wiring CallKit accept/decline into the app — register this once, e.g. in
// your root widget's initState (with access to `ref`), so it applies for
// the whole app lifetime:
// ---------------------------------------------------------------------------
//
// FlutterCallkitIncoming.onEvent.listen((event) async {
//   final callService = ref.read(callServiceProvider);
//   final extra = Map<String, dynamic>.from(event?.body['extra'] ?? {});
//   final callId = extra['callId'] as String?;
//   if (callId == null) return;
//
//   switch (event?.event) {
//     case Event.actionCallAccept:
//       await callService.answerCall(callId);
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => CallScreen(
//             callService: callService,
//             peerName: extra['callerName'] as String? ?? 'Unknown',
//           ),
//         ),
//       );
//       break;
//     case Event.actionCallDecline:
//       await callService.declineCall(callId);
//       break;
//     case Event.actionCallTimeout:
//       await callService.declineCall(callId); // unanswered -> treat as declined
//       break;
//     case Event.actionCallEnded:
//       await callService.hangUp();
//       break;
//     default:
//       break;
//   }
// });
//
// NOTE: with CallKit wired up this way, it becomes the incoming-call UI in
// ALL app states (foreground, background, terminated) via the FCM push in
// functions_call_signal.js — so IncomingCallScreen (the in-app screen driven
// by CallService.incomingCalls()) is no longer needed and can be removed,
// unless you want it as an extra in-app banner alongside CallKit's screen.
