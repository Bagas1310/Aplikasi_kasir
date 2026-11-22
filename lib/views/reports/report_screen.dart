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
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_summary == null)
                const SizedBox()
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Omset',
                        _currency.format(_summary!.totalRevenue),
                        Icons.payments_outlined,
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Keuntungan Bersih',
                        _currency.format(_summary!.totalProfit),
                        Icons.trending_up_outlined,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Transaksi',
                        '${_summary!.totalTransactions}',
                        Icons.receipt_outlined,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Item Terjual',
                        '${_summary!.totalItemsSold}',
                        Icons.shopping_bag_outlined,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Tren Penjualan (Harian)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTrendChart(),
                const SizedBox(height: 24),
                const Text(
                  'Produk Terlaris (Best Seller)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_summary!.bestSellers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Belum ada transaksi di periode ini', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _summary!.bestSellers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = _summary!.bestSellers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: i < 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: i < 3 ? Colors.amber.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                          title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${item.totalQty} terjual'),
                          trailing: Text(
                            _currency.format(item.totalRevenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trend.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Belum ada data tren')),
      );
    }
    final maxRevenue = _trend.map((t) => t['revenue'] as num).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _trend.map((t) {
          final val = (t['revenue'] as num).toDouble();
          final barHeight = maxRevenue > 0 ? (val / maxRevenue) * 140 : 0.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ),
                Text(t['day'].toString().substring(8), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: color.shade900, fontWeight: FontWeight.w500)),
              Icon(icon, size: 20, color: color.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade900),
          ),
        ],
      ),
    );
  }
}
