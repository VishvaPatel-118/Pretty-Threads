import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/services/api.dart';

class ProductsAdminPage extends StatefulWidget {
  const ProductsAdminPage({super.key});

  @override
  State<ProductsAdminPage> createState() => _ProductsAdminPageState();
}

class _ProductsAdminPageState extends State<ProductsAdminPage> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _data; // expect paginator-like map

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _showEditDialog(Map<String, dynamic> product) async {
    final nameCtrl = TextEditingController(text: (product['name'] ?? '').toString());
    final priceCtrl = TextEditingController(text: (product['price'] ?? '').toString());
    final stockCtrl = TextEditingController(text: (product['stock'] ?? '0').toString());
    final descCtrl = TextEditingController(text: (product['description'] ?? '').toString());

    // Load categories with children for selection
    List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final res = await ApiService.adminListCategories(token: token, withChildren: true);
      if (res['data'] is List) {
        categories = List<Map<String, dynamic>>.from(res['data']);
      } else if (res['data'] is Map && res['data']['data'] is List) {
        categories = List<Map<String, dynamic>>.from(res['data']['data']);
      }
    } catch (_) {}

    int? selectedParentId;
    int? selectedChildId;

    // Try to infer current category id
    final currentCategoryId = (product['category_id'] is int) ? product['category_id'] as int : null;
    if (currentCategoryId != null) {
      // Check if current is a child; otherwise set as parent
      for (final cat in categories) {
        if ((cat['id'] ?? -1) == currentCategoryId) {
          selectedParentId = currentCategoryId;
          break;
        }
        final children = (cat['children'] is List) ? List<Map<String, dynamic>>.from(cat['children']) : <Map<String, dynamic>>[];
        for (final sub in children) {
          if ((sub['id'] ?? -1) == currentCategoryId) {
            selectedParentId = (cat['id'] ?? 0) as int;
            selectedChildId = currentCategoryId;
            break;
          }
        }
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number, controller: priceCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number, controller: stockCtrl),
                const SizedBox(height: 8),
                // Parent Category dropdown
                StatefulBuilder(
                  builder: (context, setSB) {
                    return DropdownButtonFormField<int>(
                      value: selectedParentId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final cat in categories)
                          DropdownMenuItem<int>(
                            value: (cat['id'] ?? 0) as int,
                            child: Text((cat['name'] ?? 'Category').toString()),
                          )
                      ],
                      onChanged: (val) {
                        setSB(() {
                          selectedParentId = val;
                          selectedChildId = null; // reset child when parent changes
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Subcategory dropdown
                StatefulBuilder(
                  builder: (context, setSB) {
                    final parent = categories.firstWhere(
                      (e) => (e['id'] ?? -1) == selectedParentId,
                      orElse: () => <String, dynamic>{},
                    );
                    final children = (parent['children'] is List)
                        ? List<Map<String, dynamic>>.from(parent['children'])
                        : <Map<String, dynamic>>[];
                    return DropdownButtonFormField<int>(
                      value: selectedChildId,
                      decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                      items: [
                        for (final sub in children)
                          DropdownMenuItem<int>(
                            value: (sub['id'] ?? 0) as int,
                            child: Text((sub['name'] ?? 'Subcategory').toString()),
                          )
                      ],
                      onChanged: children.isEmpty ? null : (val) => setSB(() => selectedChildId = val),
                    );
                  },
                ),
                TextField(decoration: const InputDecoration(labelText: 'Description'), controller: descCtrl, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (ok != true) return;
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final id = (product['id'] ?? 0) as int;
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim());
      final stock = int.tryParse(stockCtrl.text.trim());
      final int? categoryId = selectedChildId ?? selectedParentId;
      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

      final payload = <String, dynamic>{};
      if (name.isNotEmpty) payload['name'] = name;
      if (price != null) payload['price'] = price;
      if (stock != null) payload['stock'] = stock;
      if (categoryId != null) payload['category_id'] = categoryId;
      if (desc != null) payload['description'] = desc;

      await ApiService.adminUpdateProduct(
        token: token,
        productId: id,
        name: payload['name'],
        price: payload['price'],
        stock: payload['stock'],
        categoryId: payload['category_id'],
        description: payload['description'],
      );
      await _fetch(search: _searchCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _uploadImage(int productId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final file = File(path);
      final url = await ApiService.uploadProductImage(token: token, productId: productId, file: file);
      await _fetch(search: _searchCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _fetch({String? search}) async {
    setState(() => _loading = true);
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final res = await ApiService.adminListProducts(token: token, search: search);
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      await ApiService.adminDeleteProduct(token: token, productId: id);
      await _fetch(search: _searchCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();

    // Load categories with children for selection
    List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final res = await ApiService.adminListCategories(token: token, withChildren: true);
      if (res['data'] is List) {
        categories = List<Map<String, dynamic>>.from(res['data']);
      } else if (res['data'] is Map && res['data']['data'] is List) {
        categories = List<Map<String, dynamic>>.from(res['data']['data']);
      }
    } catch (_) {}

    int? selectedParentId;
    int? selectedChildId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number, controller: priceCtrl),
                TextField(decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number, controller: stockCtrl),
                const SizedBox(height: 8),
                // Parent Category dropdown
                StatefulBuilder(
                  builder: (context, setSB) {
                    return DropdownButtonFormField<int>(
                      value: selectedParentId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final cat in categories)
                          DropdownMenuItem<int>(
                            value: (cat['id'] ?? 0) as int,
                            child: Text((cat['name'] ?? 'Category').toString()),
                          )
                      ],
                      onChanged: (val) {
                        setSB(() {
                          selectedParentId = val;
                          selectedChildId = null; // reset child when parent changes
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Subcategory dropdown (depends on parent)
                StatefulBuilder(
                  builder: (context, setSB) {
                    final parent = categories.firstWhere(
                      (e) => (e['id'] ?? -1) == selectedParentId,
                      orElse: () => <String, dynamic>{},
                    );
                    final children = (parent['children'] is List)
                        ? List<Map<String, dynamic>>.from(parent['children'])
                        : <Map<String, dynamic>>[];
                    return DropdownButtonFormField<int>(
                      value: selectedChildId,
                      decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                      items: [
                        for (final sub in children)
                          DropdownMenuItem<int>(
                            value: (sub['id'] ?? 0) as int,
                            child: Text((sub['name'] ?? 'Subcategory').toString()),
                          )
                      ],
                      onChanged: children.isEmpty
                          ? null
                          : (val) {
                              setSB(() => selectedChildId = val);
                            },
                    );
                  },
                ),
                TextField(decoration: const InputDecoration(labelText: 'Description'), controller: descCtrl, maxLines: 3),
                const SizedBox(height: 8),
                const Text('Image upload will be available after creating the product.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create')),
          ],
        );
      },
    );

    if (ok != true) return;
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
      final int? categoryId = selectedChildId ?? selectedParentId; // prefer subcategory if chosen
      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
      if (name.isEmpty || categoryId == null) {
        throw Exception('Name and Category are required');
      }
      await ApiService.adminCreateProduct(
        token: token,
        name: name,
        price: price,
        stock: stock,
        categoryId: categoryId,
        description: desc,
      );
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product created.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = (() {
      final d = _data;
      if (d == null) return <Map<String, dynamic>>[];
      // Try common shapes
      if (d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
      if (d['data'] is Map && d['data']['data'] is List) return List<Map<String, dynamic>>.from(d['data']['data']);
      return <Map<String, dynamic>>[];
    })();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products...', border: OutlineInputBorder()),
                  onSubmitted: (v) => _fetch(search: v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _loading ? null : () => _fetch(search: _searchCtrl.text.trim()), child: const Text('Search')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _loading ? null : _showCreateDialog, icon: const Icon(Icons.add), label: const Text('Add')),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemBuilder: (c, i) {
                    final p = list[i];
                    final name = (p['name'] ?? 'Product').toString();
                    final price = (p['price'] ?? '').toString();
                    final stock = (p['stock'] ?? '').toString();
                    final id = (p['id'] ?? 0) as int;
                    final imageUrl = ApiService.normalizeImageUrl(p['image_url']?.toString());
                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: imageUrl.startsWith('assets/')
                                  ? AssetImage(imageUrl) as ImageProvider
                                  : NetworkImage(imageUrl),
                            )
                          : const CircleAvatar(child: Icon(Icons.inventory_2)),
                      title: Text(name),
                      subtitle: Text('Price: $price  |  Stock: $stock'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _loading ? null : () => _showEditDialog(p),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.image_outlined),
                            onPressed: _loading ? null : () => _uploadImage(id),
                            tooltip: 'Upload Image',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _loading
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Delete Product'),
                                        content: Text('Are you sure you want to delete "$name"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteProduct(id);
                                    }
                                  },
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: list.length,
                ),
        )
      ],
    );
  }
}
