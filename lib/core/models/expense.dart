class Expense {
  final int? id;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final String? notes;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'amount': amount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Expense copyWith({
    int? id,
    DateTime? date,
    String? category,
    String? description,
    double? amount,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
