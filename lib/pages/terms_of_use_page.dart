import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Use"),
        backgroundColor: Colors.purple.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Terms of Use",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Welcome to Pretty Threads! By accessing or using our app, you agree to be bound by the following terms and conditions:\n\n"

                    "1. **Personal Use Only** – You agree to use this app for personal, non-commercial purposes only.\n\n"
                    "2. **Product Information** – All products, images, and descriptions are for reference purposes. We make every effort to ensure accuracy but do not guarantee that descriptions or prices are error-free.\n\n"
                    "3. **Pricing & Availability** – Prices and availability of items are subject to change without prior notice.\n\n"
                    "4. **Orders & Payment** – All orders are subject to acceptance. Payment must be completed before dispatch unless opting for Cash on Delivery.\n\n"
                    "5. **Return & Refund Policy** – Returns are accepted within 7 days of delivery if the product is unused and in its original condition. Refunds will be processed within 5-7 business days.\n\n"
                    "6. **Account Security** – You are responsible for maintaining the confidentiality of your account credentials.\n\n"
                    "7. **Prohibited Activities** – Misuse of the platform, fraudulent transactions, or any illegal activity will lead to account suspension or termination.\n\n"
                    "8. **Changes to Terms** – We reserve the right to modify these terms at any time. Updates will be effective immediately upon posting in the app.\n\n"
                    "9. **Contact Us** – For any queries related to these terms, reach out via our Help Center or Contact Us page.\n\n"
                    "By continuing to use Pretty Threads, you acknowledge that you have read, understood, and agreed to these terms.",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
