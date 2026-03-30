class ChickenSale {
  final int? id;
  final int? flockId;
  final DateTime date;
  final int quantity;
  final double pricePerBird;
  final String? buyer;
  final String? notes;
  final DateTime createdAt;

  ChickenSale({
    this.id,
    this.flockId,
    required this.date,
    required this.quantity,
    required this.pricePerBird,
    this.buyer,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'price_per_bird': pricePerBird,
      'buyer': buyer,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChickenSale.fromMap(Map<String, dynamic> map) {
    return ChickenSale(
      id: map['id'] as int?,
      flockId: map['flock_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      quantity: map['quantity'] as int,
      pricePerBird: map['price_per_bird'] as double,
      buyer: map['buyer'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get totalAmount => quantity * pricePerBird;

  ChickenSale copyWith({
    int? id,
    int? flockId,
    DateTime? date,
    int? quantity,
    double? pricePerBird,
    String? buyer,
    String? notes,
    DateTime? createdAt,
  }) {
    return ChickenSale(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      pricePerBird: pricePerBird ?? this.pricePerBird,
      buyer: buyer ?? this.buyer,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
