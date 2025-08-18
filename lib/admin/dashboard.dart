import 'package:flutter/material.dart';
import 'package:pretty_threads/admin/users/users_page.dart';
import 'package:pretty_threads/admin/products/products_page.dart';
import 'package:pretty_threads/admin/categories/categories_page.dart';
import 'package:pretty_threads/admin/payments/payments_page.dart';
import 'package:pretty_threads/admin/widgets/admin_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  final _pages = const [
    UsersPage(),
    ProductsAdminPage(),
    CategoriesAdminPage(),
    PaymentsAdminPage(),
  ];

  final _titles = const [
    'Users',
    'Products',
    'Categories',
    'Payments',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin - ${_titles[_index]}')),
      drawer: AdminDrawer(onSelect: (i) => setState(() => _index = i)),
      body: _pages[_index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_alt),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
          ],
        ),
      ),
    );
  }
}
