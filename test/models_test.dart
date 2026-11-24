import 'package:flutter_test/flutter_test.dart';
import 'package:mykasir/models/user.dart';
import 'package:mykasir/models/product.dart';
import 'package:mykasir/models/transaction.dart';
import 'package:mykasir/models/transaction_item.dart';
import 'package:mykasir/models/shift.dart';

void main() {
  test('UserModel toMap and fromMap', () {
    final user = UserModel(
      id: 1,
      name: 'Owner Toko',
      username: 'owner',
      password: 'password123',
      role: 'owner',
    );
    final map = user.toMap();
    final from = UserModel.fromMap(map);

    expect(from.id, 1);
    expect(from.name, 'Owner Toko');
    expect(from.username, 'owner');
    expect(from.isOwner, true);
  });

  test('ProductModel toMap, fromMap and margin', () {
    final product = ProductModel(
      id: 10,
      name: 'Kopi Susu',
      barcode: '1234567890',
      buyPrice: 8000,
      sellPrice: 15000,
      stock: 50,
      category: 'Minuman',
    );
    expect(product.margin, 7000);

    final map = product.toMap();
    final from = ProductModel.fromMap(map);
    expect(from.id, 10);
    expect(from.name, 'Kopi Susu');
    expect(from.buyPrice, 8000);
    expect(from.sellPrice, 15000);
    expect(from.margin, 7000);
  });

  test('TransactionItemModel profit calculation', () {
    final item = TransactionItemModel(
      productId: 1,
      productName: 'Kopi Susu',
      buyPrice: 8000,
      sellPrice: 15000,
      quantity: 3,
    );
    expect(item.subtotal, 45000);
    expect(item.profit, 21000);
  });

  test('ShiftModel status check', () {
    final shift = ShiftModel(
      userId: 1,
      userName: 'Kasir 1',
      startingCash: 100000,
    );
    expect(shift.isOpen, true);
  });

  test('TransactionModel toMap and fromMap', () {
    final txn = TransactionModel(
      id: 1,
      invoiceNumber: 'INV-20261120-001',
      userId: 1,
      userName: 'Kasir 1',
      subtotal: 45000,
      total: 45000,
      paymentMethod: 'tunai',
      paidAmount: 50000,
      changeAmount: 5000,
      tableNumber: 5,
      paymentProof: '/path/to/proof.jpg',
    );
    final map = txn.toMap();
    final from = TransactionModel.fromMap(map);
    expect(from.invoiceNumber, 'INV-20261120-001');
    expect(from.total, 45000);
    expect(from.tableNumber, 5);
    expect(from.paymentProof, '/path/to/proof.jpg');
  });
}
