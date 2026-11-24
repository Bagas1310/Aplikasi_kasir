import 'transaction_item.dart';

class TransactionModel {
  final int? id;
  final String invoiceNumber;
  final int userId;
  final String userName;
  final int? shiftId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double paidAmount;
  final double changeAmount;
  final int? tableNumber;
  final String? paymentProof;
  final DateTime createdAt;
  final List<TransactionItemModel> items;

  TransactionModel({
    this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.userName,
    this.shiftId,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    this.tableNumber,
    this.paymentProof,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoice_number': invoiceNumber,
    'user_id': userId,
    'user_name': userName,
    'shift_id': shiftId,
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'total': total,
    'payment_method': paymentMethod,
    'paid_amount': paidAmount,
    'change_amount': changeAmount,
    'table_number': tableNumber,
    if (paymentProof != null) 'payment_proof': paymentProof,
    'created_at': createdAt.toIso8601String(),
  };

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    List<TransactionItemModel> items = const [],
  }) => TransactionModel(
    id: map['id'] as int?,
    invoiceNumber: map['invoice_number'] as String,
    userId: map['user_id'] as int,
    userName: map['user_name'] as String,
    shiftId: map['shift_id'] as int?,
    subtotal: (map['subtotal'] as num).toDouble(),
    discount: (map['discount'] as num? ?? 0.0).toDouble(),
    tax: (map['tax'] as num? ?? 0.0).toDouble(),
    total: (map['total'] as num).toDouble(),
    paymentMethod: map['payment_method'] as String,
    paidAmount: (map['paid_amount'] as num).toDouble(),
    changeAmount: (map['change_amount'] as num).toDouble(),
    tableNumber: map['table_number'] as int?,
    paymentProof: map['payment_proof'] as String?,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    items: items,
  );

  TransactionModel copyWith({
    int? id,
    String? invoiceNumber,
    int? userId,
    String? userName,
    int? shiftId,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    double? paidAmount,
    double? changeAmount,
    int? tableNumber,
    String? paymentProof,
    DateTime? createdAt,
    List<TransactionItemModel>? items,
  }) => TransactionModel(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    shiftId: shiftId ?? this.shiftId,
    subtotal: subtotal ?? this.subtotal,
    discount: discount ?? this.discount,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paidAmount: paidAmount ?? this.paidAmount,
    changeAmount: changeAmount ?? this.changeAmount,
    tableNumber: tableNumber ?? this.tableNumber,
    paymentProof: paymentProof ?? this.paymentProof,
    createdAt: createdAt ?? this.createdAt,
    items: items ?? this.items,
  );
}
