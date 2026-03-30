class MortalityLog {
  final int? id;
  final int flockId;
  final DateTime date;
  final int count;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  MortalityLog({
    this.id,
    required this.flockId,
    required this.date,
    required this.count,
    required this.reason,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'date': date.toIso8601String(),
      'count': count,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MortalityLog.fromMap(Map<String, dynamic> map) {
    return MortalityLog(
      id: map['id'] as int?,
      flockId: map['flock_id'] as int,
      date: DateTime.parse(map['date'] as String),
      count: map['count'] as int,
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MortalityLog copyWith({
    int? id,
    int? flockId,
    DateTime? date,
    int? count,
    String? reason,
    String? notes,
    DateTime? createdAt,
  }) {
    return MortalityLog(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      date: date ?? this.date,
      count: count ?? this.count,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
