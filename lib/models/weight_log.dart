/// Model representing an individual weight measurement entry.
/// Matches PRD table: `weight_logs`.
class WeightLog {
  final String id;
  final double weightKg;
  final DateTime loggedDate;
  final String? notes;

  const WeightLog({
    required this.id,
    required this.weightKg,
    required this.loggedDate,
    this.notes,
  });

  WeightLog copyWith({
    String? id,
    double? weightKg,
    DateTime? loggedDate,
    String? notes,
  }) {
    return WeightLog(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      loggedDate: loggedDate ?? this.loggedDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight_kg': weightKg,
      'logged_date': loggedDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      loggedDate: DateTime.parse(map['logged_date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
