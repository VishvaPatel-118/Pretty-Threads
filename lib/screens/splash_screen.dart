import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart'; // later we'll create this

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // or your theme color
      body: Center(
        child: Image.asset(
          'assets/images/logo.jpg', // Add your logo image in this path
          height: 400,
          width: 400,
        ),
      ),
    );
  }
}
