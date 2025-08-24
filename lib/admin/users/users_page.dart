import 'package:flutter/material.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/admin/users/user_detail_page.dart';
import 'package:pretty_threads/services/api.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _data; // expect paginator or list map

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({String? search}) async {
    setState(() => _loading = true);
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final res = await ApiService.adminListUsers(token: token, search: search);
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final id = (user['id'] ?? 0) as int;
      final isBlocked = user['is_blocked'] == true;
      if (isBlocked) {
        await ApiService.adminUnblockUser(token: token, userId: id);
      } else {
        await ApiService.adminBlockUser(token: token, userId: id);
      }
      await _fetch(search: _searchCtrl.text.trim());
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
      if (d['data'] is Map && d['data']['data'] is List) {
        return List<Map<String, dynamic>>.from(d['data']['data']);
      }
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
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search users...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => _fetch(search: v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : () => _fetch(search: _searchCtrl.text.trim()),
                child: const Text('Search'),
              )
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemBuilder: (c, i) {
                    final u = list[i];
                    final name = (u['full_name'] ?? u['name'] ?? 'User').toString();
                    final email = (u['email'] ?? '').toString();
                    final isAdmin = u['is_admin'] == true;
                    final isBlocked = u['is_blocked'] == true;
                    return ListTile(
                      leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                      title: Text(name + (isAdmin ? ' (admin)' : '')),
                      subtitle: Text(email),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => UserDetailPage(user: Map<String, dynamic>.from(u))),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isBlocked ? 'Blocked' : 'Active',
                              style: TextStyle(color: isBlocked ? Colors.red : Colors.green)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _loading ? null : () => _toggleBlock(u),
                            child: Text(isBlocked ? 'Unblock' : 'Block'),
                          )
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
