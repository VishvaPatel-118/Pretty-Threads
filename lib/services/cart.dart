import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String slug;
  final String name;
  final double price;
  final String imageUrl; // normalized url or asset
  int quantity;

  CartItem({
    required this.slug,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
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

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, it) => sum + it.quantity);
  double get total => _items.fold(0.0, (sum, it) => sum + it.lineTotal);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _items
          ..clear()
          ..addAll(list.map(CartItem.fromMap));
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
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
    await ensureLoaded();
    final idx = _items.indexWhere((e) => e.slug == slug);
    if (idx >= 0) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(CartItem(
        slug: slug,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
      ));
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateQuantity(String slug, int quantity) async {
    await ensureLoaded();
    final idx = _items.indexWhere((e) => e.slug == slug);
    if (idx >= 0) {
      _items[idx].quantity = quantity.clamp(1, 999);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> remove(String slug) async {
    await ensureLoaded();
    _items.removeWhere((e) => e.slug == slug);
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _items.clear();
    await _persist();
    notifyListeners();
  }
}
