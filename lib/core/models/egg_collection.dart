class EggCollection {
  final int? id;
  final int flockId;
  final DateTime date;
  final int collected;
  final int broken;
  final String? notes;
  final DateTime createdAt;

  EggCollection({
    this.id,
    required this.flockId,
    required this.date,
    required this.collected,
    this.broken = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'date': date.toIso8601String(),
      'collected': collected,
      'broken': broken,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EggCollection.fromMap(Map<String, dynamic> map) {
    return EggCollection(
      id: map['id'] as int?,
      flockId: map['flock_id'] as int,
      date: DateTime.parse(map['date'] as String),
      collected: map['collected'] as int,
      broken: map['broken'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  int get goodEggs => collected - broken;

  EggCollection copyWith({
    int? id,
    int? flockId,
    DateTime? date,
    int? collected,
    int? broken,
    String? notes,
    DateTime? createdAt,
  }) {
    return EggCollection(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      date: date ?? this.date,
      collected: collected ?? this.collected,
      broken: broken ?? this.broken,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
