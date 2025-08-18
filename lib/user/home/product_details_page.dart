import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/services/cart.dart';

class ProductDetailsPage extends StatefulWidget {
  final String slug;
  final String name;
  final double price;
  final String description;
  final List<String> images;

  const ProductDetailsPage({
    super.key,
    required this.slug,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? mainImage;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    mainImage = widget.images.isNotEmpty ? widget.images[0] : null; // Default first image if available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.purple.shade300,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMainImage(),
            ),
            // Horizontal scrollable thumbnails
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        mainImage = widget.images[index]; // Change main image on tap
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: mainImage == widget.images[index]
                              ? Colors.purple
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildImage(widget.images[index], width: 70, height: 70),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Name, price & description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('₹ ${widget.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 16),
                  Text(widget.description, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAddToCartBar(context),
    );
  }

  Widget _buildMainImage() {
    if (mainImage == null || mainImage!.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 64, color: Colors.grey),
      );
    }
    return _buildImage(mainImage!, height: 300, width: double.infinity);
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    final normalized = ApiService.normalizeImageUrl(path);
    final isAsset = normalized.startsWith('assets/');
    final imageWidget = isAsset
        ? Image.asset(normalized, fit: BoxFit.cover, width: width, height: height)
        : Image.network(normalized, fit: BoxFit.cover, width: width, height: height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageWidget,
    );
  }

  Widget _buildAddToCartBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => quantity = (quantity - 1).clamp(1, 999));
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: () {
                  setState(() => quantity = (quantity + 1).clamp(1, 999));
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final cart = CartService();
                final img = mainImage != null && mainImage!.isNotEmpty
                    ? ApiService.normalizeImageUrl(mainImage!)
                    : '';
                await cart.addItem(
                  slug: widget.slug,
                  name: widget.name,
                  price: widget.price,
                  imageUrl: img,
                  quantity: quantity,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade400),
              child: const Text('Add to Cart'),
            ),
          )
        ],
      ),
    );
  }
}
