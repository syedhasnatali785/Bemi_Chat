import 'package:bemichat/config/neomorphism_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable, themed text field with Neomorphism design.
///
/// Features:
/// - Label, hint, helper and error text
/// - Prefix / suffix icons
/// - Built-in password show/hide toggle (set [isPassword] to true)
/// - Validation support (works inside a [Form])
/// - Multi-line, max length, input formatters
/// - Neomorphic shadows and soft styling
/// - Customizable colors, radius and padding
class Inputtextfield extends StatefulWidget {
  const Inputtextfield({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = 12,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    this.textStyle,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? initialValue;

  final IconData? prefixIcon;
  final Widget? suffixIcon;

  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final AutovalidateMode autovalidateMode;

  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;

  @override
  State<Inputtextfield> createState() => _InputtextfieldState();
}

class _InputtextfieldState extends State<Inputtextfield> {
  late bool _obscure;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  OutlineInputBorder _neomorphicBorder(Color color, {double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildSuffix() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off : Icons.visibility,
          color: NeomorphismTheme.mediumGrey,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = widget.focusNode ?? FocusNode();

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isFocused
              ? NeomorphismTheme.mediumShadow
              : NeomorphismTheme.softShadow,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: focusNode,
          initialValue: widget.controller == null ? widget.initialValue : null,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.isPassword ? 1 : widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          autovalidateMode: widget.autovalidateMode,
          style:
              widget.textStyle ??
              const TextStyle(
                color: NeomorphismTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            filled: true,
            fillColor: widget.fillColor ?? NeomorphismTheme.surfaceWhite,
            contentPadding: widget.contentPadding,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? NeomorphismTheme.accentPurple
                        : NeomorphismTheme.mediumGrey,
                  )
                : null,
            suffixIcon: _buildSuffix(),
            border: _neomorphicBorder(NeomorphismTheme.lightGrey),
            enabledBorder: _neomorphicBorder(
              NeomorphismTheme.lightGrey,
              width: 0,
            ),
            focusedBorder: _neomorphicBorder(
              NeomorphismTheme.accentPurple,
              width: 2,
            ),
            errorBorder: _neomorphicBorder(
              NeomorphismTheme.errorRed,
              width: 1.5,
            ),
            focusedErrorBorder: _neomorphicBorder(
              NeomorphismTheme.errorRed,
              width: 2,
            ),
            disabledBorder: _neomorphicBorder(
              NeomorphismTheme.lightGrey,
              width: 0,
            ),
            labelStyle: const TextStyle(
              color: NeomorphismTheme.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(
              color: NeomorphismTheme.mediumGrey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            helperStyle: const TextStyle(
              color: NeomorphismTheme.mediumGrey,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            errorStyle: const TextStyle(
              color: NeomorphismTheme.errorRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// USAGE EXAMPLE
// ---------------------------------------------------------------------------
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//
//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Inputtextfield(
//                 controller: _emailCtrl,
//                 label: 'Email',
//                 hint: 'you@example.com',
//                 prefixIcon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//                 textInputAction: TextInputAction.next,
//                 validator: (v) =>
//                     (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
//               ),
//               const SizedBox(height: 16),
//               Inputtextfield(
//                 controller: _passCtrl,
//                 label: 'Password',
//                 prefixIcon: Icons.lock_outline,
//                 isPassword: true,
//                 textInputAction: TextInputAction.done,
//                 validator: (v) =>
//                     (v == null || v.length < 6) ? 'Min 6 characters' : null,
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     // proceed
//                   }
//                 },
//                 child: const Text('Login'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
