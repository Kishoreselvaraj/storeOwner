import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../components/CustomTextField.dart';
const String onboard1Image = 'assets/onboarding/onboard1.png';
const String onboard2Image = 'assets/onboarding/onboard2.png';
const String onboard3Image = 'assets/onboarding/onboard3.png';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  // Onboarding variables
  bool showOnboarding = true;
  final PageController _pageController = PageController();
  int onboardingPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": onboard1Image,
      "title": "Find Trusted Electricians\n& Products in One Tap",
      "subtitle": "Book certified electricians or buy electric items from\nnearby shops instantly.",
      "button": "Next"
    },
    {
      "image": onboard2Image,
      "title": "Hire an Electrician",
      "subtitle": "Search nearby electric shops by name, rating & location.",
      "button": "Next"
    },
    {
      "image": onboard3Image,
      "title": "Smart Suggestions",
      "subtitle": "Top Rated Electricians Near You, Popular Products in Your Area.",
      "button": "Let's Start"
    },
  ];

  Future<void> loginUser() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final snapshot = await FirebaseDatabase.instance
          .ref("Shops/user/${credential.user!.uid}")
          .get();

      if (snapshot.exists) {
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
    _pageController.dispose();
    super.dispose();
  }

  Widget buildOnboarding() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => onboardingPage = index);
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
                    child: Column(
                      children: [
                        const SizedBox(height: 36),
                        Image.asset(
                          data["image"]!,
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 50),
                        Text(
                          data["title"]!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          data["subtitle"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  height: 8,
                  width: onboardingPage == index ? 22 : 8,
                  decoration: BoxDecoration(
                    color: onboardingPage == index
                        ? Colors.orange
                        : Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Bottom button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    if (onboardingPage < onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      setState(() => showOnboarding = false);
                    }
                  },
                  child: Text(
                    onboardingData[onboardingPage]['button']!,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildLogin() {
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

  @override
  Widget build(BuildContext context) {
    return showOnboarding ? buildOnboarding() : buildLogin();
  }
}
