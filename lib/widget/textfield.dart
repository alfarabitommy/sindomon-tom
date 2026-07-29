import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final bool error;
  final TextEditingController? controller;

  const AppTextField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.controller,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Color(0xFF23251D)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: const Color(0xFF4D4F46).withValues(alpha: 0.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? Colors.red : const Color(0xFFBFC1B7),
              width: 1.2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? Colors.red : const Color(0xFF1D4ED8),
              width: 2,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),

        ),
      ),
    );
  }
}