import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database/database_helper.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'services/appointment_reminders.dart';
import 'services/payment_reminders.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local database
  await Hive.initFlutter();

  // Initialize DatabaseHelper
  await DatabaseHelper.instance.init();

  // تهيئة نظام الإشعارات
  await NotificationService().initNotifications();

  // جدولة تذكيرات المواعيد والمدفوعات
  await AppointmentReminderManager().scheduleAllAppointmentReminders();
  await PaymentReminderManager().checkAndNotifyPendingPayments();

  // تهيئة اللغة العربية
  await initializeDateFormatting('ar', null);

  // Initialize Theme Service
  await ThemeService().init();

  // Initialize Localization Service
  final prefs = await SharedPreferences.getInstance();
  final language = prefs.getString('language') ?? 'ar';
  LocalizationService().init(language);

  // تعيين اتجاه النص من اليمين لليسار
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeService _themeService;
  late LocalizationService _localizationService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _localizationService = LocalizationService();
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _themeService.darkModeNotifier,
      builder: (context, isDarkMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: _localizationService.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: LocalizationService.get('app_title'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: LocalizationService.supportedLocales,
              locale: locale,

              // Dynamic Theme
              theme: ThemeService.getLightTheme(),
              darkTheme: ThemeService.getDarkTheme(),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

              // Home
              home: FutureBuilder<bool>(
                future: _checkLoginStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final isLoggedIn = snapshot.data ?? false;
                  return isLoggedIn ? const HomeScreen() : const LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}
