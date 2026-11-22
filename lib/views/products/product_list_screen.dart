import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../services/database/database_helper.dart';
import '../widgets/product_image_widget.dart';

class ProductListScreen extends StatefulWidget {
  final bool isOwner;

  const ProductListScreen({super.key, required this.isOwner});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final ImagePicker _picker = ImagePicker();

  List<ProductModel> _products = [];
  int _catalogProductCount = 0;
  int _catalogStock = 0;
  double _catalogValue = 0;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final list = await _db.getProducts(search: _searchController.text);
    final catalog = _searchController.text.isEmpty ? list : await _db.getProducts();
    if (!mounted) return;
    setState(() {
      _products = list;
      _catalogProductCount = catalog.length;
      _catalogStock = catalog.fold(0, (total, p) => total + p.stock);
      _catalogValue = catalog.fold(0.0, (total, p) => total + p.sellPrice * p.stock);
      _isLoading = false;
    });
  }

  void _showProductDialog([ProductModel? product]) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final buyCtrl = TextEditingController(text: product?.buyPrice.toStringAsFixed(0) ?? '');
    final sellCtrl = TextEditingController(text: product?.sellPrice.toStringAsFixed(0) ?? '');
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? 'Umum');
    String? selectedImagePath = product?.imagePath;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFFF1F5F9),
                              child: selectedImagePath != null && File(selectedImagePath!).existsSync()
                                  ? Image.file(File(selectedImagePath!), fit: BoxFit.cover)
                                  : const Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Theme.of(context).colorScheme.primary,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () async {
                                  final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                  if (img != null) {
                                    setDialogState(() => selectedImagePath = img.path);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          if (selectedImagePath != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Material(
                                color: Colors.red.shade600,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => setDialogState(() => selectedImagePath = null),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Produk', isDense: true, border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: barcodeCtrl,
                      decoration: const InputDecoration(labelText: 'Barcode / SKU (Opsional)', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: buyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Beli (Rp)', isDense: true, border: OutlineInputBorder()),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Validasi harga' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: sellCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Jual (Rp)', isDense: true, border: OutlineInputBorder()),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Validasi harga' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stok', isDense: true, border: OutlineInputBorder()),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Validasi stok' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: categoryCtrl,
                            decoration: const InputDecoration(labelText: 'Kategori', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final p = ProductModel(
                  id: product?.id,
                  name: nameCtrl.text.trim(),
                  barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                  buyPrice: double.parse(buyCtrl.text),
                  sellPrice: double.parse(sellCtrl.text),
                  stock: int.parse(stockCtrl.text),
                  category: categoryCtrl.text.trim().isEmpty ? 'Umum' : categoryCtrl.text.trim(),
                  imagePath: selectedImagePath,
                );

                if (isEdit) {
                  await _db.updateProduct(p);
                } else {
                  await _db.insertProduct(p);
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadProducts();
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ProductModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus ${p.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _db.deleteProduct(p.id!);
              _loadProducts();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _catalogMetric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
      body: Column(
        children: [
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Katalog', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _catalogMetric('Produk', '$_catalogProductCount')),
                      Expanded(child: _catalogMetric('Total stok', '$_catalogStock')),
                      Expanded(child: _catalogMetric('Nilai stok', _currency.format(_catalogValue))),
                    ]),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => _loadProducts(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('Belum ada produk', style: TextStyle(color: Colors.grey)),
                            if (widget.isOwner) ...[
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: () => _showProductDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Produk Pertama'),
                              )
                            ]
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _products.length,
                        key: const PageStorageKey('product-list'),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: ProductImageWidget(
                              imagePath: p.imagePath,
                              size: 48,
                              borderRadius: 8,
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p.stock < 5 ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Stok: ${p.stock}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: p.stock < 5 ? Colors.red : Colors.green.shade800,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(
                                    _currency.format(p.sellPrice),
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  if (widget.isOwner) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Margin: ${_currency.format(p.margin)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            trailing: widget.isOwner
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showProductDialog(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _confirmDelete(p),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
