class Flock {
  final int? id;
  final String name;
  final String breed;
  final int initialCount;
  final DateTime dateAcquired;
  final String purpose;
  final String? notes;
  final DateTime createdAt;

  Flock({
    this.id,
    required this.name,
    required this.breed,
    required this.initialCount,
    required this.dateAcquired,
    required this.purpose,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'initial_count': initialCount,
      'date_acquired': dateAcquired.toIso8601String(),
      'purpose': purpose,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Flock.fromMap(Map<String, dynamic> map) {
    return Flock(
      id: map['id'] as int?,
      name: map['name'] as String,
      breed: map['breed'] as String,
      initialCount: map['initial_count'] as int,
      dateAcquired: DateTime.parse(map['date_acquired'] as String),
      purpose: map['purpose'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Flock copyWith({
    int? id,
    String? name,
    String? breed,
    int? initialCount,
    DateTime? dateAcquired,
    String? purpose,
    String? notes,
    DateTime? createdAt,
  }) {
    return Flock(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      initialCount: initialCount ?? this.initialCount,
      dateAcquired: dateAcquired ?? this.dateAcquired,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
