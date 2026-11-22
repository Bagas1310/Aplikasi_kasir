import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ShiftDialog extends StatefulWidget {
  const ShiftDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ShiftDialog(),
    );
  }

  @override
  State<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<ShiftDialog> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMsg;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSwitch() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.switchShift(
      _idController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shift berhasil dialihkan ke ${auth.currentUser?.name}'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    } else {
      setState(() => _errorMsg = 'Username/Nama atau password keliru');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentShift = auth.currentShift;
    final staffList = auth.staffList;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_alt, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Ganti Shift Kasir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            if (currentShift != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text('Shift aktif: ${currentShift.userName}', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMsg != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 13))),
                      ],
                    ),
                  ),
                if (staffList.isNotEmpty) ...[
                  const Text('Pilih cepat:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: staffList.map((s) {
                      final selected = _idController.text == s.username;
                      return ActionChip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: selected ? const Color(0xFF15803D) : Colors.green.shade100,
                          child: Text(s.name[0].toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF15803D))),
                        ),
                        label: Text(s.name, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                        side: BorderSide(color: selected ? const Color(0xFF15803D) : Colors.grey.shade300),
                        backgroundColor: selected ? Colors.green.shade50 : null,
                        onPressed: () => setState(() => _idController.text = s.username),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Username atau Nama Staff',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSwitch,
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Mulai Shift'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
