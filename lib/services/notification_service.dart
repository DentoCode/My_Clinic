import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      // تهيئة البيانات الزمنية
      tz.initializeTimeZones();

      // إعدادات Android
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // إعدادات عامة
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // تهيئة المكتبة
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification clicked: ${response.payload}');
          // معالجة النقر على الإشعار
          _handleNotificationTap(response.payload);
        },
      );

      print('Notifications initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // إرسال إشعار بسيط فوري
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dental_clinic_channel',
        'Dental Clinic Notifications',
        channelDescription: 'Notifications for dental clinic appointments',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );

      print('Notification shown: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // إرسال إشعار مجدول (في وقت معين)
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dental_clinic_channel',
        'Dental Clinic Notifications',
        channelDescription: 'Notifications for dental clinic appointments',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // تحويل التاريخ إلى timezone محلي
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: scheduledDate.millisecondsSinceEpoch.toInt() % 2147483647,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      print('Scheduled notification: $title at ${scheduledDate.toString()}');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // إلغاء إشعار مجدول
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: id);
      print('Notification cancelled: $id');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  // تذكير الموعد قبل 24 ساعة
  Future<void> scheduleAppointmentReminder({
    required String patientName,
    required DateTime appointmentTime,
  }) async {
    try {
      // تذكير قبل 24 ساعة
      final DateTime reminderTime =
          appointmentTime.subtract(const Duration(hours: 24));

      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: 'تذكير موعد الأسنان',
          body: 'لديك موعد غداً مع $patientName',
          scheduledDate: reminderTime,
          payload: 'appointment_$patientName',
        );
      }

      // تذكير قبل ساعة واحدة
      final DateTime oneHourBefore =
          appointmentTime.subtract(const Duration(hours: 1));

      if (oneHourBefore.isAfter(DateTime.now())) {
        await scheduleNotification(
          title: 'موعد قريب جداً',
          body: 'سيبدأ موعد $patientName خلال ساعة واحدة',
          scheduledDate: oneHourBefore,
          payload: 'appointment_soon_$patientName',
        );
      }
    } catch (e) {
      print('Error scheduling appointment reminder: $e');
    }
  }

  // تذكير الدفع المستحق
  Future<void> schedulePaymentReminder({
    required String patientName,
    required double amount,
  }) async {
    try {
      await showNotification(
        title: 'دفعة مستحقة',
        body:
            'المريض $patientName لديه دفعة مستحقة: ${amount.toStringAsFixed(2)} ج.م',
        payload: 'payment_reminder_$patientName',
      );

      // أيضاً جدولها للغد في نفس الوقت
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
      final DateTime reminderTime =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

      await scheduleNotification(
        title: 'دفعة مستحقة - تذكير يومي',
        body:
            'المريض $patientName لديه دفعة مستحقة: ${amount.toStringAsFixed(2)} ج.م',
        scheduledDate: reminderTime,
        payload: 'payment_daily_$patientName',
      );
    } catch (e) {
      print('Error scheduling payment reminder: $e');
    }
  }

  // معالج النقر على الإشعار
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    print('Handling notification tap with payload: $payload');

    // يمكن إضافة منطق للتنقل إلى شاشات محددة بناءً على payload
    if (payload.startsWith('appointment_')) {
      // التنقل إلى شاشة المواعيد
      print('Navigate to appointments screen');
    } else if (payload.startsWith('payment_')) {
      // التنقل إلى شاشة المدفوعات
      print('Navigate to payments screen');
    }
  }
}
