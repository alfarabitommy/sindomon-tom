import 'package:flutter/material.dart';
import '../widget/background.dart';
import '../widget/login_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: const [

                  SizedBox(height: 40),

                  LoginCard(),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}