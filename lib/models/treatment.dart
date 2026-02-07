class Treatment {
  final String id;
  final String patientId;
  final String? appointmentId;
  final DateTime date;
  final String treatmentType; // حشو، تلبيس، خلع، تنظيف، etc
  final String toothNumber; // رقم السن (11-48)
  final String toothPosition; // الموضع: أمامي، خلفي، ضرس حكمة، etc
  final String description;
  final String? materials; // المواد المستخدمة
  final String? treatmentSteps; // خطوات العلاج
  final double cost;
  final double paidAmount;
  final String status; // جاري، مكتمل، معلق، فشل
  final String? complications; // المضاعفات إن وجدت
  final DateTime? followUpDate; // تاريخ المتابعة
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Treatment({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.date,
    required this.treatmentType,
    required this.toothNumber,
    this.toothPosition = '',
    required this.description,
    this.materials,
    this.treatmentSteps,
    required this.cost,
    this.paidAmount = 0,
    this.status = 'جاري',
    this.complications,
    this.followUpDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  double get remainingAmount => cost - paidAmount;
  bool get isFullyPaid => paidAmount >= cost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'date': date.toIso8601String(),
      'treatmentType': treatmentType,
      'toothNumber': toothNumber,
      'toothPosition': toothPosition,
      'description': description,
      'materials': materials,
      'treatmentSteps': treatmentSteps,
      'cost': cost,
      'paidAmount': paidAmount,
      'status': status,
      'complications': complications,
      'followUpDate': followUpDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Treatment.fromMap(Map<String, dynamic> map) {
    return Treatment(
      id: map['id'],
      patientId: map['patientId'],
      appointmentId: map['appointmentId'],
      date: DateTime.parse(map['date']),
      treatmentType: map['treatmentType'],
      toothNumber: map['toothNumber'],
      toothPosition: map['toothPosition'] ?? '',
      description: map['description'],
      materials: map['materials'],
      treatmentSteps: map['treatmentSteps'],
      cost: map['cost'],
      paidAmount: map['paidAmount'],
      status: map['status'],
      complications: map['complications'],
      followUpDate: map['followUpDate'] != null
          ? DateTime.parse(map['followUpDate'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Treatment copyWith({
    String? id,
    String? patientId,
    String? appointmentId,
    DateTime? date,
    String? treatmentType,
    String? toothNumber,
    String? toothPosition,
    String? description,
    String? materials,
    String? treatmentSteps,
    double? cost,
    double? paidAmount,
    String? status,
    String? complications,
    DateTime? followUpDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Treatment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      date: date ?? this.date,
      treatmentType: treatmentType ?? this.treatmentType,
      toothNumber: toothNumber ?? this.toothNumber,
      toothPosition: toothPosition ?? this.toothPosition,
      description: description ?? this.description,
      materials: materials ?? this.materials,
      treatmentSteps: treatmentSteps ?? this.treatmentSteps,
      cost: cost ?? this.cost,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      complications: complications ?? this.complications,
      followUpDate: followUpDate ?? this.followUpDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
