import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dental_clinic_app/services/theme_service.dart';

void main() {
  group('ThemeService Tests', () {
    // Initialize SharedPreferences for testing
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeService is a singleton', () {
      final service1 = ThemeService();
      final service2 = ThemeService();
      expect(identical(service1, service2), true);
    });

    test('isDarkMode returns correct initial value', () async {
      final service = ThemeService();
      await service.init();
      // Should be false by default
      expect(service.isDarkMode, false);
    });

    test('setDarkMode updates isDarkMode', () async {
      final service = ThemeService();
      await service.init();

      await service.setDarkMode(true);
      expect(service.isDarkMode, true);

      await service.setDarkMode(false);
      expect(service.isDarkMode, false);
    });

    test('darkModeNotifier emits changes', () async {
      final service = ThemeService();
      await service.init();

      final notifier = service.darkModeNotifier;
      expect(notifier.value, false);

      await service.setDarkMode(true);
      expect(notifier.value, true);
    });

    test('getLightTheme returns valid ThemeData', () {
      final lightTheme = ThemeService.getLightTheme();

      expect(lightTheme, isNotNull);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.primaryColor, isNotNull);
      expect(lightTheme.scaffoldBackgroundColor, isNotNull);
    });

    test('getDarkTheme returns valid ThemeData', () {
      final darkTheme = ThemeService.getDarkTheme();

      expect(darkTheme, isNotNull);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.primaryColor, isNotNull);
      expect(darkTheme.scaffoldBackgroundColor, isNotNull);
    });

    test('Light and Dark themes have different colors', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(
        lightTheme.scaffoldBackgroundColor,
        isNot(darkTheme.scaffoldBackgroundColor),
      );
    });

    test('ThemeData has proper AppBar theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.appBarTheme, isNotNull);
      expect(darkTheme.appBarTheme, isNotNull);
      expect(lightTheme.appBarTheme.elevation, 0);
      expect(darkTheme.appBarTheme.elevation, 0);
      expect(lightTheme.cardTheme, isNotNull);
      expect(darkTheme.cardTheme, isNotNull);
      expect(lightTheme.cardTheme.elevation, 2);
      expect(darkTheme.cardTheme.elevation, 2);
    });

    test('ThemeData has proper Input decoration theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.inputDecorationTheme, isNotNull);
      expect(darkTheme.inputDecorationTheme, isNotNull);
    });

    test('ThemeData has proper Button theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.elevatedButtonTheme, isNotNull);
      expect(darkTheme.elevatedButtonTheme, isNotNull);
      expect(lightTheme.textButtonTheme, isNotNull);
      expect(darkTheme.textButtonTheme, isNotNull);
    });

    test('ThemeData has proper FloatingActionButton theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.floatingActionButtonTheme, isNotNull);
      expect(darkTheme.floatingActionButtonTheme, isNotNull);
    });

    test('ThemeData has proper Dialog theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.dialogTheme, isNotNull);
      expect(darkTheme.dialogTheme, isNotNull);
    });

    test('ThemeData has proper SnackBar theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.snackBarTheme, isNotNull);
      expect(darkTheme.snackBarTheme, isNotNull);
    });

    test('ThemeData has proper Text theme', () {
      final lightTheme = ThemeService.getLightTheme();
      final darkTheme = ThemeService.getDarkTheme();

      expect(lightTheme.textTheme, isNotNull);
      expect(darkTheme.textTheme, isNotNull);
      expect(lightTheme.textTheme.displayLarge, isNotNull);
      expect(darkTheme.textTheme.displayLarge, isNotNull);
    });

    test('Multiple setDarkMode calls maintain correct state', () async {
      final service = ThemeService();
      await service.init();

      await service.setDarkMode(true);
      expect(service.isDarkMode, true);

      await service.setDarkMode(true);
      expect(service.isDarkMode, true);

      await service.setDarkMode(false);
      expect(service.isDarkMode, false);

      await service.setDarkMode(false);
      expect(service.isDarkMode, false);
    });
  });
}
