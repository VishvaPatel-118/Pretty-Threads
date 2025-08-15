import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: const Color(0xFF9C27B0),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "We’d love to hear from you!\n\n"
              "📍 Address: 123 Pretty Threads Lane, Surat, India\n"
              "📞 Phone: +91 9824863001\n"
              "📧 Email: support@prettythreads.com\n"
              "⏰ Working Hours: Mon-Sat, 10:00 AM - 8:00 PM",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
