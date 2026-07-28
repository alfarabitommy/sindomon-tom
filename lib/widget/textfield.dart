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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? Colors.red : Colors.grey,
              width: 1.2,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: error ? Colors.red : Colors.blue,
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

          errorText: error ? "" : null, // agar border merah muncul tanpa pesan
        ),
      ),
    );
  }
}