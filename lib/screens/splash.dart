import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_restaurant_app/screens/login/loginui.dart';
import 'package:multi_restaurant_app/screens/mainpage/mainhomepage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieBuilder.asset('assets/images/Animation - 1720508864321.json',height:250),
          const SizedBox(
              height: 20), // Add space between the animation and text
          const Text(
            'Restaurant Booking APP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      nextScreen: user != null ? const MainHomePage() : const LoginUI(),
      backgroundColor: Colors.white,
      splashIconSize:
          double.infinity, // Ensure splash screen covers the entire screen
      duration: 2000, // Duration in milliseconds
    );
  }
}
