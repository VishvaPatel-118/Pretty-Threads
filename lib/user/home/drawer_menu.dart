import 'package:flutter/material.dart';
import 'package:pretty_threads/user/authentication/login_screen.dart';
import 'package:pretty_threads/pages/about_us_page.dart';
import 'package:pretty_threads/pages/terms_of_use_page.dart';
import 'package:pretty_threads/pages/help_center_page.dart';
import 'package:pretty_threads/pages/contact_us_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) setState(() => _loggedIn = token != null && token.isNotEmpty);
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    setState(() => _loggedIn = false);
    // Redirect to Login and clear back stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Compact Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.storefront, size: 32, color: Color(0xFF9C27B0)),
                ),
                SizedBox(width: 12),
                Text(
                  'Pretty Threads',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // About Us
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
            title: const Text('About Us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),

          // Terms of Use
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Color(0xFF9C27B0)),
            title: const Text('Terms of Use'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfUsePage()),
              );
            },
          ),

          // Help Center
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF9C27B0)),
            title: const Text('Help Center'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterPage()),
              );
            },
          ),

          // Contact Us
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: Color(0xFF9C27B0)),
            title: const Text('Contact Us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactUsPage()),
              );
            },
          ),

          const Divider(),

          // Login / Logout
          _loggedIn
              ? ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFF6A1B9A)),
                  title: const Text("Logout"),
                  onTap: () => _logout(context),
                )
              : ListTile(
                  leading: const Icon(Icons.login, color: Color(0xFF6A1B9A)),
                  title: const Text("Login"),
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    ).then((_) => _checkLogin());
                  },
                ),
        ],
      ),
    );
  }
}
