import 'package:flutter/material.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/services/api.dart';

class CategoriesAdminPage extends StatefulWidget {
  const CategoriesAdminPage({super.key});

  @override
  State<CategoriesAdminPage> createState() => _CategoriesAdminPageState();
}

class _CategoriesAdminPageState extends State<CategoriesAdminPage> {
  bool _loading = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final res = await ApiService.adminListCategories(token: token, withChildren: true);
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final parentCtrl = TextEditingController(); // enter parentId for subcategory
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Parent ID (optional)'), keyboardType: TextInputType.number, controller: parentCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Description'), controller: descCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final name = nameCtrl.text.trim();
      final parentId = int.tryParse(parentCtrl.text.trim());
      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
      if (name.isEmpty) throw Exception('Name is required');
      await ApiService.adminCreateCategory(token: token, name: name, parentId: parentId, description: desc);
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created.')));
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
      if (d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
      return <Map<String, dynamic>>[];
    })();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ElevatedButton.icon(onPressed: _loading ? null : _showCreateDialog, icon: const Icon(Icons.add), label: const Text('Add Category')),
              const SizedBox(width: 8),
              IconButton(onPressed: _loading ? null : _fetch, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemBuilder: (c, i) {
                    final cat = list[i];
                    final name = (cat['name'] ?? 'Category').toString();
                    final id = (cat['id'] ?? 0) as int;
                    final children = (cat['children'] is List) ? List<Map<String, dynamic>>.from(cat['children']) : <Map<String, dynamic>>[];
                    return ExpansionTile(
                      title: Text('$name (ID: $id)'),
                      children: [
                        if (children.isEmpty)
                          const ListTile(title: Text('No subcategories'))
                        else
                          ...children.map((sc) => ListTile(
                                leading: const Icon(Icons.subdirectory_arrow_right),
                                title: Text(sc['name']?.toString() ?? 'Subcategory'),
                                subtitle: Text('ID: ${sc['id']}'),
                              )),
                      ],
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
