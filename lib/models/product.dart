class ProductModel {
  final int? id;
  final String name;
  final String? barcode;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final String category;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    this.id,
    required this.name,
    this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.category,
    this.imagePath,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get margin => sellPrice - buyPrice;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'barcode': barcode,
    'buy_price': buyPrice,
    'sell_price': sellPrice,
    'stock': stock,
    'category': category,
    'image_path': imagePath,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
    id: map['id'] as int?,
    name: map['name'] as String,
    barcode: map['barcode'] as String?,
    buyPrice: (map['buy_price'] as num).toDouble(),
    sellPrice: (map['sell_price'] as num).toDouble(),
    stock: map['stock'] as int,
    category: map['category'] as String? ?? 'Umum',
    imagePath: map['image_path'] as String?,
    isActive: (map['is_active'] as int? ?? 1) == 1,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
  );

  ProductModel copyWith({
    int? id,
    String? name,
    String? barcode,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    String? category,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductModel(
    id: id ?? this.id,
    name: name ?? this.name,
    barcode: barcode ?? this.barcode,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    stock: stock ?? this.stock,
    category: category ?? this.category,
    imagePath: imagePath ?? this.imagePath,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
