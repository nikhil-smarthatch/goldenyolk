class FeedUsage {
  final int? id;
  final int flockId;
  final DateTime date;
  final double quantityKg;
  final String? notes;
  final DateTime createdAt;

  FeedUsage({
    this.id,
    required this.flockId,
    required this.date,
    required this.quantityKg,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'date': date.toIso8601String(),
      'quantity_kg': quantityKg,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedUsage.fromMap(Map<String, dynamic> map) {
    return FeedUsage(
      id: map['id'] as int?,
      flockId: map['flock_id'] as int,
      date: DateTime.parse(map['date'] as String),
      quantityKg: map['quantity_kg'] as double,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FeedUsage copyWith({
    int? id,
    int? flockId,
    DateTime? date,
    double? quantityKg,
    String? notes,
    DateTime? createdAt,
  }) {
    return FeedUsage(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      date: date ?? this.date,
      quantityKg: quantityKg ?? this.quantityKg,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
