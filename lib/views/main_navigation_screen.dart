import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'tables/table_selection_screen.dart';
import 'pos/pos_screen.dart';
import 'products/product_list_screen.dart';
import 'invoices/invoice_history_screen.dart';
import 'reports/report_screen.dart';
import 'shift/shift_dialog.dart';
import 'staff/staff_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int? _tableNumber;
  int _tableRefresh = 0;
  int _invoiceRefresh = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final shift = auth.currentShift;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOwner = user.isOwner;

    final List<Widget> pages = isOwner
        ? [
            ProductListScreen(isOwner: isOwner),
            InvoiceHistoryScreen(refreshKey: _invoiceRefresh),
            ReportScreen(isOwner: isOwner),
          ]
        : [
            TableSelectionScreen(
              key: ValueKey(_tableRefresh),
              userId: user.id!,
              userName: user.name,
              shiftId: shift?.id,
              onTableSelected: (number) => setState(() => _tableNumber = number),
            ),
            PosScreen(
              userId: user.id!,
              userName: user.name,
              shiftId: shift?.id,
              tableNumber: _tableNumber,
              onTransactionCompleted: () => setState(() {
                _tableNumber = null;
                _tableRefresh++;
                 _invoiceRefresh++;
                _currentIndex = 2;
              }),
            ),
            InvoiceHistoryScreen(refreshKey: _invoiceRefresh),
          ];

    final List<String> titles = isOwner
        ? ['Katalog Produk', 'Riwayat Invoice', 'Laporan Penjualan']
        : ['Pilih Meja', 'Transaksi', 'Riwayat Invoice'];

    final List<NavigationDestination> destinations = isOwner
        ? const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Invoice',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label: 'Pilih Meja',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Transaksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Invoice',
            ),
          ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOwner ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${user.name} (${user.role.toUpperCase()})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: () => ShiftDialog.show(context),
            icon: const Icon(Icons.sync_alt, size: 16),
            label: const Text('Ganti Shift', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'staff') {
                StaffDialog.show(context);
              } else if (val == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (ctx) => [
              if (isOwner)
                const PopupMenuItem(
                  value: 'staff',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 20),
                      SizedBox(width: 10),
                      Text('Kelola Staff'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Keluar Akun', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() {
          _currentIndex = idx;
          if (idx == 0) _tableRefresh++;
        }),
        destinations: destinations,
      ),
    );
  }
}
