import 'package:flutter/material.dart';
import 'package:pretty_threads/user/authentication/signup_screen.dart';
import 'package:pretty_threads/user/authentication/forgot_password_screen.dart';
import 'package:pretty_threads/user/home/home_page.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6B5E5), Color(0xFFB19CD9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ✅ Top bar with Skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // ✅ Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        "assets/images/login-remove.png",
                        height: 200,
                        width: 250,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Login to continue your fashion journey",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✅ White card container for form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.purple),
                                labelText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: Colors.purple),
                                labelText: "Password",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                       ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Colors.purple),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text;

                                        if (email.isEmpty || password.isEmpty) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text('Please enter both email and password')),
                                            );
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                          return;
                                        }

                                        try {
                                          final response = await ApiService.login(
                                            email: email,
                                            password: password,
                                          );

                                          if (!mounted) return;

                                          // Save token to shared preferences
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('auth_token', response['token']);

                                          // Show success then navigate to home
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Logged in successfully')),
                                          );
                                          await Future.delayed(const Duration(milliseconds: 400));
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => const HomePage()),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(e
                                                    .toString()
                                                    .replaceFirst('Exception: ', ''))),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.purple.withOpacity(0.7),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              "OR",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                // Admin login navigation
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: "Are you an admin? ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Click here",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
