import 'package:flutter/material.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/user/authentication/login_screen.dart';

class AdminDrawer extends StatelessWidget {
  final ValueChanged<int> onSelect;
  const AdminDrawer({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings)),
                  SizedBox(height: 12),
                  Text('Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Users'),
              onTap: () {
                Navigator.pop(context);
                onSelect(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                onSelect(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                onSelect(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Payments'),
              onTap: () {
                Navigator.pop(context);
                onSelect(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                // Clear local auth state
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
