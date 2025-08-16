import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/user/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // App Logo
                  Image.asset(
                    "assets/images/login-remove.png",
                    height: 200,
                    width: 250,
                  ),

                  // Title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Join us and start your fashion journey",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Signup Card
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
                        // Full Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Colors.purple),
                            labelText: "Full Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Email
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

                        // Phone Number
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone_outlined,
                                color: Colors.purple),
                            labelText: "Phone Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Password
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
                        const SizedBox(height: 15),

                        // Confirm Password
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_reset,
                                color: Colors.purple),
                            labelText: "Confirm Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Address
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.home_outlined,
                                color: Colors.purple),
                            labelText: "Full Address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // City
                        TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_city,
                                color: Colors.purple),
                            labelText: "City",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Pincode
                        TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.local_post_office_outlined,
                                color: Colors.purple),
                            labelText: "Pincode",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Signup Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final name = _nameController.text.trim();
                                    final email = _emailController.text.trim();
                                    final phone = _phoneController.text.trim();
                                    final password = _passwordController.text;
                                    final confirmPassword = _confirmPasswordController.text;
                                    final address = _addressController.text.trim();
                                    final city = _cityController.text.trim();
                                    final pincode = _pincodeController.text.trim();

                                    // Basic validation (match backend required fields)
                                    if (name.isEmpty ||
                                        email.isEmpty ||
                                        phone.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty ||
                                        address.isEmpty ||
                                        city.isEmpty ||
                                        pincode.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Please fill in all required fields')),
                                      );
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Passwords do not match')),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      // Register the user
                                      await ApiService.register(
                                        fullName: name,
                                        email: email,
                                        password: password,
                                        phoneNumber: phone,
                                        fullAddress: address,
                                        city: city,
                                        pincode: pincode,
                                      );

                                      if (!mounted) return;

                                      // Auto-login after successful registration
                                      final loginResp = await ApiService.login(
                                        email: email,
                                        password: password,
                                      );

                                      if (!mounted) return;
                                      // Save token and navigate to Home
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('auth_token', loginResp['token']);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sign up successful! Logged in.')),
                                      );
                                      await Future.delayed(const Duration(milliseconds: 400));
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HomePage()),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                e.toString().replaceFirst('Exception: ', ''))),
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
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Already have account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
