import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'product_details_page.dart';
import 'package:pretty_threads/user/cart/cart_page.dart';

class ProductsPage extends StatefulWidget {
  final String subcategoryName;
  final String subcategorySlug;

  const ProductsPage({super.key, required this.subcategoryName, required this.subcategorySlug});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _products = const [];

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
      final data = await ApiService.getProducts(categorySlug: widget.subcategorySlug, page: 1, perPage: 50);
      final items = (data['data'] as List<dynamic>? ?? <dynamic>[]);
      if (mounted) {
        setState(() {
          _products = items;
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
        title: Text("${widget.subcategoryName} Products"),
        backgroundColor: Colors.purple.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
            },
          )
        ],
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
                        ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final product = _products[index] as Map<String, dynamic>;
                    final name = (product['name'] ?? '').toString();
                    final slug = (product['slug'] ?? '').toString();
                    final dynamic rawPrice = product['price'];
                    final double price = rawPrice is num
                        ? rawPrice.toDouble()
                        : double.tryParse((rawPrice ?? '').toString()) ?? 0.0;
                    final imageUrlRaw = (product['image_url'] ?? '').toString();
                    final imageUrl = ApiService.normalizeImageUrl(imageUrlRaw);
                    return GestureDetector(
                      onTap: () async {
                        // Fetch full product details if needed
                        final details = await ApiService.getProductBySlug(slug);
                        final desc = (details['description'] ?? '').toString();
                        final images = <String>[];
                        if (details['image_url'] is String && (details['image_url'] as String).isNotEmpty) {
                          images.add(ApiService.normalizeImageUrl(details['image_url'] as String));
                        }
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(
                              slug: slug,
                              name: name,
                              price: price,
                              description: desc,
                              images: images,
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
                                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
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
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
