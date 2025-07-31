import 'package:flutter/material.dart';
import '../screens/Auth/Login.dart';
import '../screens/Auth/SignUp.dart';

class AuthStack extends StatelessWidget {
  const AuthStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/signup':
            page = const SignupScreen();
            break;
          case '/login':
          default:
            page = const LoginScreen();
        }

        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}
