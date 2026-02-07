class Payment {
  final String id;
  final String patientId;
  final String? treatmentId;
  final double amount;
  final DateTime date;
  final String paymentMethod; // نقدي، بطاقة ائتمان، تحويل بنكي، شيك، إلخ
  final String? cardType; // مثلاً: Visa, MasterCard, Amex
  final String? checkNumber; // رقم الشيك إن وجد
  final String? transferReference; // مرجع التحويل البنكي
  final String paymentStatus; // مكتمل، معلق، ملغى
  final String? receiptNumber; // رقم الإيصال
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.patientId,
    this.treatmentId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.cardType,
    this.checkNumber,
    this.transferReference,
    this.paymentStatus = 'مكتمل',
    this.receiptNumber,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'treatmentId': treatmentId,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'cardType': cardType,
      'checkNumber': checkNumber,
      'transferReference': transferReference,
      'paymentStatus': paymentStatus,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      patientId: map['patientId'],
      treatmentId: map['treatmentId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      paymentMethod: map['paymentMethod'],
      cardType: map['cardType'],
      checkNumber: map['checkNumber'],
      transferReference: map['transferReference'],
      paymentStatus: map['paymentStatus'] ?? 'مكتمل',
      receiptNumber: map['receiptNumber'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Payment copyWith({
    String? id,
    String? patientId,
    String? treatmentId,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? cardType,
    String? checkNumber,
    String? transferReference,
    String? paymentStatus,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      treatmentId: treatmentId ?? this.treatmentId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardType: cardType ?? this.cardType,
      checkNumber: checkNumber ?? this.checkNumber,
      transferReference: transferReference ?? this.transferReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
