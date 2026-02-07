import 'package:dental_clinic_app/database/database_helper.dart';
import 'package:dental_clinic_app/services/notification_service.dart';

class PaymentReminderManager {
  static final PaymentReminderManager _instance =
      PaymentReminderManager._internal();

  factory PaymentReminderManager() {
    return _instance;
  }

  PaymentReminderManager._internal();

  final NotificationService _notificationService = NotificationService();

  /// التحقق من المدفوعات المستحقة وإرسال تنبيهات
  Future<void> checkAndNotifyPendingPayments() async {
    try {
      final treatments = await DatabaseHelper.instance.getAllTreatments();
      final patients = await DatabaseHelper.instance.getAllPatients();

      // البحث عن العلاجات التي لم يتم الدفع الكامل لها
      for (final treatment in treatments) {
        final remainingAmount = treatment.cost - treatment.paidAmount;

        if (remainingAmount > 0) {
          final patientIndex =
              patients.indexWhere((p) => p.id == treatment.patientId);

          if (patientIndex != -1) {
            final patient = patients[patientIndex];
            await _notificationService.schedulePaymentReminder(
              patientName: patient.name,
              amount: remainingAmount,
            );
          }
        }
      }

      print('Payment reminders scheduled');
    } catch (e) {
      print('Error checking pending payments: $e');
    }
  }

  /// إرسال تنبيه عند إضافة علاج جديد
  Future<void> onTreatmentAdded(
    String patientName,
    double cost,
  ) async {
    await _notificationService.showNotification(
      title: 'علاج جديد مضاف',
      body:
          'تم إضافة علاج جديد للمريض $patientName بقيمة ${cost.toStringAsFixed(2)} ج.م',
      payload: 'new_treatment_$patientName',
    );
  }

  /// إرسال تنبيه عند استحقاق دفعة
  Future<void> onPaymentDue(
    String patientName,
    double amount,
    int daysUntilDue,
  ) async {
    if (daysUntilDue <= 0) {
      // الدفعة مستحقة الآن
      await _notificationService.showNotification(
        title: 'دفعة مستحقة فوراً',
        body:
            'المريض $patientName لديه دفعة مستحقة: ${amount.toStringAsFixed(2)} ج.م',
        payload: 'overdue_payment_$patientName',
      );
    } else if (daysUntilDue <= 3) {
      // الدفعة ستستحق قريباً
      final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
      await _notificationService.scheduleNotification(
        title: 'دفعة ستستحق قريباً',
        body:
            'المريض $patientName لديه دفعة ${amount.toStringAsFixed(2)} ج.م ستستحق خلال $daysUntilDue أيام',
        scheduledDate: dueDate,
        payload: 'upcoming_payment_$patientName',
      );
    }
  }

  /// إرسال تنبيه عند استقبال دفعة
  Future<void> onPaymentReceived(
    String patientName,
    double amount,
  ) async {
    await _notificationService.showNotification(
      title: 'دفعة مستلمة',
      body:
          'تم استقبال دفعة من $patientName بقيمة ${amount.toStringAsFixed(2)} ج.م',
      payload: 'payment_received_$patientName',
    );
  }

  /// إرسال تنبيه للمرضى الذين لم يدفعوا في الوقت المحدد
  Future<void> notifyOverduePayments() async {
    try {
      final treatments = await DatabaseHelper.instance.getAllTreatments();
      final patients = await DatabaseHelper.instance.getAllPatients();

      for (final treatment in treatments) {
        final remainingAmount = treatment.cost - treatment.paidAmount;

        // إذا كان هناك مبلغ معلق والتاريخ قد مضى
        if (remainingAmount > 0 && treatment.date.isBefore(DateTime.now())) {
          final patientIndex =
              patients.indexWhere((p) => p.id == treatment.patientId);

          if (patientIndex != -1) {
            final patient = patients[patientIndex];
            await _notificationService.showNotification(
              title: 'دفعة متأخرة - طلب عاجل',
              body:
                  'المريض ${patient.name} لديه دفعة متأخرة: ${remainingAmount.toStringAsFixed(2)} ج.م',
              payload: 'overdue_payment_${patient.name}',
            );
          }
        }
      }
    } catch (e) {
      print('Error notifying overdue payments: $e');
    }
  }
}
