import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'AuthStack.dart';
import 'BottomNav.dart';
import '../components/Loader.dart';
// import 'EmailVerifyScreen.dart';        // <- optional, if you have one
// import 'CompleteProfileScreen.dart';    // <- optional, if you have one

class AppStack extends StatelessWidget {
  const AppStack({super.key});

  Future<bool> _profileExists(String uid) async {
    final snap = await FirebaseDatabase.instance
        .ref('Shops/user/$uid')
        .get();
    return snap.exists && snap.value != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // 1) Splash while auth stream connects
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: Loader(message: "Logging In...",)));
        }

        // 2) Not logged in -> show auth flow
        final user = authSnap.data;
        if (user == null) {
          return const AuthStack();
        }

        // 3) (Optional) Require email verification before entering app
        // if (!user.emailVerified) {
        //   return const EmailVerifyScreen();
        // }

        // 4) Check profile existence before entering main app
        return FutureBuilder<bool>(
          future: _profileExists(user.uid),
          builder: (context, profSnap) {
            if (profSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: Loader()));
            }

            if (profSnap.hasError) {
              // Minimal inline error state with retry
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load profile.'),
                      const SizedBox(height: 8),
                      FilledButton(
                        // ignore: invalid_use_of_protected_member
                        onPressed: () => (context as Element).reassemble(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final exists = profSnap.data == true;
            if (exists) {
              return const BottomNav();
            }
            return const AuthStack();
          },
        );
      },
    );
  }
}
