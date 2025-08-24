import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Configurable at build time: flutter build apk/appbundle --dart-define=API_BASE_URL=https://your-domain
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ed4a35763e8c.ngrok-free.app',
  );

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // -----------------------------
  // User Cart (server-side)
  // -----------------------------
  static Future<Map<String, dynamic>> getCart({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/cart');
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch cart (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> addCartItem({
    required String token,
    required int productId,
    int quantity = 1,
    Map<String, dynamic>? attributes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/cart/items');
    final payload = <String, dynamic>{
      'product_id': productId,
      if (quantity > 0) 'quantity': quantity,
      if (attributes != null) 'attributes': attributes,
    };
    final resp = await http
        .post(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if ((resp.statusCode == 200 || resp.statusCode == 201) && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to add item (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String token,
    required int itemId,
    required int quantity,
  }) async {
    final uri = Uri.parse('$baseUrl/api/cart/items/$itemId');
    final resp = await http
        .put(uri, headers: _authHeaders(token), body: jsonEncode({'quantity': quantity}))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update item (${resp.statusCode})');
  }

  static Future<void> removeCartItem({
    required String token,
    required int itemId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/cart/items/$itemId');
    final resp = await http.delete(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to remove item (${resp.statusCode})');
  }

  static Future<void> clearCart({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/cart');
    final resp = await http.delete(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to clear cart (${resp.statusCode})');
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? fullAddress,
    String? city,
    String? pincode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');

    final body = {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber ?? '',
      'password': password,
      'password_confirmation': password,
      'full_address': fullAddress ?? '',
      'city': city ?? '',
      'pincode': pincode ?? '',
    };

    final resp = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);

    if (resp.statusCode == 201) {
      return data as Map<String, dynamic>;
    }

    // Try to extract validation errors or message
    final message = _extractErrorMessage(data) ?? 'Registration failed (${resp.statusCode})';
    throw Exception(message);
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    final resp = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);

    if (resp.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    final message = _extractErrorMessage(data) ?? 'Login failed (${resp.statusCode})';
    throw ApiException(message: message, statusCode: resp.statusCode);
  }

  static dynamic _parseJson(http.Response resp) {
    try {
      if (resp.body.isEmpty) return {};
      return jsonDecode(resp.body);
    } catch (_) {
      return {'raw': resp.body};
    }
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Top-level message if available (e.g., "Validation failed")
      final topMessage = data['message'] is String ? data['message'] as String : null;

      // Field-specific errors
      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        final msgs = <String>[];

        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String) msgs.add('$key: $first');
          } else if (value is String && value.isNotEmpty) {
            msgs.add('$key: $value');
          }
        });

        if (msgs.isNotEmpty) {
          final parts = <String>[];
          if (topMessage != null && topMessage.isNotEmpty) parts.add(topMessage);
          parts.addAll(msgs);
          return parts.join('\n');
        }
      }

      // Fallback to just the top-level message
      if (topMessage != null && topMessage.isNotEmpty) return topMessage;
    }
    return null;
  }

  // Normalize image URLs: if Laravel returns "/storage/...", prefix with baseUrl
  static String normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // If absolute URL
    if (url.startsWith('http')) {
      try {
        final u = Uri.parse(url);
        final base = Uri.parse(baseUrl);
        // If URL points to localhost/127.0.0.1 or a different origin but is a storage path, rebase to API origin
        final isLocal = (u.host == 'localhost' || u.host == '127.0.0.1');
        final looksLikeStorage = u.path.startsWith('/storage/') || u.path.contains('/storage/');
        final differentOrigin = (u.scheme != base.scheme) || (u.host != base.host) || (u.hasPort && u.port != base.port);
        if ((isLocal || differentOrigin) && looksLikeStorage) {
          return Uri(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : null,
            path: u.path,
            query: u.query,
          ).toString();
        }
        return url;
      } catch (_) {
        return url;
      }
    }
    // Relative path, prefix with API base
    if (url.startsWith('/')) return '$baseUrl$url';
    return url; // asset or other path
  }

  // ===== Protected endpoints (Profile) =====
  static Future<Map<String, dynamic>> getProfile({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/user');
    final resp = await http
        .get(uri, headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);
    if (resp.statusCode == 200) return data as Map<String, dynamic>;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch profile (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? fullAddress,
    String? city,
    String? pincode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user');
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (email != null) payload['email'] = email;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (fullAddress != null) payload['full_address'] = fullAddress;
    if (city != null) payload['city'] = city;
    if (pincode != null) payload['pincode'] = pincode;

    final resp = await http
        .put(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);
    if (resp.statusCode == 200) return data as Map<String, dynamic>;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update profile (${resp.statusCode})');
  }

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user/password');
    final resp = await http
        .put(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode({
            'current_password': currentPassword,
            'password': newPassword,
            'password_confirmation': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to change password (${resp.statusCode})');
  }

  // Delete account
  static Future<String> deleteAccount({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/user');
    final resp = await http
        .delete(
          uri,
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 204) return 'Account deleted successfully';
    final data = _parseJson(resp);
    if (resp.statusCode == 200) {
      final msg = (data is Map && data['message'] is String) ? data['message'] as String : 'Account deleted successfully';
      return msg;
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to delete account (${resp.statusCode})');
  }

  // Logout
  static Future<String> logout({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/auth/logout');
    final resp = await http
        .post(
          uri,
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);
    if (resp.statusCode == 200) {
      final msg = (data is Map && data['message'] is String) ? data['message'] as String : 'Logged out successfully';
      return msg;
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to logout (${resp.statusCode})');
  }

  // ===== Public catalog endpoints =====
  // Fetch categories (optionally only roots and with children)
  static Future<List<dynamic>> getCategories({bool onlyRoots = true, bool withChildren = true}) async {
    final params = <String, String>{
      'only': onlyRoots ? 'roots' : 'all',
      'with': withChildren ? 'subcategories' : 'none',
    };
    final uri = Uri.parse('$baseUrl/api/categories').replace(queryParameters: params);

    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return (data['data'] as List<dynamic>? ?? <dynamic>[]);
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch categories (${resp.statusCode})');
  }

  // Fetch a single category by slug (with its children)
  static Future<Map<String, dynamic>> getCategoryBySlug(String slug) async {
    final uri = Uri.parse('$baseUrl/api/categories/$slug');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return (data['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch category (${resp.statusCode})');
  }

  // Fetch products, optionally filtered by category slug. Returns Laravel paginator map.
  static Future<Map<String, dynamic>> getProducts({String? categorySlug, int page = 1, int perPage = 20}) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (categorySlug != null && categorySlug.isNotEmpty) 'category_slug': categorySlug,
    };
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return (data['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch products (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> getProductBySlug(String slug) async {
    final uri = Uri.parse('$baseUrl/api/products/$slug');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return (data['data'] as Map<String, dynamic>? ?? <String, dynamic>{});
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch product (${resp.statusCode})');
  }

  // ===== Admin/Product media (protected) =====
  static Future<String> uploadProductImage({
    required String token,
    required int productId,
    required File file,
  }) async {
    final uri = Uri.parse('$baseUrl/api/products/$productId/image');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_authHeaders(token));
    req.files.add(await http.MultipartFile.fromPath('image', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map && data['data'] is Map) {
      final img = (data['data'] as Map)['image_url']?.toString() ?? '';
      return img;
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to upload image (${resp.statusCode})');
  }

  // Upload category image (auth required)
  static Future<String> uploadCategoryImage({
    required String token,
    required int categoryId,
    required File file,
  }) async {
    final uri = Uri.parse('$baseUrl/api/categories/$categoryId/image');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_authHeaders(token));
    req.files.add(await http.MultipartFile.fromPath('image', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map && data['data'] is Map) {
      final img = (data['data'] as Map)['image_url']?.toString() ?? '';
      return img;
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to upload image (${resp.statusCode})');
  }

  // ===== Admin: Users =====
  // NOTE: Routes assume Laravel-style admin prefix: /api/admin/...
  // Adjust paths if your backend differs.
  static Future<Map<String, dynamic>> adminListUsers({
    required String token,
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) {
      return data;
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch users (${resp.statusCode})');
  }

  static Future<void> adminBlockUser({required String token, required int userId}) async {
    final uri = Uri.parse('$baseUrl/api/admin/users/$userId/block');
    final resp = await http.post(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to block user (${resp.statusCode})');
  }

  static Future<void> adminUnblockUser({required String token, required int userId}) async {
    final uri = Uri.parse('$baseUrl/api/admin/users/$userId/unblock');
    final resp = await http.post(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to unblock user (${resp.statusCode})');
  }

  // ===== Admin: Products CRUD =====
  static Future<Map<String, dynamic>> adminListProducts({
    required String token,
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId.toString(),
    };
    final uri = Uri.parse('$baseUrl/api/admin/products').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch products (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminCreateProduct({
    required String token,
    required String name,
    required double price,
    required int stock,
    required int categoryId,
    String? description,
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/products');
    final payload = <String, dynamic>{
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      if (description != null) 'description': description,
      if (extra != null) ...extra,
    };
    final resp = await http
        .post(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 201 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to create product (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminUpdateProduct({
    required String token,
    required int productId,
    String? name,
    double? price,
    int? stock,
    int? categoryId,
    String? description,
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/products/$productId');
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (extra != null) ...extra,
    };
    final resp = await http
        .put(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update product (${resp.statusCode})');
  }

  static Future<void> adminDeleteProduct({required String token, required int productId}) async {
    final uri = Uri.parse('$baseUrl/api/admin/products/$productId');
    final resp = await http.delete(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to delete product (${resp.statusCode})');
  }

  // ===== Admin: Categories CRUD (with parent/child) =====
  static Future<Map<String, dynamic>> adminListCategories({
    required String token,
    bool withChildren = true,
  }) async {
    final qp = <String, String>{
      if (withChildren) 'with': 'children',
    };
    final uri = Uri.parse('$baseUrl/api/admin/categories').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch categories (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminCreateCategory({
    required String token,
    required String name,
    int? parentId,
    String? description,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/categories');
    final payload = <String, dynamic>{
      'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (description != null) 'description': description,
    };
    final resp = await http
        .post(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 201 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to create category (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminUpdateCategory({
    required String token,
    required int categoryId,
    String? name,
    int? parentId,
    String? description,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/categories/$categoryId');
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (description != null) 'description': description,
    };
    final resp = await http
        .put(uri, headers: _authHeaders(token), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update category (${resp.statusCode})');
  }

  static Future<void> adminDeleteCategory({required String token, required int categoryId}) async {
    final uri = Uri.parse('$baseUrl/api/admin/categories/$categoryId');
    final resp = await http.delete(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to delete category (${resp.statusCode})');
  }

  // ===== Admin: Payments (start CRUD) =====
  static Future<Map<String, dynamic>> adminListPayments({
    required String token,
    int page = 1,
    int perPage = 20,
    String? status,
    int? userId,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null) 'user_id': userId.toString(),
    };
    final uri = Uri.parse('$baseUrl/api/admin/payments').replace(queryParameters: qp);
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch payments (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminGetPayment({required String token, required int paymentId}) async {
    final uri = Uri.parse('$baseUrl/api/admin/payments/$paymentId');
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch payment (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminUpdatePaymentStatus({
    required String token,
    required int paymentId,
    required String status, // e.g., pending, paid, failed, refunded
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/payments/$paymentId/status');
    final resp = await http
        .put(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update payment (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminRefundPayment({
    required String token,
    required int paymentId,
    double? amount,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/payments/$paymentId/refund');
    final payload = <String, dynamic>{
      if (amount != null) 'amount': amount,
    };
    final resp = await http
        .post(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to refund payment (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> adminGetUserCart({
    required String token,
    required int userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/users/$userId/cart');
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch user cart (${resp.statusCode})');
  }

  // ===== Favorites (authenticated) =====
  static Future<List<Map<String, dynamic>>> getFavorites({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/favorites');
    final resp = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    final data = _parseJson(resp);
    if (resp.statusCode == 200 && data is Map) {
      final list = (data['data'] as List? ?? const []);
      return List<Map<String, dynamic>>.from(list);
    }
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch favorites (${resp.statusCode})');
  }

  static Future<void> addFavorite({required String token, required int productId}) async {
    final uri = Uri.parse('$baseUrl/api/favorites/$productId');
    final resp = await http.post(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to add favorite (${resp.statusCode})');
  }

  static Future<void> removeFavorite({required String token, required int productId}) async {
    final uri = Uri.parse('$baseUrl/api/favorites/$productId');
    final resp = await http.delete(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to remove favorite (${resp.statusCode})');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
