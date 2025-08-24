import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_threads/user/authentication/login_screen.dart';
import 'drawer_menu.dart';

import 'package:pretty_threads/user/home/categories_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_threads/user/profile/profile_page.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/user/cart/cart_page.dart';
import 'package:pretty_threads/user/favorites/favorites_page.dart';
import 'package:pretty_threads/theme/app_theme.dart';

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
  
  // Dynamic categories fetched from backend
  List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  bool _loadingCategories = false;

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

  // Local placeholder mapping when backend image_url is missing
  String? _defaultAssetForSlug(String slug) {
    switch (slug) {
      case 'men':
        return 'assets/images/mensuits.webp';
      case 'women':
        return 'assets/images/kurti.jpeg';
      case 'kids':
        return 'assets/images/pinkgown.jpg';
      default:
        return null; // no default -> will show icon placeholder
    }
  }

  // Builds a circular avatar for category using asset or network image with error fallback.
  Widget _buildCategoryAvatar(String url) {
    if (url.isEmpty) {
      return const CircleAvatar(radius: 30, child: Icon(Icons.category));
    }
    if (url.startsWith('assets/')) {
      return CircleAvatar(radius: 30, backgroundImage: AssetImage(url));
    }
    // For network images, use ClipOval + Image.network to get errorBuilder support
    return ClipOval(
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: 60,
          height: 60,
          child: CircleAvatar(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  // Image on the New Arrivals card; uses first category image if available.
  Widget _buildNewArrivalsImage() {
    final String url = _categories.isNotEmpty
        ? ((_categories.first['final_image'] ?? _categories.first['image_url'] ?? '').toString())
        : '';
    if (url.isEmpty) {
      return Container(
        width: 160,
        height: 120,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: 160, height: 120, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      width: 160,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 160,
        height: 120,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await ApiService.getCategories(onlyRoots: true, withChildren: false);
      // Expecting items with fields: name, slug, image_url
      final mapped = list
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'name': (e['name'] ?? '').toString(),
                'slug': (e['slug'] ?? '').toString(),
                'image_url': ApiService.normalizeImageUrl(e['image_url']?.toString()),
              })
          .where((e) => (e['name'] as String).isNotEmpty && (e['slug'] as String).isNotEmpty)
          .map((e) {
            final slug = (e['slug'] as String).toLowerCase();
            final img = (e['image_url'] as String);
            final fallback = _defaultAssetForSlug(slug);
            return {
              ...e,
              if (img.isEmpty && fallback != null) 'final_image': fallback else 'final_image': img,
            };
          })
          .toList();
      if (mounted) setState(() => _categories = mapped);
    } catch (_) {
      if (mounted) setState(() => _categories = <Map<String, dynamic>>[]);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
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
    _loadCategories();
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
      appBar: AppTheme.buildAppBar('Pretty Threads'),

      drawer: const DrawerMenu(),

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _buildBody(),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundColor,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.secondaryText,
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
        return const FavoritesPage();
      case 2:
        return const CartPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.1),
                  blurRadius: 6,
                )
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search, color: AppTheme.secondaryText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Categories Row (Dynamic from backend)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isHovered = _hoveredCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoriesPage(
                          categoryName: (_categories[index]["name"] ?? '').toString(),
                          categorySlug: (_categories[index]["slug"] ?? '').toString(),
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
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isHovered
                            ? [
                          BoxShadow(
                            color: AppTheme.shadowColor.withOpacity(0.3),
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
                            child: _buildCategoryAvatar((
                              _categories[index]['final_image'] ?? _categories[index]['image_url'] ?? ''
                            ).toString()),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 70,
                            child: Text(
                              (_categories[index]["name"] ?? '').toString(),
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

          // New Arrivals Section
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
                  colors: [AppTheme.accentLight, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withOpacity(0.3),
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
                          color: AppTheme.primary,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: AppTheme.shadowColor,
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
                      child: _buildNewArrivalsImage(),
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
    );
  }
}
