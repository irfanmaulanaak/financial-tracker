import 'package:flutter/material.dart';

import '../theme.dart';

/// Editorial text input. Eyebrow label above (optional), warm surface fill,
/// 0.5px border that thickens to 1px on focus. Plays well inside a Form.
class FtInput extends StatefulWidget {
  const FtInput({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.trailing,
    this.leading,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final Widget? leading;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final int? minLines;

  @override
  State<FtInput> createState() => _FtInputState();
}

class _FtInputState extends State<FtInput> {
  final _focus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != _focus.hasFocus) {
      setState(() => _hasFocus = _focus.hasFocus);
    }
  }

  OutlineInputBorder _border(Color c, double w) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Eyebrow(widget.label!),
          const SizedBox(height: 8),
        ],
        TextFormField(
          focusNode: _focus,
          controller: widget.controller,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          cursorColor: FtColors.clay,
          cursorWidth: 1.5,
          style: TextStyle(
            color: FtColors.ink,
            fontSize: 15,
            height: 1.3,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: FtColors.ink4,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.leading,
            suffixIcon: widget.trailing,
            filled: true,
            fillColor: _hasFocus ? FtColors.surfaceAlt : FtColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(FtColors.line, 0.5),
            enabledBorder: _border(FtColors.line, 0.5),
            focusedBorder: _border(FtColors.ink, 1.0),
            disabledBorder: _border(FtColors.line, 0.5),
            errorBorder: _border(FtColors.danger, 0.5),
            focusedErrorBorder: _border(FtColors.danger, 1.0),
            errorStyle: TextStyle(
              color: FtColors.danger,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
