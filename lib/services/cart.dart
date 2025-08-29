import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/services/auth.dart';

/// Thrown when a cart operation is attempted without being logged in.
class LoginRequiredException implements Exception {
  final String message;
  const LoginRequiredException([this.message = 'Please login first']);
  @override
  String toString() => 'LoginRequiredException: ' + message;
}

class CartItem {
  final String slug;
  final String name;
  final double price;
  final String imageUrl; // normalized url or asset
  int quantity;
  final int? itemId; // server cart_items.id when logged in

  CartItem({
    required this.slug,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.itemId,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
        // itemId is intentionally not persisted to local storage
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        slug: map['slug'] as String,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        imageUrl: map['imageUrl'] as String,
        quantity: map['quantity'] as int,
      );
}

class CartService extends ChangeNotifier {
  static const _storageKey = 'cart_items_v1';
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  bool _loaded = false;
  bool _serverBacked = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, it) => sum + it.quantity);
  double get total => _items.fold(0.0, (sum, it) => sum + it.lineTotal);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final auth = AuthService();
    await auth.loadFromStorage();
    _serverBacked = auth.isLoggedIn;
    if (_serverBacked) {
      // Load from server
      try {
        final data = await ApiService.getCart(token: auth.token!);
        // Expected structure: { status, data: { id, items: [ { id, quantity, unit_price, line_total, product: {...} } ] }, meta: { total, item_count } }
        final cartData = (data['data'] as Map<String, dynamic>? ?? {});
        final list = (cartData['items'] as List<dynamic>? ?? const []);
        _items
          ..clear()
          ..addAll(list.map((e) {
            final m = e as Map<String, dynamic>;
            final prod = (m['product'] as Map<String, dynamic>? ?? const {});
            double _asDouble(dynamic v) {
              if (v is num) return v.toDouble();
              if (v is String) return double.tryParse(v) ?? 0.0;
              return 0.0;
            }
            int _asInt(dynamic v) {
              if (v is num) return v.toInt();
              if (v is String) return int.tryParse(v) ?? 0;
              return 0;
            }
            return CartItem(
              itemId: (m['id'] as num?)?.toInt(),
              slug: (prod['slug'] ?? '').toString(),
              name: (prod['name'] ?? '').toString(),
              price: (() {
                final up = _asDouble(m['unit_price']);
                if (up > 0) return up;
                final pp = _asDouble(prod['price']);
                return pp;
              })(),
              imageUrl: (prod['image_url'] ?? '').toString(),
              quantity: (() {
                final q = _asInt(m['quantity']);
                return q > 0 ? q : 1;
              })(),
            );
          }));
      } catch (_) {
        // If server fails, fallback to empty cart to avoid mixing with local
        _items.clear();
      }
      _loaded = true;
      notifyListeners();
      return;
    }

    // Guest carts are disabled: do not load any local cart for logged-out users.
    _items.clear();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    // Do not persist when server-backed or when not logged in (guest carts disabled)
    if (_serverBacked) return;
    final auth = AuthService();
    await auth.loadFromStorage();
    if (!auth.isLoggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> addItem({
    required String slug,
    required String name,
    required double price,
    required String imageUrl,
    int quantity = 1,
  }) async {
    final auth = AuthService();
    await auth.loadFromStorage();
    if (!auth.isLoggedIn) {
      throw const LoginRequiredException();
    }
    await ensureLoaded();
    // Server-backed only (no guest cart)
    final prod = await ApiService.getProductBySlug(slug);
    final productId = (prod['id'] as num?)?.toInt();
    if (productId == null) return;
    await ApiService.addCartItem(token: auth.token!, productId: productId, quantity: quantity);
    // Refresh from server
    _loaded = false;
    await ensureLoaded();
  }

  Future<void> updateQuantity(String slug, int quantity) async {
    final auth = AuthService();
    await auth.loadFromStorage();
    if (!auth.isLoggedIn) {
      throw const LoginRequiredException();
    }
    await ensureLoaded();
    final idx = _items.indexWhere((e) => e.slug == slug);
    if (idx < 0) return;
    final item = _items[idx];
    final itemId = item.itemId;
    if (itemId == null) return;
    await ApiService.updateCartItem(token: auth.token!, itemId: itemId, quantity: quantity.clamp(1, 999));
    _loaded = false;
    await ensureLoaded();
  }

  Future<void> remove(String slug) async {
    final auth = AuthService();
    await auth.loadFromStorage();
    if (!auth.isLoggedIn) {
      throw const LoginRequiredException();
    }
    await ensureLoaded();
    final idx = _items.indexWhere((e) => e.slug == slug);
    if (idx < 0) return;
    final itemId = _items[idx].itemId;
    if (itemId == null) return;
    await ApiService.removeCartItem(token: auth.token!, itemId: itemId);
    _loaded = false;
    await ensureLoaded();
  }

  Future<void> clear() async {
    final auth = AuthService();
    await auth.loadFromStorage();
    if (!auth.isLoggedIn) {
      throw const LoginRequiredException();
    }
    await ensureLoaded();
    await ApiService.clearCart(token: auth.token!);
    _loaded = false;
    await ensureLoaded();
  }

  // Clears local cart storage and in-memory cache. Does not touch server cart.
  Future<void> resetLocal() async {
    _items.clear();
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
