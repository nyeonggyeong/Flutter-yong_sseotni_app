import 'package:flutter/material.dart';
import 'screens/start.dart';
import 'screens/signup.dart';
import 'screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
