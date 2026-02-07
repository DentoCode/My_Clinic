class Procedure {
  final String id;
  final String treatmentId;
  final String name; // اسم الإجراء
  final String description; // وصف الإجراء
  final DateTime startDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final int order; // ترتيب الإجراء
  final String? notes;
  final DateTime createdAt;

  Procedure({
    required this.id,
    required this.treatmentId,
    required this.name,
    required this.description,
    required this.startDate,
    this.completedDate,
    this.isCompleted = false,
    required this.order,
    this.notes,
    required this.createdAt,
  });

  double get progressPercentage {
    // سيتم حسابها على مستوى Treatment
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'treatmentId': treatmentId,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'order': order,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Procedure.fromMap(Map<String, dynamic> map) {
    return Procedure(
      id: map['id'],
      treatmentId: map['treatmentId'],
      name: map['name'],
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'])
          : null,
      isCompleted: map['isCompleted'] == 1,
      order: map['order'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Procedure copyWith({
    String? id,
    String? treatmentId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? completedDate,
    bool? isCompleted,
    int? order,
    String? notes,
    DateTime? createdAt,
  }) {
    return Procedure(
      id: id ?? this.id,
      treatmentId: treatmentId ?? this.treatmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
