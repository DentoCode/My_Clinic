import 'package:hive/hive.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/treatment.dart';
import '../models/payment.dart';
import '../models/procedure.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Box names
  static const String patientBoxName = 'patients';
  static const String appointmentBoxName = 'appointments';
  static const String treatmentBoxName = 'treatments';
  static const String paymentBoxName = 'payments';
  static const String procedureBoxName = 'procedures';
  static const String userBoxName = 'users';

  // Boxes
  late Box _patientBox;
  late Box _appointmentBox;
  late Box _treatmentBox;
  late Box _paymentBox;
  late Box _procedureBox;
  late Box _userBox;

  DatabaseHelper._init();

  Future<void> init() async {
    try {
      print('Initializing DatabaseHelper...');

      _patientBox = await Hive.openBox(patientBoxName);
      print('Opened patientBox');

      _appointmentBox = await Hive.openBox(appointmentBoxName);
      print('Opened appointmentBox');

      _treatmentBox = await Hive.openBox(treatmentBoxName);
      print('Opened treatmentBox');

      _paymentBox = await Hive.openBox(paymentBoxName);
      print('Opened paymentBox');

      _procedureBox = await Hive.openBox(procedureBoxName);
      print('Opened procedureBox');

      _userBox = await Hive.openBox(userBoxName);
      print('Opened userBox');

      // Initialize with default admin user if empty
      await _initializeDefaultUser();
      print('DatabaseHelper initialized successfully');
    } catch (e) {
      print('Error initializing DatabaseHelper: $e');
      rethrow;
    }
  }

  Future<void> _initializeDefaultUser() async {
    try {
      // Check if admin user already exists
      final adminExists = _userBox.containsKey('admin');
      if (!adminExists) {
        await _userBox.put('admin', {
          'id': 'default-admin',
          'username': 'admin',
          'password': 'admin123', // يجب تشفيرها في الإنتاج
          'name': 'المدير',
          'role': 'admin',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error initializing default user: $e');
    }
  }

  // ==================== Patients ====================

  Future<String> insertPatient(Patient patient) async {
    try {
      await _patientBox.put(patient.id, patient.toMap());
      return patient.id;
    } catch (e) {
      print('Error inserting patient: $e');
      rethrow;
    }
  }

  Future<List<Patient>> getAllPatients() async {
    try {
      final patients = _patientBox.values
          .map((data) => Patient.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      patients.sort((a, b) => a.name.compareTo(b.name));
      return patients;
    } catch (e) {
      print('Error getting all patients: $e');
      return [];
    }
  }

  Future<Patient?> getPatient(String id) async {
    try {
      final data = _patientBox.get(id);
      if (data != null) {
        return Patient.fromMap(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      await _patientBox.put(patient.id, patient.toMap());
    } catch (e) {
      print('Error updating patient: $e');
      rethrow;
    }
  }

  Future<void> deletePatient(String id) async {
    await _patientBox.delete(id);
  }

  Future<void> deletePatientWithAllData(String patientId) async {
    try {
      // حذف جميع العلاجات الخاصة بالمريض
      final treatments = _treatmentBox.values
          .where((data) => (data['patientId'] ?? '') == patientId)
          .toList();
      for (var treatment in treatments) {
        final id = treatment['id'];
        if (id != null) {
          await _treatmentBox.delete(id);
        }
      }

      // حذف جميع المواعيد الخاصة بالمريض
      final appointments = _appointmentBox.values
          .where((data) => (data['patientId'] ?? '') == patientId)
          .toList();
      for (var appointment in appointments) {
        final id = appointment['id'];
        if (id != null) {
          await _appointmentBox.delete(id);
        }
      }

      // حذف جميع المدفوعات الخاصة بالمريض
      final payments = _paymentBox.values
          .where((data) => (data['patientId'] ?? '') == patientId)
          .toList();
      for (var payment in payments) {
        final id = payment['id'];
        if (id != null) {
          await _paymentBox.delete(id);
        }
      }

      // حذف ملف المريض نفسه
      await _patientBox.delete(patientId);

      print('تم حذف المريض وجميع بياناته بنجاح');
    } catch (e) {
      print('Error deleting patient with all data: $e');
      rethrow;
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    try {
      final patients = _patientBox.values
          .map((data) => Patient.fromMap(Map<String, dynamic>.from(data)))
          .where((patient) {
        return patient.name.toLowerCase().contains(query.toLowerCase()) ||
            patient.phone.contains(query);
      }).toList();
      patients.sort((a, b) => a.name.compareTo(b.name));
      return patients;
    } catch (e) {
      print('Error searching patients: $e');
      return [];
    }
  }

  // ==================== Appointments ====================

  Future<String> insertAppointment(Appointment appointment) async {
    try {
      await _appointmentBox.put(appointment.id, appointment.toMap());
      return appointment.id;
    } catch (e) {
      print('Error inserting appointment: $e');
      rethrow;
    }
  }

  Future<List<Appointment>> getAllAppointments() async {
    try {
      final appointments = _appointmentBox.values
          .map((data) => Appointment.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    } catch (e) {
      print('Error getting all appointments: $e');
      return [];
    }
  }

  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final appointments = _appointmentBox.values
          .map((data) => Appointment.fromMap(Map<String, dynamic>.from(data)))
          .where((appointment) {
        return appointment.dateTime.isAfter(startOfDay) &&
            appointment.dateTime.isBefore(endOfDay);
      }).toList();

      appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return appointments;
    } catch (e) {
      print('Error getting appointments by date: $e');
      return [];
    }
  }

  Future<List<Appointment>> getPatientAppointments(String patientId) async {
    try {
      final appointments = _appointmentBox.values
          .map((data) => Appointment.fromMap(Map<String, dynamic>.from(data)))
          .where((appointment) => appointment.patientId == patientId)
          .toList();
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    } catch (e) {
      print('Error getting patient appointments: $e');
      return [];
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _appointmentBox.put(appointment.id, appointment.toMap());
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    await _appointmentBox.delete(id);
  }

  // ==================== Treatments ====================

  Future<String> insertTreatment(Treatment treatment) async {
    try {
      await _treatmentBox.put(treatment.id, treatment.toMap());
      return treatment.id;
    } catch (e) {
      print('Error inserting treatment: $e');
      rethrow;
    }
  }

  Future<List<Treatment>> getAllTreatments() async {
    try {
      final treatments = _treatmentBox.values
          .map((data) => Treatment.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      treatments.sort((a, b) => b.date.compareTo(a.date));
      return treatments;
    } catch (e) {
      print('Error getting all treatments: $e');
      return [];
    }
  }

  Future<List<Treatment>> getPatientTreatments(String patientId) async {
    try {
      final treatments = _treatmentBox.values
          .map((data) => Treatment.fromMap(Map<String, dynamic>.from(data)))
          .where((treatment) => treatment.patientId == patientId)
          .toList();
      treatments.sort((a, b) => b.date.compareTo(a.date));
      return treatments;
    } catch (e) {
      print('Error getting patient treatments: $e');
      return [];
    }
  }

  Future<void> updateTreatment(Treatment treatment) async {
    try {
      await _treatmentBox.put(treatment.id, treatment.toMap());
    } catch (e) {
      print('Error updating treatment: $e');
      rethrow;
    }
  }

  Future<void> deleteTreatment(String id) async {
    await _treatmentBox.delete(id);
  }

  // ==================== Payments ====================

  Future<String> insertPayment(Payment payment) async {
    try {
      await _paymentBox.put(payment.id, payment.toMap());
      return payment.id;
    } catch (e) {
      print('Error inserting payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final payments = _paymentBox.values
          .map((data) => Payment.fromMap(Map<String, dynamic>.from(data)))
          .toList();
      payments.sort((a, b) => b.date.compareTo(a.date));
      return payments;
    } catch (e) {
      print('Error getting all payments: $e');
      return [];
    }
  }

  Future<List<Payment>> getPatientPayments(String patientId) async {
    try {
      final payments = _paymentBox.values
          .map((data) => Payment.fromMap(Map<String, dynamic>.from(data)))
          .where((payment) => payment.patientId == patientId)
          .toList();
      payments.sort((a, b) => b.date.compareTo(a.date));
      return payments;
    } catch (e) {
      print('Error getting patient payments: $e');
      return [];
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      await _paymentBox.put(payment.id, payment.toMap());
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  Future<void> deletePayment(String id) async {
    await _paymentBox.delete(id);
  }

  // ==================== Statistics ====================

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // عدد المرضى
      final patientsCount = _patientBox.length;

      // عدد المواعيد اليوم
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayAppointments = _appointmentBox.values
          .map((data) => Appointment.fromMap(Map<String, dynamic>.from(data)))
          .where((appointment) =>
              appointment.dateTime.isAfter(startOfDay) &&
              appointment.dateTime.isBefore(endOfDay))
          .length;

      // إجمالي الإيرادات
      final totalRevenue = _paymentBox.values
          .map((data) => Payment.fromMap(Map<String, dynamic>.from(data)))
          .fold<double>(0, (sum, payment) => sum + payment.amount);

      // المبالغ المستحقة
      final pendingPayments = _treatmentBox.values
          .map((data) => Treatment.fromMap(Map<String, dynamic>.from(data)))
          .fold<double>(
              0,
              (sum, treatment) =>
                  sum + (treatment.cost - treatment.paidAmount));

      return {
        'patientsCount': patientsCount,
        'todayAppointments': todayAppointments,
        'totalRevenue': totalRevenue,
        'pendingPayments': pendingPayments,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'patientsCount': 0,
        'todayAppointments': 0,
        'totalRevenue': 0.0,
        'pendingPayments': 0.0,
      };
    }
  }

  // ==================== Authentication ====================

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // Search for user by username in the box
      for (int i = 0; i < _userBox.length; i++) {
        final userEntry = _userBox.getAt(i);
        if (userEntry is Map) {
          final user = Map<String, dynamic>.from(userEntry);
          if (user['username'] == username && user['password'] == password) {
            return user;
          }
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // ===== Procedure Methods =====
  Future<void> insertProcedure(Procedure procedure) async {
    try {
      if (!_procedureBox.isOpen) {
        print('Warning: procedureBox is not open, opening it now');
        // Try to reopen
        await Hive.openBox(procedureBoxName);
      }
      final map = procedure.toMap();
      print('Inserting procedure with toMap: $map');
      await _procedureBox.put(procedure.id, map);
      print('Procedure inserted: ${procedure.id}');
    } catch (e) {
      print('Error inserting procedure: $e');
      rethrow;
    }
  }

  Future<void> updateProcedure(Procedure procedure) async {
    try {
      if (!_procedureBox.isOpen) {
        print('Warning: procedureBox is not open, opening it now');
        await Hive.openBox(procedureBoxName);
      }
      final map = procedure.toMap();
      await _procedureBox.put(procedure.id, map);
    } catch (e) {
      print('Error updating procedure: $e');
      rethrow;
    }
  }

  Future<void> deleteProcedure(String procedureId) async {
    try {
      if (!_procedureBox.isOpen) {
        await Hive.openBox(procedureBoxName);
      }
      await _procedureBox.delete(procedureId);
    } catch (e) {
      print('Error deleting procedure: $e');
      rethrow;
    }
  }

  Future<List<Procedure>> getTreatmentProcedures(String treatmentId) async {
    try {
      if (!_procedureBox.isOpen) {
        await Hive.openBox(procedureBoxName);
      }
      final procedures = <Procedure>[];
      for (var value in _procedureBox.values) {
        if (value is Map) {
          final procedure = Procedure.fromMap(
            Map<String, dynamic>.from(value),
          );
          if (procedure.treatmentId == treatmentId) {
            procedures.add(procedure);
          }
        }
      }
      procedures.sort((a, b) => a.order.compareTo(b.order));
      return procedures;
    } catch (e) {
      print('Error getting treatment procedures: $e');
      return [];
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
