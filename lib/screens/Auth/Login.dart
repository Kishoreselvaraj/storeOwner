import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:store/components/Loader.dart';
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
      if (!mounted) return;
      
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
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top illustration (replace with your asset if needed)
                SizedBox(height: 32),
                Image.asset(
                  "assets/onboarding/login.png", // Replace with your image path
                  height: 170,
                ),
                SizedBox(height: 28),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 18),

                // Email Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 10),

                // Forgot Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reset-password');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Error
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(error!,
                        style: TextStyle(color: Colors.red, fontSize: 14)),
                  ),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loading
                        ? Loader(
                            color: Colors.white,
                          )
                        : Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16),

                // Register text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Not a member? ",
                        style: TextStyle(color: Colors.black87)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 22),
                Divider(),
                SizedBox(height: 15),

                // Social login text
                Text(
                  "Or continue with",
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                SizedBox(height: 18),

                // Social login row (add functions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.red.shade600,
                      child: Icon(Icons.g_mobiledata, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 24),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.apple, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 24),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue.shade700,
                      child: Icon(Icons.facebook, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return showOnboarding ? buildOnboarding() : buildLogin();
  }
}
