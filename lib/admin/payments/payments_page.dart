import 'package:flutter/material.dart';
import 'package:pretty_threads/services/auth.dart';
import 'package:pretty_threads/services/api.dart';

class PaymentsAdminPage extends StatefulWidget {
  const PaymentsAdminPage({super.key});

  @override
  State<PaymentsAdminPage> createState() => _PaymentsAdminPageState();
}

class _PaymentsAdminPageState extends State<PaymentsAdminPage> {
  bool _loading = false;
  String _status = 'all';
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
      final res = await ApiService.adminListPayments(
        token: token,
        status: _status == 'all' ? null : _status,
      );
      setState(() => _data = res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id) async {
    final statuses = ['pending', 'paid', 'failed', 'refunded'];
    final sel = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Update Status'),
        children: [
          ...statuses.map((s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(c, s),
                child: Text(s.toUpperCase()),
              )),
        ],
      ),
    );
    if (sel == null) return;
    try {
      final token = AuthService().token;
      if (token == null) throw Exception('Not authenticated');
      await ApiService.adminUpdatePaymentStatus(token: token, paymentId: id, status: sel);
      await _fetch();
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
      if (d['data'] is Map && d['data']['data'] is List) return List<Map<String, dynamic>>.from(d['data']['data']);
      return <Map<String, dynamic>>[];
    })();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Text('Status:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _status = v);
                  _fetch();
                },
              ),
              const Spacer(),
              IconButton(onPressed: _loading ? null : _fetch, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemBuilder: (c, i) {
                    final p = list[i];
                    final id = (p['id'] ?? 0) as int;
                    final amount = (p['amount'] ?? '').toString();
                    final status = (p['status'] ?? '').toString();
                    final method = (p['method'] ?? '').toString();
                    final userEmail = (p['user'] is Map) ? (p['user']['email'] ?? '').toString() : '';
                    return ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text('Payment #$id - $amount'),
                      subtitle: Text('Status: ${status.toUpperCase()}  |  Method: $method  ${userEmail.isNotEmpty ? '\nUser: $userEmail' : ''}'),
                      isThreeLine: userEmail.isNotEmpty,
                      trailing: TextButton(
                        onPressed: _loading ? null : () => _updateStatus(id),
                        child: const Text('Update Status'),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: list.length,
                ),
        ),
      ],
    );
  }
}
