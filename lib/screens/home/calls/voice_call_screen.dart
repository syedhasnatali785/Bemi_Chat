import 'dart:async';

import 'package:bemichat/services/call_services/call_service.dart';
import 'package:flutter/material.dart';

/// Shown for both the caller (immediately, state = calling) and the
/// callee (after tapping Accept, state = connected). Voice-only — there
/// is no video view, since the remote audio track plays automatically
/// through the device once the peer connection is established.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.callService,
    required this.peerName,
  });

  final CallService callService;
  final String peerName;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  StreamSubscription<CallState>? _stateSub;
  CallState _state = CallState.calling;

  bool _muted = false;
  bool _speakerOn = false;

  Timer? _durationTimer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _state = widget.callService.state;

    _stateSub = widget.callService.stateStream.listen((state) {
      setState(() => _state = state);
      if (state == CallState.connected) {
        _startTimer();
      } else if (state == CallState.ended) {
        _durationTimer?.cancel();
        // Give the "call ended" label a beat on screen before popping.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _statusLabel {
    switch (_state) {
      case CallState.calling:
        return 'Calling…';
      case CallState.ringing:
        return 'Ringing…';
      case CallState.connected:
        return _formatDuration(_duration);
      case CallState.ended:
        return 'Call ended';
      case CallState.idle:
        return '';
    }
  }

  Future<void> _toggleMute() async {
    widget.callService.toggleMute();
    setState(() => _muted = !_muted);
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerOn;
    await widget.callService.setSpeakerphone(next);
    setState(() => _speakerOn = next);
  }

  Future<void> _hangUp() async {
    await widget.callService.hangUp();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // route hang-up through the button so we clean up properly
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 64,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    widget.peerName.isNotEmpty
                        ? widget.peerName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(widget.peerName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  _statusLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      selected: _muted,
                      onTap: _toggleMute,
                    ),
                    _ControlButton(
                      icon: Icons.call_end,
                      backgroundColor: theme.colorScheme.error,
                      iconColor: theme.colorScheme.onError,
                      large: true,
                      onTap: _hangUp,
                    ),
                    _ControlButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.hearing,
                      selected: _speakerOn,
                      onTap: _toggleSpeaker,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.large = false,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool large;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = large ? 72.0 : 56.0;
    final bg =
        backgroundColor ??
        (selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest);
    final fg =
        iconColor ??
        (selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface);

    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: fg, size: large ? 32 : 24),
        ),
      ),
    );
  }
}
