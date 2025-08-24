import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'products_page.dart';

class CategoriesPage extends StatefulWidget {
  final String categoryName; // Display name e.g., Men
  final String categorySlug; // e.g., men

  const CategoriesPage({super.key, required this.categoryName, required this.categorySlug});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _subcategories = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cat = await ApiService.getCategoryBySlug(widget.categorySlug);
      final children = (cat['children'] as List<dynamic>? ?? <dynamic>[]);
      if (mounted) {
        setState(() {
          _subcategories = children;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.categoryName} Subcategories"),
        backgroundColor: Colors.purple.shade300,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _fetch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subcategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final subcat = _subcategories[index] as Map<String, dynamic>;
                    final name = (subcat['name'] ?? '').toString();
                    final slug = (subcat['slug'] ?? '').toString();
                    final raw = (subcat['image_url'] ?? '').toString();
                    final imageUrl = ApiService.normalizeImageUrl(raw);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductsPage(
                              subcategoryName: name,
                              subcategorySlug: slug,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: imageUrl.isNotEmpty
                                    ? (imageUrl.startsWith('assets/')
                                        ? Image.asset(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ))
                                    : Container(
                                        color: Colors.grey[200],
                                        width: double.infinity,
                                        child: const Icon(Icons.category, size: 48, color: Colors.grey),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
