class Patient {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final DateTime birthDate;
  final String gender;
  final String? medicalHistory;
  final String? allergies;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.birthDate,
    required this.gender,
    this.medicalHistory,
    this.allergies,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      birthDate: DateTime.parse(map['birthDate']),
      gender: map['gender'],
      medicalHistory: map['medicalHistory'],
      allergies: map['allergies'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? medicalHistory,
    String? allergies,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
