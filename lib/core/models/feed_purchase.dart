class FeedPurchase {
  final int? id;
  final DateTime date;
  final String feedType;
  final double quantityKg;
  final double pricePerUnit;
  final String? supplier;
  final String? notes;
  final DateTime createdAt;

  FeedPurchase({
    this.id,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    required this.pricePerUnit,
    this.supplier,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'feed_type': feedType,
      'quantity_kg': quantityKg,
      'price_per_unit': pricePerUnit,
      'supplier': supplier,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedPurchase.fromMap(Map<String, dynamic> map) {
    return FeedPurchase(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      feedType: map['feed_type'] as String,
      quantityKg: map['quantity_kg'] as double,
      pricePerUnit: map['price_per_unit'] as double,
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get totalCost => quantityKg * pricePerUnit;

  FeedPurchase copyWith({
    int? id,
    DateTime? date,
    String? feedType,
    double? quantityKg,
    double? pricePerUnit,
    String? supplier,
    String? notes,
    DateTime? createdAt,
  }) {
    return FeedPurchase(
      id: id ?? this.id,
      date: date ?? this.date,
      feedType: feedType ?? this.feedType,
      quantityKg: quantityKg ?? this.quantityKg,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
