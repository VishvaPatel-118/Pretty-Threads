import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_threads/user/home/home_page.dart'; // ✅ Home Page import

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Fashion Store',
      'subtitle': 'Discover elegant outfits for every occasion',
      'image': 'assets/images/fashion1.jpg',
    },
    {
      'title': 'Trendy Collections',
      'subtitle': 'Stay ahead with our latest designs',
      'image': 'assets/images/fashion2.jpg',
    },
    {
      'title': 'Style Your Way',
      'subtitle': 'Make every outfit your own',
      'image': 'assets/images/fashion3.jpg',
    },
  ];

  // ✅ Go to Home Page instead of Login
  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentPage + 1) / onboardingData.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EAF7),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (only if not last page)
            if (_currentPage != onboardingData.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 16),
                  child: TextButton(
                    onPressed: _goToHome, // ✅ Home page open
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        item['image']!,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        item['title']!,
                        style: GoogleFonts.greatVibes(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6A1B9A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          item['subtitle']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dancingScript(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Progress Ring with Next Button
            GestureDetector(
              onTap: _nextPage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF6A1B9A),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
