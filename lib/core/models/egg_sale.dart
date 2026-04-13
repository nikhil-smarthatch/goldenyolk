class EggSale {
  final int? id;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final int quantity;
  final double pricePerUnit;
  final String? buyer;
  final String status; // 'ordered', 'delivered', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final double amountPaid;
  final String paymentStatus; // 'unpaid', 'partial', 'paid'

  EggSale({
    this.id,
    required this.orderDate,
    this.deliveryDate,
    required this.quantity,
    required this.pricePerUnit,
    this.buyer,
    this.status = 'ordered',
    this.notes,
    DateTime? createdAt,
    this.amountPaid = 0.0,
    this.paymentStatus = 'unpaid',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'buyer': buyer,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'amount_paid': amountPaid,
      'payment_status': paymentStatus,
    };
  }

  factory EggSale.fromMap(Map<String, dynamic> map) {
    return EggSale(
      id: map['id'] as int?,
      orderDate: DateTime.parse(map['order_date'] as String),
      deliveryDate: map['delivery_date'] != null ? DateTime.parse(map['delivery_date'] as String) : null,
      quantity: map['quantity'] as int,
      pricePerUnit: map['price_per_unit'] as double,
      buyer: map['buyer'] as String?,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] as String? ?? 'unpaid',
    );
  }

  double get totalAmount => quantity * pricePerUnit;
  double get balanceDue => totalAmount - amountPaid;
  bool get isFullyPaid => paymentStatus == 'paid' || amountPaid >= totalAmount;
  bool get hasPartialPayment => paymentStatus == 'partial' || (amountPaid > 0 && amountPaid < totalAmount);

  bool get isDelivered => status == 'delivered';
  bool get isOrdered => status == 'ordered';
  bool get isCancelled => status == 'cancelled';

  EggSale copyWith({
    int? id,
    DateTime? orderDate,
    DateTime? deliveryDate,
    int? quantity,
    double? pricePerUnit,
    String? buyer,
    String? status,
    String? notes,
    DateTime? createdAt,
    double? amountPaid,
    String? paymentStatus,
  }) {
    return EggSale(
      id: id ?? this.id,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      buyer: buyer ?? this.buyer,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
