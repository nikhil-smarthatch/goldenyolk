class PaymentHistory {
  final int? id;
  final int saleId;
  final double amountPaid;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  PaymentHistory({
    this.id,
    required this.saleId,
    required this.amountPaid,
    required this.paymentDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      amountPaid: map['amount_paid'] as double,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PaymentHistory copyWith({
    int? id,
    int? saleId,
    double? amountPaid,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return PaymentHistory(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
