import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_summary.dart';
import '../../services/database/database_helper.dart';

class ReportScreen extends StatefulWidget {
  final bool isOwner;

  const ReportScreen({super.key, required this.isOwner});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedFilterIndex = 0;
  SalesSummaryModel? _summary;
  List<Map<String, dynamic>> _trend = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedFilterIndex == 0) {
      start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (_selectedFilterIndex == 1) {
      final weekAgo = now.subtract(const Duration(days: 7));
      start = DateTime(weekAgo.year, weekAgo.month, weekAgo.day, 0, 0, 0);
    } else {
      start = DateTime(now.year, now.month, 1, 0, 0, 0);
    }

    final data = await _db.getSalesSummary(start, end);
    final trend = await _db.getSalesTrend(start, end);
    if (!mounted) return;
    setState(() {
      _summary = data;
      _trend = trend;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Akses Terbatas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Laporan penjualan dan laba hanya dapat diakses oleh Pemilik Usaha.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Hari Ini')),
                  ButtonSegment(value: 1, label: Text('7 Hari')),
                  ButtonSegment(value: 2, label: Text('Bulan Ini')),
                ],
                selected: {_selectedFilterIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedFilterIndex = set.first);
                  _loadReport();
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _metricCard('Total Omset', _currency.format(_summary!.totalRevenue), Icons.payments_outlined, const Color(0xFF15803D))),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Keuntungan Bersih', _currency.format(_summary!.totalProfit), Icons.trending_up_outlined, Colors.green.shade600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCard('Tunai (Cash)', _currency.format(_summary!.cashRevenue), Icons.money_outlined, const Color(0xFF15803D))),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('QRIS / Non-Tunai', _currency.format(_summary!.qrisRevenue), Icons.qr_code_2_outlined, Colors.blue.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCard('Total Transaksi', '${_summary!.totalTransactions}', Icons.receipt_outlined, Colors.indigo.shade600)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('Item Terjual', '${_summary!.totalItemsSold}', Icons.shopping_bag_outlined, Colors.amber.shade700)),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Tren Penjualan',
                  child: _trend.isEmpty
                      ? _emptyState(Icons.show_chart_outlined, 'Belum ada data penjualan di periode ini')
                      : Column(
                          children: [
                            _buildTrendChart(),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(width: 6),
                                      Text('Omset', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(width: 6),
                                      Text('Laba Bersih', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Produk Terlaris (Best Seller)',
                  child: _summary!.bestSellers.isEmpty
                      ? _emptyState(Icons.emoji_objects_outlined, 'Belum ada produk terjual di periode ini')
                      : Column(
                          children: List.generate(
                            _summary!.bestSellers.length,
                            (i) {
                              final item = _summary!.bestSellers[i];
                              return _bestSellerRow(i + 1, item.productName, item.totalQty, item.totalRevenue);
                            },
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: const Color(0xFF15803D)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: child,
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final maxRevenue = _trend.map((t) => t['revenue'] as num).reduce((a, b) => a > b ? a : b).toDouble();
    final maxProfit = _trend.map((t) => t['profit'] as num).reduce((a, b) => a > b ? a : b).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_trend.length, (i) {
            final t = _trend[i];
            final revenue = (t['revenue'] as num).toDouble();
            final profit = (t['profit'] as num).toDouble();
            final revHeight = maxRevenue > 0 ? (revenue / maxRevenue) * 90 : 0.0;
            final profHeight = maxProfit > 0 ? (profit / maxProfit) * 90 : 0.0;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: revHeight,
                        width: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      ),
                      if (profit > 0 && profHeight > 0)
                        Container(
                          height: profHeight,
                          width: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(t['day'].toString().substring(8), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _bestSellerRow(int rank, String name, int qty, double revenue) {
    final isTop = rank <= 3;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: isTop ? Colors.amber.shade100 : Colors.grey.shade100,
            child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isTop ? Colors.amber.shade900 : Colors.black87)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('$qty terjual', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          trailing: Text(_currency.format(revenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
