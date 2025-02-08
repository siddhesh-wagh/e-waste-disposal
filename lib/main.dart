import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Waste Guide',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/onboard',
      routes: {
        '/onboard': (context) => OnboardingScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}