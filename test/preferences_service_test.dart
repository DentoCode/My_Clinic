import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dental_clinic_app/services/preferences_service.dart';

void main() {
  group('PreferencesService Tests', () {
    late PreferencesService prefsService;

    setUp(() async {
      // تهيئة SharedPreferences للاختبار
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefsService = PreferencesService();
      await prefsService.init();
    });

    test('تحميل القيم الافتراضية عند التهيئة', () async {
      expect(prefsService.getNotificationsEnabled(), isTrue);
      expect(prefsService.getAppointmentRemindersEnabled(), isTrue);
      expect(prefsService.getPaymentRemindersEnabled(), isTrue);
      expect(prefsService.getDarkMode(), isFalse);
      expect(prefsService.getLanguage(), 'ar');
      expect(prefsService.getReminderHours(), 24);
      expect(prefsService.getPaymentReminderDays(), 7);
      expect(prefsService.getAutoSyncEnabled(), isTrue);
    });

    test('حفظ واسترجاع حالة الإشعارات', () async {
      await prefsService.setNotificationsEnabled(false);
      expect(prefsService.getNotificationsEnabled(), isFalse);

      await prefsService.setNotificationsEnabled(true);
      expect(prefsService.getNotificationsEnabled(), isTrue);
    });

    test('حفظ واسترجاع حالة تذكيرات المواعيد', () async {
      await prefsService.setAppointmentRemindersEnabled(false);
      expect(prefsService.getAppointmentRemindersEnabled(), isFalse);

      await prefsService.setAppointmentRemindersEnabled(true);
      expect(prefsService.getAppointmentRemindersEnabled(), isTrue);
    });

    test('حفظ واسترجاع حالة تذكيرات المدفوعات', () async {
      await prefsService.setPaymentRemindersEnabled(false);
      expect(prefsService.getPaymentRemindersEnabled(), isFalse);

      await prefsService.setPaymentRemindersEnabled(true);
      expect(prefsService.getPaymentRemindersEnabled(), isTrue);
    });

    test('حفظ واسترجاع الوضع المظلم', () async {
      await prefsService.setDarkMode(true);
      expect(prefsService.getDarkMode(), isTrue);

      await prefsService.setDarkMode(false);
      expect(prefsService.getDarkMode(), isFalse);
    });

    test('حفظ واسترجاع اللغة', () async {
      await prefsService.setLanguage('en');
      expect(prefsService.getLanguage(), 'en');

      await prefsService.setLanguage('ar');
      expect(prefsService.getLanguage(), 'ar');
    });

    test('حفظ واسترجاع وقت التذكير', () async {
      final testHours = [1, 6, 12, 24, 48];

      for (final hours in testHours) {
        await prefsService.setReminderHours(hours);
        expect(prefsService.getReminderHours(), hours);
      }
    });

    test('حفظ واسترجاع فترة تذكير المدفوعات', () async {
      final testDays = [1, 3, 7, 14, 30];

      for (final days in testDays) {
        await prefsService.setPaymentReminderDays(days);
        expect(prefsService.getPaymentReminderDays(), days);
      }
    });

    test('حفظ واسترجاع حالة المزامنة التلقائية', () async {
      await prefsService.setAutoSyncEnabled(false);
      expect(prefsService.getAutoSyncEnabled(), isFalse);

      await prefsService.setAutoSyncEnabled(true);
      expect(prefsService.getAutoSyncEnabled(), isTrue);
    });

    test('حفظ واسترجاع حالة تسجيل الدخول', () async {
      await prefsService.setLoginStatus(true);
      expect(prefsService.getLoginStatus(), isTrue);

      await prefsService.setLoginStatus(false);
      expect(prefsService.getLoginStatus(), isFalse);
    });

    test('حفظ واسترجاع بيانات المستخدم', () async {
      const testName = 'أحمد محمد';
      const testEmail = 'ahmed@example.com';

      await prefsService.setUserName(testName);
      expect(prefsService.getUserName(), testName);

      await prefsService.setUserEmail(testEmail);
      expect(prefsService.getUserEmail(), testEmail);
    });

    test('حفظ واسترجاع وقت آخر نسخة احتياطية', () async {
      final testTime = DateTime.now();
      await prefsService.setLastBackupTime(testTime);

      final retrievedTime = prefsService.getLastBackupTime();
      expect(retrievedTime, isNotNull);
      expect(
        retrievedTime?.year,
        testTime.year,
      );
      expect(retrievedTime?.month, testTime.month);
      expect(retrievedTime?.day, testTime.day);
    });

    test('حذف تفضيل معين', () async {
      await prefsService.setLanguage('en');
      expect(prefsService.getLanguage(), 'en');

      await prefsService.removePreference('language');
      expect(prefsService.getLanguage(), 'ar'); // القيمة الافتراضية
    });

    test('حذف جميع التفضيلات', () async {
      // تعيين قيم مختلفة
      await prefsService.setLanguage('en');
      await prefsService.setDarkMode(true);
      await prefsService.setReminderHours(48);

      // التحقق من أنها محفوظة
      expect(prefsService.getLanguage(), 'en');
      expect(prefsService.getDarkMode(), isTrue);
      expect(prefsService.getReminderHours(), 48);

      // حذف الكل
      await prefsService.clearAllPreferences();

      // التحقق من استعادة القيم الافتراضية
      expect(prefsService.getLanguage(), 'ar');
      expect(prefsService.getDarkMode(), isFalse);
      expect(prefsService.getReminderHours(), 24);
    });

    test('اختبار متعدد الخيوط - حفظ متزامن', () async {
      final futures = <Future<void>>[];

      for (int i = 0; i < 10; i++) {
        futures.add(prefsService.setReminderHours(i + 1));
        futures.add(prefsService.setLanguage(i % 2 == 0 ? 'ar' : 'en'));
      }

      await Future.wait(futures);

      // التحقق من أن القيم محفوظة
      expect(prefsService.getReminderHours(), isNotNull);
      expect(prefsService.getLanguage(), isNotNull);
    });

    test('اختبار الأداء - حفظ 100 عملية', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        await prefsService.setReminderHours((i % 5) + 1);
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds,
          lessThan(5000)); // يجب أن يتم في أقل من 5 ثواني
      print(
          '✅ 100 عملية حفظ تمت في ${stopwatch.elapsedMilliseconds} ميلي ثانية');
    });

    test('التحقق من النوع الصحيح للبيانات', () async {
      // التحقق من أن جميع القيم بالنوع الصحيح
      expect(prefsService.getNotificationsEnabled(), isA<bool>());
      expect(prefsService.getDarkMode(), isA<bool>());
      expect(prefsService.getLanguage(), isA<String>());
      expect(prefsService.getReminderHours(), isA<int>());
      expect(prefsService.getPaymentReminderDays(), isA<int>());
    });

    test('اختبار الحدود - قيم حد أدنى وأعلى', () async {
      // اختبار القيم الحد الأدنى
      await prefsService.setReminderHours(1);
      expect(prefsService.getReminderHours(), 1);

      // اختبار القيم الحد الأقصى
      await prefsService.setReminderHours(999);
      expect(prefsService.getReminderHours(), 999);

      // اختبار أيام الدفع
      await prefsService.setPaymentReminderDays(1);
      expect(prefsService.getPaymentReminderDays(), 1);

      await prefsService.setPaymentReminderDays(365);
      expect(prefsService.getPaymentReminderDays(), 365);
    });
  });
}
