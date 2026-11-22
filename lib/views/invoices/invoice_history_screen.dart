import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database/database_helper.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  final int? refreshKey;
  const InvoiceHistoryScreen({super.key, this.refreshKey});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(InvoiceHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadTransactions(showLoading: _transactions.isEmpty);
    }
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final list = await _db.getTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = list;
      _isLoading = false;
    });
  }

  void _showDetailModal(TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(txn.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              if (txn.tableNumber != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Nomor Meja: Meja ${txn.tableNumber!.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
              Text(
                'Kasir: ${txn.userName} • ${DateFormat('dd MMM yyyy, HH:mm').format(txn.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                child: ListView(
                  shrinkWrap: true,
                  children: txn.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${i.productName}(meja no ${txn.tableNumber}) (x${i.quantity})')),
                        Text(_currency.format(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Metode Pembayaran'),
                  Text(txn.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_currency.format(txn.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uang Diterima'),
                  Text(_currency.format(txn.paidAmount)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian'),
                  Text(_currency.format(txn.changeAmount)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulasi cetak ulang invoice Bluetooth printer!')),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Ulang Struk'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _confirmDelete(ctx, txn),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Struk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext sheetContext, TransactionModel txn) async {
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Struk?'),
        content: Text('Invoice ${txn.invoiceNumber} akan dihapus dan stok dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteTransaction(txn.id!);
    if (!mounted || !sheetContext.mounted) return;
    Navigator.pop(sheetContext);
    _loadTransactions(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final t = _transactions[i];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () => _showDetailModal(t),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.paymentMethod == 'Tunai' ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.paymentMethod,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: t.paymentMethod == 'Tunai' ? Colors.green.shade800 : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kasir: ${t.userName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    if (t.tableNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Meja ${t.tableNumber!.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${t.items.length} Barang', style: const TextStyle(fontSize: 13)),
                        Text(
                          _currency.format(t.total),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
