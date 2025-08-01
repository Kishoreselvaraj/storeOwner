import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../components/CustomTextField.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  /// Handles user login
  Future<void> loginUser() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Firebase sign-in
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if user data exists in Realtime DB
      final snapshot = await FirebaseDatabase.instance
          .ref("Shops/user/${credential.user!.uid}")
          .get();

      if (snapshot.exists) {
        // Go to main app (BottomNav)
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        setState(() {
          error = "User data not found in database.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? "Login failed.";
      });
    } catch (e) {
      setState(() {
        error = "Unexpected error: $e";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              controller: emailController,
              label: "Email",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              label: "Password",
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : loginUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
