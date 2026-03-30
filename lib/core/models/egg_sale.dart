class EggSale {
  final int? id;
  final DateTime date;
  final int quantity;
  final double pricePerUnit;
  final String? buyer;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;

  EggSale({
    this.id,
    required this.date,
    required this.quantity,
    required this.pricePerUnit,
    this.buyer,
    this.paymentStatus = 'paid',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'buyer': buyer,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EggSale.fromMap(Map<String, dynamic> map) {
    return EggSale(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      quantity: map['quantity'] as int,
      pricePerUnit: map['price_per_unit'] as double,
      buyer: map['buyer'] as String?,
      paymentStatus: map['payment_status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get totalAmount => quantity * pricePerUnit;

  bool get isPaid => paymentStatus == 'paid';
  bool get isCredit => paymentStatus == 'credit';

  EggSale copyWith({
    int? id,
    DateTime? date,
    int? quantity,
    double? pricePerUnit,
    String? buyer,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return EggSale(
      id: id ?? this.id,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      buyer: buyer ?? this.buyer,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
