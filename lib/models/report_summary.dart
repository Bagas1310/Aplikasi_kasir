class BestSellerModel {
  final int productId;
  final String productName;
  final int totalQty;
  final double totalRevenue;

  BestSellerModel({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory BestSellerModel.fromMap(Map<String, dynamic> map) => BestSellerModel(
    productId: map['product_id'] as int,
    productName: map['product_name'] as String,
    totalQty: (map['total_qty'] as num).toInt(),
    totalRevenue: (map['total_revenue'] as num).toDouble(),
  );
}

class SalesSummaryModel {
  final double totalRevenue;
  final double totalProfit;
  final int totalTransactions;
  final int totalItemsSold;
  final List<BestSellerModel> bestSellers;

  SalesSummaryModel({
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.bestSellers,
  });

  factory SalesSummaryModel.empty() => SalesSummaryModel(
    totalRevenue: 0,
    totalProfit: 0,
    totalTransactions: 0,
    totalItemsSold: 0,
    bestSellers: const [],
  );
}
