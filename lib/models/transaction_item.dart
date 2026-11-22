class TransactionItemModel {
  final int? id;
  final int? transactionId;
  final int productId;
  final String productName;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final double subtotal;

  TransactionItemModel({
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    double? subtotal,
  }) : subtotal = subtotal ?? (sellPrice * quantity);

  double get profit => (sellPrice - buyPrice) * quantity;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    if (transactionId != null) 'transaction_id': transactionId,
    'product_id': productId,
    'product_name': productName,
    'buy_price': buyPrice,
    'sell_price': sellPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) =>
      TransactionItemModel(
        id: map['id'] as int?,
        transactionId: map['transaction_id'] as int?,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String,
        buyPrice: (map['buy_price'] as num).toDouble(),
        sellPrice: (map['sell_price'] as num).toDouble(),
        quantity: map['quantity'] as int,
        subtotal: (map['subtotal'] as num).toDouble(),
      );

  TransactionItemModel copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? buyPrice,
    double? sellPrice,
    int? quantity,
    double? subtotal,
  }) => TransactionItemModel(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    quantity: quantity ?? this.quantity,
    subtotal: subtotal ?? this.subtotal,
  );
}
