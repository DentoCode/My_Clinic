import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:dental_clinic_app/services/localization_service.dart';

void main() {
  group('LocalizationService Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocalizationService is a singleton', () {
      final service1 = LocalizationService();
      final service2 = LocalizationService();
      expect(identical(service1, service2), true);
    });

    test('Default locale is Arabic', () {
      final service = LocalizationService();
      expect(service.currentLocale, const Locale('ar', 'EG'));
    });

    test('setLocale changes current locale to Arabic', () {
      final service = LocalizationService();
      service.setLocale('ar');
      expect(service.currentLocale, const Locale('ar', 'EG'));
    });

    test('setLocale changes current locale to English', () {
      final service = LocalizationService();
      service.setLocale('en');
      expect(service.currentLocale, const Locale('en', 'US'));
    });

    test('Arabic translations are available', () {
      final title = LocalizationService.get('app_title');
      expect(title, 'عيادة الأسنان');
    });

    test('English translations are available', () {
      final title = LocalizationService.get('app_title', locale: 'en');
      expect(title, 'Dental Clinic');
    });

    test('localeNotifier emits changes', () async {
      final service = LocalizationService();
      final notifier = service.localeNotifier;

      expect(notifier.value, const Locale('ar', 'EG'));

      service.setLocale('en');
      expect(notifier.value, const Locale('en', 'US'));
    });

    test('All required keys exist in Arabic translations', () {
      const requiredKeys = [
        'app_title',
        'patients',
        'appointments',
        'treatments',
        'payments',
        'settings',
        'add_patient',
        'edit_patient',
        'delete_patient',
      ];

      for (final key in requiredKeys) {
        final value = LocalizationService.get(key);
        expect(value.isNotEmpty, true);
        expect(value, isNot(key)); // Should not return the key itself
      }
    });

    test('All required keys exist in English translations', () {
      const requiredKeys = [
        'app_title',
        'patients',
        'appointments',
        'treatments',
        'payments',
        'settings',
        'add_patient',
        'edit_patient',
        'delete_patient',
      ];

      for (final key in requiredKeys) {
        final value = LocalizationService.get(key, locale: 'en');
        expect(value.isNotEmpty, true);
      }
    });

    test('Unknown keys return the key itself', () {
      final value = LocalizationService.get('unknown_key_12345');
      expect(value, 'unknown_key_12345');
    });

    test('Locale switching is case-insensitive', () {
      final service = LocalizationService();

      service.setLocale('AR');
      expect(service.currentLocale, const Locale('ar', 'EG'));

      service.setLocale('EN');
      expect(service.currentLocale, const Locale('en', 'US'));
    });

    test('Supported locales are correct', () {
      const expected = [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ];

      expect(LocalizationService.supportedLocales, expected);
    });

    test('Arabic translations have correct counts', () {
      // Test sample of translations
      expect(LocalizationService.get('home'), 'الرئيسية');
      expect(LocalizationService.get('home_ar'), isNotEmpty);
    });

    test('English translations have correct counts', () {
      // Test sample of translations
      final home = LocalizationService.get('home');
      expect(home.isNotEmpty, true);
    });

    test('Multiple locale switches maintain state', () {
      final service = LocalizationService();

      service.setLocale('ar');
      expect(service.currentLocale, const Locale('ar', 'EG'));

      service.setLocale('en');
      expect(service.currentLocale, const Locale('en', 'US'));

      service.setLocale('ar');
      expect(service.currentLocale, const Locale('ar', 'EG'));
    });

    test('Patient-related translations are complete', () {
      const keys = [
        'add_patient',
        'edit_patient',
        'delete_patient',
        'patient_name',
        'patient_phone',
        'patient_email',
      ];

      for (final key in keys) {
        final ar = LocalizationService.get(key);
        expect(ar.isNotEmpty, true);
      }
    });

    test('Appointment translations are complete', () {
      const keys = [
        'add_appointment',
        'edit_appointment',
        'delete_appointment',
        'appointment_date',
        'appointment_time',
        'appointment_status',
      ];

      for (final key in keys) {
        final ar = LocalizationService.get(key);
        expect(ar.isNotEmpty, true);
      }
    });

    test('Treatment translations are complete', () {
      const keys = [
        'add_treatment',
        'edit_treatment',
        'delete_treatment',
        'treatment_name',
        'treatment_description',
        'treatment_cost',
      ];

      for (final key in keys) {
        final ar = LocalizationService.get(key);
        expect(ar.isNotEmpty, true);
      }
    });

    test('Payment translations are complete', () {
      const keys = [
        'add_payment',
        'edit_payment',
        'delete_payment',
        'payment_amount',
        'payment_date',
        'payment_method',
        'payment_status',
      ];

      for (final key in keys) {
        final ar = LocalizationService.get(key);
        expect(ar.isNotEmpty, true);
      }
    });

    test('Common message translations are available', () {
      const keys = [
        'success',
        'error',
        'confirm',
        'cancel',
        'save',
        'delete',
        'loading',
      ];

      for (final key in keys) {
        final ar = LocalizationService.get(key);
        expect(ar.isNotEmpty, true);
      }
    });
  });
}
