import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // إعدادات الإشعارات
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool('enableNotifications', value);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool('enableNotifications') ?? true;
  }

  Future<void> setAppointmentRemindersEnabled(bool value) async {
    await _prefs.setBool('enableAppointmentReminders', value);
  }

  bool getAppointmentRemindersEnabled() {
    return _prefs.getBool('enableAppointmentReminders') ?? true;
  }

  Future<void> setPaymentRemindersEnabled(bool value) async {
    await _prefs.setBool('enablePaymentReminders', value);
  }

  bool getPaymentRemindersEnabled() {
    return _prefs.getBool('enablePaymentReminders') ?? true;
  }

  // إعدادات المظهر
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('darkMode', value);
  }

  bool getDarkMode() {
    return _prefs.getBool('darkMode') ?? false;
  }

  // اللغة
  Future<void> setLanguage(String language) async {
    await _prefs.setString('language', language);
  }

  String getLanguage() {
    return _prefs.getString('language') ?? 'ar';
  }

  // أوقات التذكير
  Future<void> setReminderHours(int hours) async {
    await _prefs.setInt('reminderHours', hours);
  }

  int getReminderHours() {
    return _prefs.getInt('reminderHours') ?? 24;
  }

  Future<void> setPaymentReminderDays(int days) async {
    await _prefs.setInt('paymentReminderDays', days);
  }

  int getPaymentReminderDays() {
    return _prefs.getInt('paymentReminderDays') ?? 7;
  }

  // حالة تسجيل الدخول
  Future<void> setLoginStatus(bool status) async {
    await _prefs.setBool('isLoggedIn', status);
  }

  bool getLoginStatus() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  // معلومات المستخدم
  Future<void> setUserName(String name) async {
    await _prefs.setString('userName', name);
  }

  String getUserName() {
    return _prefs.getString('userName') ?? 'المستخدم';
  }

  Future<void> setUserEmail(String email) async {
    await _prefs.setString('userEmail', email);
  }

  String getUserEmail() {
    return _prefs.getString('userEmail') ?? '';
  }

  // إعدادات إضافية
  Future<void> setAutoSyncEnabled(bool value) async {
    await _prefs.setBool('autoSync', value);
  }

  bool getAutoSyncEnabled() {
    return _prefs.getBool('autoSync') ?? true;
  }

  Future<void> setLastBackupTime(DateTime dateTime) async {
    await _prefs.setString('lastBackup', dateTime.toIso8601String());
  }

  DateTime? getLastBackupTime() {
    final timestamp = _prefs.getString('lastBackup');
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // حذف جميع الإعدادات
  Future<void> clearAllPreferences() async {
    await _prefs.clear();
  }

  // حذف إعدادات محددة
  Future<void> removePreference(String key) async {
    await _prefs.remove(key);
  }
}
