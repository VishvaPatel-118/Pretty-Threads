import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/services/auth.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _loading = false;
  bool _loadingPayments = false;
  List<Map<String, dynamic>> _payments = const [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final id = (widget.user['id'] ?? 0) as int;
      final res = await ApiService.adminListPayments(token: token, userId: id, perPage: 10);
      // Handle both { data: { data: [...] }} and { data: [...] }
      List<Map<String, dynamic>> items = [];
      if (res['data'] is Map && res['data']['data'] is List) {
        items = List<Map<String, dynamic>>.from(res['data']['data']);
      } else if (res['data'] is List) {
        items = List<Map<String, dynamic>>.from(res['data']);
      }
      if (!mounted) return;
      setState(() => _payments = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  Future<void> _toggleBlock() async {
    setState(() => _loading = true);
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      final id = (widget.user['id'] ?? 0) as int;
      final isBlocked = widget.user['is_blocked'] == true;
      if (isBlocked) {
        await ApiService.adminUnblockUser(token: token, userId: id);
        widget.user['is_blocked'] = false;
      } else {
        await ApiService.adminBlockUser(token: token, userId: id);
        widget.user['is_blocked'] = true;
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isBlocked ? 'User unblocked' : 'User blocked')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final name = (u['full_name'] ?? u['name'] ?? 'User').toString();
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone_number'] ?? '').toString();
    final address = (u['full_address'] ?? '').toString();
    final city = (u['city'] ?? '').toString();
    final pincode = (u['pincode'] ?? '').toString();
    final isAdmin = u['is_admin'] == true;
    final isBlocked = u['is_blocked'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _toggleBlock,
            icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
            label: Text(isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 32, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(email),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Chip(label: Text(isAdmin ? 'Admin' : 'User')),
                      Chip(label: Text(isBlocked ? 'Blocked' : 'Active'),
                        avatar: Icon(isBlocked ? Icons.error_outline : Icons.check_circle_outline),),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text('Contact', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _kv('Phone', phone.isEmpty ? '-' : phone),
          _kv('Address', address.isEmpty ? '-' : address),
          _kv('City', city.isEmpty ? '-' : city),
          _kv('Pincode', pincode.isEmpty ? '-' : pincode),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text('Recent Payments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingPayments)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ))
          else if (_payments.isEmpty)
            const Text('No payments found.')
          else
            Column(
              children: [
                for (final p in _payments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Payment #'+(p['id']?.toString() ?? '')),
                    subtitle: Text('Status: '+(p['status']?.toString() ?? '-')+'  •  Amount: '+(p['amount']?.toString() ?? '-')),
                    trailing: Text((p['created_at'] ?? '').toString(), style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadingPayments ? null : _fetchPayments,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh payments'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
