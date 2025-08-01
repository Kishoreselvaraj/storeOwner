import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("👤 Profile Page", style: TextStyle(fontSize: 24)),
        const SizedBox(height: 10),
        Text("Email: ${user?.email ?? 'N/A'}"),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text("Logout"),
        )
      ],
    );
  }
}
