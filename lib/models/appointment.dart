class Appointment {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final int duration; // بالدقائق
  final String type; // كشف، متابعة، علاج، جراحة، إلخ
  final String status; // محجوز، مكتمل، ملغي، لم يحضر
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    this.duration = 30,
    required this.type,
    this.status = 'محجوز',
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'type': type,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'],
      dateTime: DateTime.parse(map['dateTime']),
      duration: map['duration'],
      type: map['type'],
      status: map['status'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    DateTime? dateTime,
    int? duration,
    String? type,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
