import 'package:flutter/material.dart';
import 'screens/start.dart';
import 'screens/signup.dart';
import 'screens/login.dart';
import 'screens/calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/calendar') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => CalendarPage(userData: args),
          );
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const StartPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignUpPage());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          default:
            return MaterialPageRoute(builder: (context) => const StartPage());
        }
      },
    );
  }
}
