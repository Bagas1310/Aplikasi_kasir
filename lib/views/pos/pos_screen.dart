import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../models/transaction_item.dart';
import '../../services/database/database_helper.dart';
import '../widgets/product_image_widget.dart';

class PosScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int? shiftId;
  final int? tableNumber;
  final VoidCallback? onTransactionCompleted;

  const PosScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.shiftId,
    this.tableNumber,
    this.onTransactionCompleted,
  });

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<ProductModel> _products = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final Map<int, TransactionItemModel> _cart = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await _db.getCategories();
    final items = await _db.getProducts(
      search: _searchController.text,
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
    );
    setState(() {
      _categories = ['Semua', ...cats];
      _products = items;
      _isLoading = false;
    });
  }

  void _addToCart(ProductModel product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok ${product.name} habis!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final existing = _cart[product.id!];
      final currentQty = existing?.quantity ?? 0;
      if (currentQty >= product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok maksimal tercapai (${product.stock})')),
        );
        return;
      }

      _cart[product.id!] = TransactionItemModel(
        productId: product.id!,
        productName: product.name,
        buyPrice: product.buyPrice,
        sellPrice: product.sellPrice,
        quantity: currentQty + 1,
      );
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      final existing = _cart[productId];
      if (existing == null) return;
      if (existing.quantity > 1) {
        _cart[productId] = existing.copyWith(
          quantity: existing.quantity - 1,
          subtotal: (existing.quantity - 1) * existing.sellPrice,
        );
      } else {
        _cart.remove(productId);
      }
    });
  }

  double get _cartTotal => _cart.values.fold(0.0, (acc, item) => acc + item.subtotal);
  int get _cartItemCount => _cart.values.fold(0, (acc, item) => acc + item.quantity);

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Keranjang Belanja ($_cartItemCount item)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: _cart.isEmpty
                          ? null
                          : () {
                              setState(() => _cart.clear());
                              setModalState(() {});
                              Navigator.pop(ctx);
                            },
                      child: const Text('Kosongkan', style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
                const Divider(),
                if (_cart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView(
                      shrinkWrap: true,
                      children: _cart.values.map((item) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${item.productName}(meja no ${widget.tableNumber})', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${_currency.format(item.sellPrice)} × ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  _removeFromCart(item.productId);
                                  setState(() {});
                                  setModalState(() {});
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  final p = _products.firstWhere((e) => e.id == item.productId);
                                  _addToCart(p);
                                  setState(() {});
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_currency.format(_cartTotal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _cart.isEmpty || widget.tableNumber == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _openCheckoutModal();
                          },
                    child: const Text('Lanjut ke Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCheckoutModal() {
    double discount = 0.0;
    double tax = 0.0;
    String method = 'Tunai';
    String? proofPath;
    final cashController = TextEditingController(text: _cartTotal.toStringAsFixed(0));
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final totalPay = _cartTotal - discount + tax;
          final cashVal = double.tryParse(cashController.text) ?? 0.0;
          final changeVal = method == 'Tunai' ? (cashVal - totalPay) : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proses Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tagihan', style: TextStyle(fontSize: 15)),
                        Text(_currency.format(totalPay), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Tunai', label: Text('Tunai'), icon: Icon(Icons.money)),
                      ButtonSegment(value: 'QRIS', label: Text('QRIS / Non-Tunai'), icon: Icon(Icons.qr_code_2)),
                    ],
                    selected: {method},
                    onSelectionChanged: (set) => setModalState(() {
                      method = set.first;
                      if (method == 'QRIS') cashController.text = totalPay.toStringAsFixed(0);
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (method == 'Tunai') ...[
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Uang Diterima (Rp)',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                        isDense: true,
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [totalPay, 50000.0, 100000.0, 200000.0].map((amt) {
                        return ActionChip(
                          label: Text(_currency.format(amt)),
                          onPressed: () => setModalState(() => cashController.text = amt.toStringAsFixed(0)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian:', style: TextStyle(fontSize: 15)),
                        Text(
                          _currency.format(changeVal < 0 ? 0 : changeVal),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: changeVal < 0 ? Colors.red : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bukti Pembayaran (Opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (proofPath != null)
                                TextButton(
                                  onPressed: () => setModalState(() => proofPath = null),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              side: BorderSide(color: proofPath != null ? const Color(0xFF15803D) : Colors.grey.shade400),
                            ),
                            onPressed: () async {
                              final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                              if (img != null) {
                                setModalState(() => proofPath = img.path);
                              }
                            },
                            icon: Icon(proofPath != null ? Icons.check_circle : Icons.upload_file, color: proofPath != null ? const Color(0xFF15803D) : null, size: 18),
                            label: Text(
                              proofPath != null ? 'Bukti Terlampir' : 'Unggah Bukti Transfer / QRIS',
                              style: TextStyle(color: proofPath != null ? const Color(0xFF15803D) : null, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (method == 'Tunai' && cashVal < totalPay)
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _submitTransaction(
                                totalPay: totalPay,
                                method: method,
                                paidAmount: method == 'Tunai' ? cashVal : totalPay,
                                changeAmount: changeVal < 0 ? 0 : changeVal,
                                discount: discount,
                                tax: tax,
                                paymentProof: proofPath,
                              );
                            },
                      child: const Text('Selesaikan Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitTransaction({
    required double totalPay,
    required String method,
    required double paidAmount,
    required double changeAmount,
    required double discount,
    required double tax,
    String? paymentProof,
  }) async {
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.millisecondsSinceEpoch.toString().substring(4)}';

    final txn = TransactionModel(
      invoiceNumber: invoiceNumber,
      userId: widget.userId,
      userName: widget.userName,
      shiftId: widget.shiftId,
      subtotal: _cartTotal,
      discount: discount,
      tax: tax,
      total: totalPay,
      paymentMethod: method,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      tableNumber: widget.tableNumber,
      paymentProof: paymentProof,
      createdAt: now,
      items: _cart.values.toList(),
    );

    try {
      final savedTxn = await _db.createTransaction(txn);
      setState(() => _cart.clear());
      _loadData();
      if (!mounted) return;
      _showReceiptDialog(savedTxn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReceiptDialog(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 8),
              Text('Transaksi Berhasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Text(txn.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Membeli',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D)),
                    ),
                  ),
                ),
                if (txn.tableNumber != null)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Meja ${txn.tableNumber!.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D)),
                      ),
                    ),
                  ),
                Center(
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(txn.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (txn.paymentProof != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text('Bukti Non-Tunai Terlampir', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const Divider(),
                ...txn.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${i.productName}(meja no ${txn.tableNumber}) × ${i.quantity}')),
                          Text(_currency.format(i.subtotal)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_currency.format(txn.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bayar (${txn.paymentMethod}):'),
                    Text(_currency.format(txn.paidAmount)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembalian:'),
                    Text(_currency.format(txn.changeAmount)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulasi cetak struk Bluetooth thermal berhasil!')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak Struk'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onTransactionCompleted != null) {
                widget.onTransactionCompleted!();
              } else if (widget.tableNumber != null && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.tableNumber != null
          ? AppBar(
              title: Text('Meja ${widget.tableNumber!.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await _db.freeTable(widget.tableNumber!);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.tableNumber != null ? Colors.green.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.tableNumber != null ? Colors.green.shade200 : Colors.amber.shade300,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.tableNumber != null ? Colors.green.shade600 : Colors.amber.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.tableNumber != null ? Icons.table_restaurant : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tableNumber != null
                            ? 'Meja ${widget.tableNumber!.toString().padLeft(2, '0')} Terpilih'
                            : 'Belum Memilih Meja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: widget.tableNumber != null ? Colors.green.shade900 : Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        widget.tableNumber != null
                            ? 'Pesanan otomatis terhubung ke meja ini'
                            : 'Pilih meja di tab "Pilih Meja" untuk aktifkan tombol Bayar',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.tableNumber != null ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_cartItemCount > 0)
                  InkWell(
                    onTap: _showCartModal,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.tableNumber != null ? Colors.green.shade600 : Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$_cartItemCount item',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => _loadData(),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                    _loadData();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('Tidak ada produk ditemukan', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.69,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final product = _products[i];
                          final inCart = _cart[product.id!]?.quantity ?? 0;

                          return InkWell(
                            onTap: () => _addToCart(product),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: inCart > 0 ? Theme.of(context).colorScheme.primary : const Color(0xFFE2E8F0),
                                  width: inCart > 0 ? 1.8 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: inCart > 0
                                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                            child: ProductImageWidget(
                                              imagePath: product.imagePath,
                                              size: double.infinity,
                                              borderRadius: 0,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              product.category,
                                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        if (inCart > 0)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.shopping_cart, size: 11, color: Colors.white),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$inCart',
                                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (product.stock <= 0)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              alignment: Alignment.center,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade700,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('Habis', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _currency.format(product.sellPrice),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 14,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Stok: ${product.stock}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: product.stock < 5 ? Colors.red.shade700 : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: inCart > 0 ? Theme.of(context).colorScheme.primary : const Color(0xFFF1F5F9),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: inCart > 0 ? Colors.white : const Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_cart.isNotEmpty)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showCartModal,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Badge(
                          label: Text('$_cartItemCount'),
                          backgroundColor: Colors.amber.shade700,
                          child: const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: _showCartModal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.tableNumber != null
                                  ? 'Total (Meja ${widget.tableNumber!.toString().padLeft(2, '0')})'
                                  : 'Total Pembayaran',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            Text(
                              _currency.format(_cartTotal),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.tableNumber != null ? Colors.green.shade600 : Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _cart.isEmpty || widget.tableNumber == null ? null : _showCartModal,
                      icon: Icon(widget.tableNumber != null ? Icons.payment : Icons.lock_outline, size: 18),
                      label: Text(
                        widget.tableNumber != null ? 'Bayar' : 'Pilih Meja',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
