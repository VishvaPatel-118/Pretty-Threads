import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _showEditCategoryDialog(Map<String, dynamic> category) async {
    final id = (category['id'] ?? 0) as int;
    final nameCtrl = TextEditingController(text: (category['name'] ?? '').toString());
    final parentCtrl = TextEditingController(text: (category['parent_id']?.toString() ?? ''));
    final descCtrl = TextEditingController(text: (category['description'] ?? '').toString());

    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit Category (ID: $id)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameCtrl),
              TextField(
                decoration: const InputDecoration(labelText: 'Parent ID (optional)'),
                keyboardType: TextInputType.number,
                controller: parentCtrl,
              ),
              TextField(decoration: const InputDecoration(labelText: 'Description'), controller: descCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'cancel'), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, 'delete'),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(c, 'save'), child: const Text('Save')),
        ],
      ),
    );

    if (res == null || res == 'cancel') return;
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');

      if (res == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Are you sure you want to delete "${nameCtrl.text.trim()}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          await ApiService.adminDeleteCategory(token: token, categoryId: id);
          await _fetch();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted.')));
        }
        return;
      }

      // Save
      final name = nameCtrl.text.trim();
      final parentId = parentCtrl.text.trim().isEmpty ? null : int.tryParse(parentCtrl.text.trim());
      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
      if (name.isEmpty) throw Exception('Name is required');
      await ApiService.adminUpdateCategory(
        token: token,
        categoryId: id,
        name: name,
        parentId: parentId,
        description: desc,
      );
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _uploadCategoryImage(int categoryId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final file = File(path);
      await ApiService.uploadCategoryImage(token: token, categoryId: categoryId, file: file);
      await _fetch();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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

  Future<void> _showCreateDialog({int? parentId}) async {
    final nameCtrl = TextEditingController();
    final parentCtrl = TextEditingController(text: parentId?.toString() ?? '');
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(parentId == null ? 'Create Category' : 'Create Subcategory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (parentId != null)
                  TextField(
                    controller: parentCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Parent ID'),
                  )
                else
                  TextField(
                    controller: parentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Parent ID (optional)'),
                  ),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
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
      final parentIdVal = parentId ?? (parentCtrl.text.trim().isEmpty ? null : int.tryParse(parentCtrl.text.trim()));
      final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
      if (name.isEmpty) throw Exception('Name is required');
      await ApiService.adminCreateCategory(
        token: token,
        name: name,
        parentId: parentIdVal,
        description: desc,
      );
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
                    final imageUrl = ApiService.normalizeImageUrl(cat['image_url']?.toString());
                    return ExpansionTile(
                      leading: imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: imageUrl.startsWith('assets/')
                                  ? AssetImage(imageUrl) as ImageProvider
                                  : NetworkImage(imageUrl),
                            )
                          : const CircleAvatar(child: Icon(Icons.category)),
                      title: Text('$name (ID: $id)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.subdirectory_arrow_right),
                            tooltip: 'Add Subcategory',
                            onPressed: _loading ? null : () => _showCreateDialog(parentId: id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Category',
                            onPressed: _loading ? null : () => _showEditCategoryDialog(cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.image_outlined),
                            tooltip: 'Upload Image',
                            onPressed: _loading ? null : () => _uploadCategoryImage(id),
                          ),
                        ],
                      ),
                      children: [
                        if (children.isEmpty)
                          const ListTile(title: Text('No subcategories'))
                        else
                          ...children.map((sc) {
                            final scImage = ApiService.normalizeImageUrl(sc['image_url']?.toString());
                            final scId = (sc['id'] ?? 0) as int;
                            return ListTile(
                              leading: scImage.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: scImage.startsWith('assets/')
                                          ? AssetImage(scImage) as ImageProvider
                                          : NetworkImage(scImage),
                                    )
                                  : const Icon(Icons.subdirectory_arrow_right),
                              title: Text(sc['name']?.toString() ?? 'Subcategory'),
                              subtitle: Text('ID: $scId'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit Subcategory',
                                    onPressed: _loading ? null : () => _showEditCategoryDialog(sc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.image_outlined),
                                    tooltip: 'Upload Image',
                                    onPressed: _loading ? null : () => _uploadCategoryImage(scId),
                                  ),
                                ],
                              ),
                            );
                          }),
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
