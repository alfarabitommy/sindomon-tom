import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.white),
          //child: Image.asset(
          //  "assets/images/background.png",
          //  fit: BoxFit.cover,
          //),
        ),
        child,
      ],
    );
  }
}
