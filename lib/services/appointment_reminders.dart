import 'package:dental_clinic_app/database/database_helper.dart';
import 'package:dental_clinic_app/models/appointment.dart';
import 'package:dental_clinic_app/services/notification_service.dart';

class AppointmentReminderManager {
  static final AppointmentReminderManager _instance =
      AppointmentReminderManager._internal();

  factory AppointmentReminderManager() {
    return _instance;
  }

  AppointmentReminderManager._internal();

  final NotificationService _notificationService = NotificationService();

  /// تحضير تذكيرات المواعيد لجميع المواعيد القادمة
  Future<void> scheduleAllAppointmentReminders() async {
    try {
      final appointments = await DatabaseHelper.instance.getAllAppointments();

      // فلترة المواعيد المستقبلية فقط
      final futureAppointments = appointments.where((apt) {
        return apt.dateTime.isAfter(DateTime.now());
      }).toList();

      print(
          'Scheduling reminders for ${futureAppointments.length} appointments');

      for (final appointment in futureAppointments) {
        await _scheduleAppointmentReminder(appointment);
      }
    } catch (e) {
      print('Error scheduling appointment reminders: $e');
    }
  }

  /// جدولة تذكير لموعد واحد
  Future<void> _scheduleAppointmentReminder(Appointment appointment) async {
    try {
      // الحصول على بيانات المريض
      final patients = await DatabaseHelper.instance.getAllPatients();
      final patientIndex =
          patients.indexWhere((p) => p.id == appointment.patientId);

      if (patientIndex == -1) {
        print('Patient not found for appointment');
        return;
      }

      final patient = patients[patientIndex];

      // جدولة التذكيرات
      await _notificationService.scheduleAppointmentReminder(
        patientName: patient.name,
        appointmentTime: appointment.dateTime,
      );
    } catch (e) {
      print('Error scheduling reminder for appointment: $e');
    }
  }

  /// عند إضافة موعد جديد
  Future<void> onAppointmentAdded(Appointment appointment) async {
    await _scheduleAppointmentReminder(appointment);
  }

  /// عند حذف موعد
  Future<void> onAppointmentDeleted(Appointment appointment) async {
    try {
      await _notificationService.cancelNotification(appointment.id.hashCode);
      print('Appointment reminder cancelled');
    } catch (e) {
      print('Error cancelling appointment reminder: $e');
    }
  }

  /// التحقق من المواعيد وإرسال تنبيهات للمتأخرة
  Future<void> checkAndNotifyUpcomingAppointments() async {
    try {
      final appointments = await DatabaseHelper.instance.getAllAppointments();
      final patients = await DatabaseHelper.instance.getAllPatients();
      final now = DateTime.now();

      for (final appointment in appointments) {
        // إذا كان الموعد بعد الآن بأقل من ساعة
        if (appointment.dateTime.isAfter(now) &&
            appointment.dateTime.isBefore(now.add(const Duration(hours: 1)))) {
          final patientIndex =
              patients.indexWhere((p) => p.id == appointment.patientId);

          if (patientIndex != -1) {
            final patient = patients[patientIndex];
            await _notificationService.showNotification(
              title: 'موعد قريب جداً',
              body: 'موعد ${patient.name} سيبدأ بعد دقائق قليلة',
              payload: 'upcoming_appointment_${appointment.id}',
            );
          }
        }
      }
    } catch (e) {
      print('Error checking upcoming appointments: $e');
    }
  }
}
