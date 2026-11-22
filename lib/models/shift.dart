class ShiftModel {
  final int? id;
  final int userId;
  final String userName;
  final DateTime startTime;
  final DateTime? endTime;
  final double startingCash;
  final double totalSales;
  final String status;

  ShiftModel({
    this.id,
    required this.userId,
    required this.userName,
    DateTime? startTime,
    this.endTime,
    this.startingCash = 0.0,
    this.totalSales = 0.0,
    this.status = 'open',
  }) : startTime = startTime ?? DateTime.now();

  bool get isOpen => status == 'open';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'user_name': userName,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'starting_cash': startingCash,
    'total_sales': totalSales,
    'status': status,
  };

  factory ShiftModel.fromMap(Map<String, dynamic> map) => ShiftModel(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    userName: map['user_name'] as String,
    startTime: DateTime.tryParse(map['start_time'] as String? ?? '') ?? DateTime.now(),
    endTime: map['end_time'] != null ? DateTime.tryParse(map['end_time'] as String) : null,
    startingCash: (map['starting_cash'] as num? ?? 0.0).toDouble(),
    totalSales: (map['total_sales'] as num? ?? 0.0).toDouble(),
    status: map['status'] as String? ?? 'open',
  );

  ShiftModel copyWith({
    int? id,
    int? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    double? startingCash,
    double? totalSales,
    String? status,
  }) => ShiftModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    startingCash: startingCash ?? this.startingCash,
    totalSales: totalSales ?? this.totalSales,
    status: status ?? this.status,
  );
}
