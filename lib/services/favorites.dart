import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/services/api.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const _key = 'favorites_items_v1';

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final auth = AuthService();
    if (auth.isLoggedIn && auth.token != null) {
      try {
        final items = await ApiService.getFavorites(token: auth.token!);
        return items;
      } catch (_) {
        // fall back to local on error
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list
        .map((s) {
          try {
            final parts = s.split('|');
            // slug|name|price|imageUrl
            return {
              'slug': parts.isNotEmpty ? parts[0] : '',
              'name': parts.length > 1 ? parts[1] : '',
              'price': parts.length > 2 ? double.tryParse(parts[2]) ?? 0.0 : 0.0,
              'image_url': parts.length > 3 ? parts[3] : '',
            };
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => (m['slug'] ?? '').toString().isNotEmpty)
        .toList();
  }

  Future<bool> isFavorite(String slug) async {
    final auth = AuthService();
    if (auth.isLoggedIn && auth.token != null) {
      try {
        final items = await ApiService.getFavorites(token: auth.token!);
        return items.any((e) => (e['slug'] ?? '') == slug);
      } catch (_) {
        // fall back to local check on error
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.any((s) => s.startsWith('$slug|'));
  }

  Future<void> addFavorite({
    required String slug,
    required String name,
    required double price,
    String imageUrl = '',
    int? productId,
  }) async {
    final auth = AuthService();
    if (auth.isLoggedIn && auth.token != null) {
      try {
        final pid = await _ensureProductId(slug, productId);
        await ApiService.addFavorite(token: auth.token!, productId: pid);
        return;
      } catch (_) {
        // fall back to local persistence
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final encoded = _encode(slug, name, price, imageUrl);
    if (!list.any((s) => s.startsWith('$slug|'))) {
      list.add(encoded);
      await prefs.setStringList(_key, list);
    }
  }

  Future<void> removeFavorite(String slug, {int? productId}) async {
    final auth = AuthService();
    if (auth.isLoggedIn && auth.token != null) {
      try {
        final pid = await _ensureProductId(slug, productId);
        await ApiService.removeFavorite(token: auth.token!, productId: pid);
        return;
      } catch (_) {
        // fall back to local persistence
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.removeWhere((s) => s.startsWith('$slug|'));
    await prefs.setStringList(_key, list);
  }

  Future<void> toggleFavorite({
    required String slug,
    required String name,
    required double price,
    String imageUrl = '',
    int? productId,
  }) async {
    final fav = await isFavorite(slug);
    if (fav) {
      await removeFavorite(slug, productId: productId);
    } else {
      await addFavorite(slug: slug, name: name, price: price, imageUrl: imageUrl, productId: productId);
    }
  }

  String _encode(String slug, String name, double price, String imageUrl) {
    // Avoid delimiter conflicts by replacing pipes in fields
    final safeName = name.replaceAll('|', '/');
    final safeUrl = imageUrl.replaceAll('|', '%7C');
    return '$slug|$safeName|$price|$safeUrl';
  }

  Future<int> _ensureProductId(String slug, int? productId) async {
    if (productId != null) return productId;
    // Resolve via product detail
    final data = await ApiService.getProductBySlug(slug);
    final p = (data['data'] ?? data) as Map<String, dynamic>;
    final id = p['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? (throw Exception('Invalid product id'));
    throw Exception('Product id not found for slug: $slug');
  }
}
