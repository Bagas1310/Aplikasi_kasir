import 'package:flutter/material.dart';
import '../../services/database/database_helper.dart';

class TableSelectionScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int? shiftId;
  final int? selectedTable;
  final ValueChanged<int> onTableSelected;

  const TableSelectionScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.shiftId,
    this.selectedTable,
    required this.onTableSelected,
  });

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final tables = await _db.getTables();
    setState(() {
      _tables = tables;
      _isLoading = false;
    });
  }

  Future<void> _confirmFreeTable(int number) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kosongkan Meja ${number.toString().padLeft(2, '0')}?'),
        content: const Text('Status meja akan diubah menjadi Tersedia (Kosong).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.freeTable(number);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableColor = Colors.green.shade600;
    final occupiedColor = Colors.red.shade600;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _Legend(color: availableColor, label: 'Kosong'),
                    const SizedBox(width: 16),
                    _Legend(color: occupiedColor, label: 'Terisi'),
                  ],
                ),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Segarkan', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (_, i) {
                    final t = _tables[i];
                    final number = t['number'] as int;
                    final isAvailable = t['status'] == 'available';

                    return _TableCard(
                      number: number,
                      isAvailable: isAvailable,
                      selected: widget.selectedTable == number,
                      onTap: isAvailable
                          ? () {
                               
                              widget.onTableSelected(number);
                            }
                          : () => _confirmFreeTable(number),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final int number;
  final bool isAvailable;
  final bool selected;
  final VoidCallback onTap;

  const _TableCard({
    required this.number,
    required this.isAvailable,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade600;
    final availableColor = Colors.green.shade600;
    final occupiedColor = Colors.red.shade400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStatePropertyAll(
          (isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.12),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: isAvailable
                ? (selected ? Colors.green.shade600 : Colors.green.shade50)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? (selected ? Colors.green.shade800 : Colors.green.shade400)
                  : occupiedColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isAvailable ? primaryColor : occupiedColor).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAvailable ? Icons.table_restaurant : Icons.person,
                color: isAvailable
                    ? (selected ? Colors.white : availableColor)
                    : occupiedColor,
                size: 32,
              ),
              const SizedBox(height: 6),
              Text(
                'Meja ${number.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isAvailable
                      ? (selected ? Colors.white : Colors.black87)
                      : Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAvailable ? (selected ? 'Pilih' : 'Kosong') : 'Terisi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isAvailable
                      ? (selected ? Colors.white : availableColor)
                      : occupiedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
