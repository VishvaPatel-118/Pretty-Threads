import 'package:flutter/material.dart';
import 'package:pretty_threads/user/authentication/login_screen.dart';
import 'package:pretty_threads/pages/about_us_page.dart';
import 'package:pretty_threads/pages/terms_of_use_page.dart';
import 'package:pretty_threads/pages/help_center_page.dart';
import 'package:pretty_threads/pages/contact_us_page.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

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

          // Login
          ListTile(
            leading: const Icon(Icons.login, color: Color(0xFF6A1B9A)),
            title: const Text("Login"),
            onTap: () {
              Navigator.pop(context); // Close Drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
