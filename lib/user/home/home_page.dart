import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_threads/user/authentication/login_screen.dart';
import 'drawer_menu.dart';

import 'package:pretty_threads/user/home/categories_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_threads/user/profile/profile_page.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/user/cart/cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int? _hoveredCategoryIndex;
  bool _isImageTapped = false;
  String? _userName;

  // ✅ Category Data (Display name + slug for backend)
  final List<Map<String, String>> categories = [
    {"name": "Men", "slug": "men", "image": "assets/images/mensuits.webp"},
    {"name": "Women", "slug": "women", "image": "assets/images/kurti.jpeg"},
    {"name": "Kids", "slug": "kids", "image": "assets/images/pinkgown.jpg"},
  ];

  Future<void> _onAccountTapped() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => token != null && token.isNotEmpty
            ? const ProfilePage()
            : const LoginScreen(),
      ),
    ).then((_) => _loadUserName());
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _onAccountTapped();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _userName = null);
      return;
    }
    try {
      final data = await ApiService.getProfile(token: token);
      final user = (data['user'] ?? data) as Map<String, dynamic>;
      final name = (user['full_name'] ?? '').toString();
      if (mounted) setState(() => _userName = name.isNotEmpty ? name : null);
    } catch (_) {
      if (mounted) setState(() => _userName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),

      drawer: const DrawerMenu(),

      body: _buildBody(),

      // ✅ Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6A1B9A),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Account",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const Center(child: Text('Favorites coming soon'));
      case 2:
        return const CartPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF6A1B9A)),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                Text(
                  _userName != null && _userName!.isNotEmpty
                      ? "Welcome $_userName"
                      : "Welcome",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.notifications, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 6,
                  )
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Categories Row (Men / Women / Kids → open CategoriesPage)
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  bool isHovered = _hoveredCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesPage(
                            categoryName: categories[index]["name"]!,
                            categorySlug: categories[index]["slug"]!,
                          ),
                        ),
                      );
                    },

                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredCategoryIndex = index;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredCategoryIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 16.0),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isHovered
                              ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: isHovered ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(
                                  categories[index]["image"]!,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 70,
                              child: Text(
                                categories[index]["name"]!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ✅ New Arrivals Section
            GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _isImageTapped = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  _isImageTapped = false;
                });
              },
              onTapCancel: () {
                setState(() {
                  _isImageTapped = false;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "New Arrivals",
                          style: GoogleFonts.dancingScript(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6A1B9A),
                            shadows: const [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.purpleAccent,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: AnimatedScale(
                        scale: _isImageTapped ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Image.asset(
                          categories[0]["image"]!,
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "Your Boutique Content Here",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
