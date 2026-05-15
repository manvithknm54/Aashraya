import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AashrayaTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final int maxLines;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const AashrayaTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
  });

  @override
  State<AashrayaTextField> createState() => _AashrayaTextFieldState();
}

class _AashrayaTextFieldState extends State<AashrayaTextField> {
  bool _obscure = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.walnut,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) =>
              setState(() => _isFocused = focused),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword && _obscure,
            validator: widget.validator,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            textInputAction: widget.textInputAction,
            onEditingComplete: widget.onEditingComplete,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.walnut,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textHint,
                fontWeight: FontWeight.w300,
              ),
              filled: true,
              fillColor: _isFocused
                  ? AppColors.surface
                  : AppColors.surface,
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48, minHeight: 48,
              ),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () =>
                          setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}