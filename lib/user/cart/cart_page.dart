import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/services/cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartService();

  @override
  void initState() {
    super.initState();
    cart.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.purple.shade300,
      ),
      body: FutureBuilder(
        future: cart.ensureLoaded(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cart.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final image = ApiService.normalizeImageUrl(item.imageUrl);
                    return ListTile(
                      leading: image.isNotEmpty
                          ? (image.startsWith('assets/')
                              ? Image.asset(image, width: 56, height: 56, fit: BoxFit.cover)
                              : Image.network(image, width: 56, height: 56, fit: BoxFit.cover))
                          : const Icon(Icons.image, size: 40),
                      title: Text(item.name),
                      subtitle: Text('₹ ${item.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              final newQty = (item.quantity - 1).clamp(1, 999);
                              await cart.updateQuantity(item.slug, newQty);
                              setState(() {});
                            },
                          ),
                          Text(item.quantity.toString()),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              final newQty = (item.quantity + 1).clamp(1, 999);
                              await cart.updateQuantity(item.slug, newQty);
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await cart.remove(item.slug);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ₹ ${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement checkout flow (requires backend order API)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checkout coming soon')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade400),
                      child: const Text('Checkout'),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
