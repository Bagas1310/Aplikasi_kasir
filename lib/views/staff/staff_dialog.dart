import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StaffDialog extends StatefulWidget {
  const StaffDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const StaffDialog(),
    );
  }

  @override
  State<StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<StaffDialog> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAddStaff() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.addStaff(
      name: _nameController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();
      setState(() => _isAdding = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username sudah terpakai'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffList = context.watch<AuthProvider>().staffList;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF064E3B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kelola Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('${staffList.length} staff terdaftar', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isAdding ? Icons.list_rounded : Icons.person_add_alt_1_rounded, color: Colors.white),
              tooltip: _isAdding ? 'Daftar Staff' : 'Tambah Staff Baru',
              onPressed: () => setState(() {
                _isAdding = !_isAdding;
                _obscurePassword = true;
              }),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 380,
        child: _isAdding ? _buildAddForm() : _buildStaffList(staffList),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              if (!_isAdding)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => _isAdding = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Staff'),
                  ),
                ),
              if (!_isAdding) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList(List staffList) {
    if (staffList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Belum ada staff terdaftar', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final colors = [Colors.blue, Colors.teal, Colors.deepPurple, Colors.orange, Colors.pink, Colors.indigo];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: staffList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final s = staffList[i];
          final color = colors[i % colors.length];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.shade100,
                  child: Text(s.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('@${s.username}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('STAFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                  onPressed: () => _confirmDelete(s.id, s.name),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Baru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username Login',
                prefixIcon: Icon(Icons.alternate_email),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password / PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isAdding = false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submitAddStaff,
                    child: const Text('Simpan Staff'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 10),
            const Text('Hapus Staff'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(ctx).style,
            children: [
              const TextSpan(text: 'Yakin ingin menghapus '),
              TextSpan(text: '"$name"', style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '? Tindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().deleteStaff(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
