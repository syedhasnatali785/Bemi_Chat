import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:flutter/material.dart';

/// A reusable rounded button with Neomorphism design.
///
/// Features:
/// - Filled or outlined style ([outlined])
/// - Loading spinner ([loading]) that also blocks taps
/// - Optional leading icon ([icon])
/// - Disabled state (pass `ontap: null`)
/// - Neomorphic shadows and styling
/// - Custom colors, size, radius and text style
class RoundButton extends StatefulWidget {
  const RoundButton({
    super.key,
    required this.title,
    required this.ontap,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.color,
    this.textColor,
    this.borderColor,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 12,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String title;

  /// Pass `null` to disable the button.
  final VoidCallback? ontap;

  final bool loading;
  final bool outlined;
  final IconData? icon;

  final Color? color;
  final Color? textColor;
  final Color? borderColor;

  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  bool get _enabled => ontap != null && !loading;

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.color ?? NeomorphismTheme.accentPurple;
    final bgColor = widget.outlined ? NeomorphismTheme.surfaceWhite : primary;
    final fgColor =
        widget.textColor ??
        (widget.outlined ? primary : NeomorphismTheme.surfaceWhite);
    final outline = widget.borderColor ?? primary;

    final radius = BorderRadius.circular(widget.borderRadius);

    return Opacity(
      opacity: widget.ontap == null ? 0.5 : 1,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTapDown: widget._enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget._enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: widget._enabled
              ? () => setState(() => _pressed = false)
              : null,
          onTap: widget._enabled ? widget.ontap : null,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: radius,
              border: widget.outlined
                  ? Border.all(color: outline, width: 2)
                  : null,
              boxShadow: _pressed
                  ? NeomorphismTheme.insetShadow
                  : NeomorphismTheme.softShadow,
            ),
            child: Padding(
              padding: widget.padding,
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: fgColor, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  widget.textStyle ??
                                  TextStyle(
                                    color: fgColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// USAGE EXAMPLES
// ---------------------------------------------------------------------------
//
// // Basic
// RoundButton(title: 'Login', ontap: () {});
//
// // With loading state
// RoundButton(
//   title: 'Login',
//   loading: isLoading,
//   ontap: () async {
//     setState(() => isLoading = true);
//     await doLogin();
//     setState(() => isLoading = false);
//   },
// );
//
// // Outlined with icon
// RoundButton(
//   title: 'Continue with Google',
//   icon: Icons.g_mobiledata,
//   outlined: true,
//   ontap: () {},
// );
//
// // Custom color, fixed width
// RoundButton(
//   title: 'Save',
//   color: Colors.green,
//   width: 160,
//   ontap: () {},
// );
//
// // Disabled
// const RoundButton(title: 'Submit', ontap: null);
