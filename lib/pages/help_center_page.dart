import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help Center"),
        backgroundColor: const Color(0xFF9C27B0), // Match your theme
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Help Center - Frequently Asked Questions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "Q: How do I place an order?\n"
                    "A: Simply browse products, add them to your cart, and proceed to checkout.\n\n"
                    "Q: How can I track my order?\n"
                    "A: You will receive a tracking link via email once your order is shipped.\n\n"
                    "Q: What is your return policy?\n"
                    "A: We accept returns within 7 days of delivery. Items must be unused and in original condition.\n\n"
                    "Q: Is a video call facility available to view products before buying?\n"
                    "A: Yes! During the ordering process, you can request a live video call with our team to see the product in real time before confirming your purchase.",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
