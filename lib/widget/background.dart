import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const AppBackground({super.key, required this.child, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        child,
      ],
    );
  }
}
