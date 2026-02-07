import 'package:flutter/material.dart';

/// نظام إدارة اللغة والترجمات
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  late Locale _currentLocale = const Locale('ar', 'EG');
  final ValueNotifier<Locale> _localeNotifier =
      ValueNotifier(const Locale('ar', 'EG'));

  ValueNotifier<Locale> get localeNotifier => _localeNotifier;
  Locale get currentLocale => _currentLocale;

  // قاموس الترجمات الرئيسي
  static final Map<String, Map<String, String>> _translations = {
    'ar_EG': _getArabicTranslations(),
    'en_US': _getEnglishTranslations(),
  };

  /// تهيئة خدمة اللغة
  void init(String languageCode) {
    setLocale(languageCode);
  }

  /// تغيير اللغة
  void setLocale(String languageCode) {
    final locale = _getLocaleFromCode(languageCode);
    _currentLocale = locale;
    _localeNotifier.value = locale;
  }

  /// الحصول على Locale من الكود
  static Locale _getLocaleFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'ar':
      case 'ar_eg':
        return const Locale('ar', 'EG');
      case 'en':
      case 'en_us':
        return const Locale('en', 'US');
      default:
        return const Locale('ar', 'EG');
    }
  }

  /// الحصول على ترجمة
  static String get(String key, {String? locale}) {
    final currentLang = locale ?? _getInstance()._getLanguageKey();
    final translations = _translations[currentLang] ?? _translations['ar_EG']!;
    return translations[key] ?? key;
  }

  /// الحصول على مفتاح اللغة الحالية
  String _getLanguageKey() {
    return _currentLocale.languageCode == 'ar' ? 'ar_EG' : 'en_US';
  }

  /// الحصول على instance
  static LocalizationService _getInstance() => _instance;

  /// قائمة اللغات المدعومة
  static const List<Locale> supportedLocales = [
    Locale('ar', 'EG'),
    Locale('en', 'US'),
  ];

  /// الترجمات العربية
  static Map<String, String> _getArabicTranslations() {
    return {
      // العناوين الرئيسية
      'app_title': 'عيادة الأسنان',
      'home': 'الرئيسية',
      'patients': 'المرضى',
      'appointments': 'المواعيد',
      'treatments': 'العلاجات',
      'payments': 'المدفوعات',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',

      // تسجيل الدخول
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'remember_me': 'تذكرني',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'sign_in': 'دخول',
      'sign_up': 'إنشاء حساب',

      // إدارة المرضى
      'add_patient': 'إضافة مريض',
      'patient_name': 'اسم المريض',
      'patient_phone': 'رقم الهاتف',
      'patient_email': 'البريد الإلكتروني',
      'patient_age': 'العمر',
      'patient_gender': 'الجنس',
      'patient_medical_history': 'التاريخ الطبي',
      'edit_patient': 'تعديل المريض',
      'delete_patient': 'حذف المريض',
      'patient_details': 'تفاصيل المريض',
      'no_patients': 'لا توجد مرضى',
      'patient_added_successfully': 'تم إضافة المريض بنجاح',
      'patient_updated_successfully': 'تم تحديث المريض بنجاح',

      // المواعيد
      'add_appointment': 'إضافة موعد',
      'appointment_date': 'تاريخ الموعد',
      'appointment_time': 'وقت الموعد',
      'appointment_type': 'نوع الموعد',
      'appointment_notes': 'ملاحظات',
      'appointment_status': 'حالة الموعد',
      'upcoming': 'قادم',
      'completed': 'مكتمل',
      'cancelled': 'ملغى',
      'edit_appointment': 'تعديل الموعد',
      'delete_appointment': 'حذف الموعد',
      'no_appointments': 'لا توجد مواعيد',
      'appointment_added_successfully': 'تم إضافة الموعد بنجاح',
      'appointment_updated_successfully': 'تم تحديث الموعد بنجاح',

      // العلاجات
      'add_treatment': 'إضافة علاج',
      'treatment_name': 'اسم العلاج',
      'treatment_description': 'وصف العلاج',
      'treatment_cost': 'تكلفة العلاج',
      'treatment_status': 'حالة العلاج',
      'in_progress': 'قيد التنفيذ',
      'on_hold': 'معلق',
      'finished': 'منتهي',
      'edit_treatment': 'تعديل العلاج',
      'delete_treatment': 'حذف العلاج',
      'procedures': 'الإجراءات',
      'no_treatments': 'لا توجد علاجات',
      'treatment_added_successfully': 'تم إضافة العلاج بنجاح',
      'treatment_updated_successfully': 'تم تحديث العلاج بنجاح',

      // المدفوعات
      'add_payment': 'إضافة دفعة',
      'payment_amount': 'مبلغ الدفعة',
      'payment_date': 'تاريخ الدفع',
      'payment_method': 'طريقة الدفع',
      'payment_status': 'حالة الدفع',
      'paid': 'مدفوع',
      'pending': 'قيد الانتظار',
      'overdue': 'متأخر',
      'cash': 'نقداً',
      'card': 'بطاقة ائتمان',
      'transfer': 'تحويل بنكي',
      'check': 'شيك',
      'edit_payment': 'تعديل الدفعة',
      'delete_payment': 'حذف الدفعة',
      'no_payments': 'لا توجد مدفوعات',
      'payment_added_successfully': 'تم إضافة الدفعة بنجاح',
      'payment_updated_successfully': 'تم تحديث الدفعة بنجاح',

      // التقارير
      'total_patients': 'إجمالي المرضى',
      'total_appointments': 'إجمالي المواعيد',
      'total_treatments': 'إجمالي العلاجات',
      'total_revenue': 'إجمالي الإيرادات',
      'pending_payments': 'مدفوعات قيد الانتظار',
      'completed_treatments': 'علاجات مكتملة',
      'revenue_chart': 'رسم الإيرادات',
      'patients_chart': 'رسم المرضى',
      'monthly_report': 'التقرير الشهري',
      'yearly_report': 'التقرير السنوي',

      // الإعدادات
      'notifications': 'الإشعارات',
      'enable_notifications': 'تفعيل الإشعارات',
      'appointment_reminders': 'تذكيرات المواعيد',
      'payment_reminders': 'تذكيرات المدفوعات',
      'dark_mode': 'الوضع المظلم',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'about': 'حول التطبيق',
      'version': 'الإصدار',
      'backup_restore': 'النسخ الاحتياطي والاستعادة',
      'backup': 'إنشاء نسخة احتياطية',
      'restore': 'استعادة من نسخة احتياطية',
      'clear_data': 'مسح البيانات',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_conditions': 'الشروط والأحكام',

      // الرسائل
      'success': 'نجح',
      'error': 'خطأ',
      'warning': 'تحذير',
      'info': 'معلومة',
      'confirm': 'تأكيد',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'save': 'حفظ',
      'add': 'إضافة',
      'search': 'بحث',
      'filter': 'تصفية',
      'sort': 'ترتيب',
      'yes': 'نعم',
      'no': 'لا',
      'loading': 'جاري التحميل...',
      'no_data': 'لا توجد بيانات',
      'are_you_sure': 'هل أنت متأكد؟',
      'this_action_cannot_be_undone': 'لا يمكن التراجع عن هذا الإجراء',
      'operation_successful': 'تمت العملية بنجاح',
      'something_went_wrong': 'حدث خطأ ما',
      'please_try_again': 'يرجى المحاولة مجدداً',
      'internet_connection_error': 'خطأ في الاتصال بالإنترنت',
      'field_required': 'هذا الحقل مطلوب',
      'invalid_email': 'بريد إلكتروني غير صحيح',
      'password_too_short': 'كلمة المرور قصيرة جداً',
      'settings_saved_successfully': 'تم حفظ الإعدادات بنجاح',

      // التاريخ والوقت
      'today': 'اليوم',
      'yesterday': 'أمس',
      'tomorrow': 'غداً',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'this_year': 'هذه السنة',
      'january': 'يناير',
      'february': 'فبراير',
      'march': 'مارس',
      'april': 'أبريل',
      'may': 'مايو',
      'june': 'يونيو',
      'july': 'يوليو',
      'august': 'أغسطس',
      'september': 'سبتمبر',
      'october': 'أكتوبر',
      'november': 'نوفمبر',
      'december': 'ديسمبر',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
    };
  }

  /// الترجمات الإنجليزية
  static Map<String, String> _getEnglishTranslations() {
    return {
      // Main Titles
      'app_title': 'Dental Clinic',
      'home': 'Home',
      'patients': 'Patients',
      'appointments': 'Appointments',
      'treatments': 'Treatments',
      'payments': 'Payments',
      'reports': 'Reports',
      'settings': 'Settings',
      'logout': 'Logout',

      // Login
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'remember_me': 'Remember Me',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',

      // Patients Management
      'add_patient': 'Add Patient',
      'patient_name': 'Patient Name',
      'patient_phone': 'Phone Number',
      'patient_email': 'Email Address',
      'patient_age': 'Age',
      'patient_gender': 'Gender',
      'patient_medical_history': 'Medical History',
      'edit_patient': 'Edit Patient',
      'delete_patient': 'Delete Patient',
      'patient_details': 'Patient Details',
      'no_patients': 'No Patients',
      'patient_added_successfully': 'Patient added successfully',
      'patient_updated_successfully': 'Patient updated successfully',

      // Appointments
      'add_appointment': 'Add Appointment',
      'appointment_date': 'Appointment Date',
      'appointment_time': 'Appointment Time',
      'appointment_type': 'Appointment Type',
      'appointment_notes': 'Notes',
      'appointment_status': 'Appointment Status',
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'edit_appointment': 'Edit Appointment',
      'delete_appointment': 'Delete Appointment',
      'no_appointments': 'No Appointments',
      'appointment_added_successfully': 'Appointment added successfully',
      'appointment_updated_successfully': 'Appointment updated successfully',

      // Treatments
      'add_treatment': 'Add Treatment',
      'treatment_name': 'Treatment Name',
      'treatment_description': 'Description',
      'treatment_cost': 'Cost',
      'treatment_status': 'Treatment Status',
      'in_progress': 'In Progress',
      'on_hold': 'On Hold',
      'finished': 'Finished',
      'edit_treatment': 'Edit Treatment',
      'delete_treatment': 'Delete Treatment',
      'procedures': 'Procedures',
      'no_treatments': 'No Treatments',
      'treatment_added_successfully': 'Treatment added successfully',
      'treatment_updated_successfully': 'Treatment updated successfully',

      // Payments
      'add_payment': 'Add Payment',
      'payment_amount': 'Payment Amount',
      'payment_date': 'Payment Date',
      'payment_method': 'Payment Method',
      'payment_status': 'Payment Status',
      'paid': 'Paid',
      'pending': 'Pending',
      'overdue': 'Overdue',
      'cash': 'Cash',
      'card': 'Credit Card',
      'transfer': 'Bank Transfer',
      'check': 'Check',
      'edit_payment': 'Edit Payment',
      'delete_payment': 'Delete Payment',
      'no_payments': 'No Payments',
      'payment_added_successfully': 'Payment added successfully',
      'payment_updated_successfully': 'Payment updated successfully',

      // Reports
      'total_patients': 'Total Patients',
      'total_appointments': 'Total Appointments',
      'total_treatments': 'Total Treatments',
      'total_revenue': 'Total Revenue',
      'pending_payments': 'Pending Payments',
      'completed_treatments': 'Completed Treatments',
      'revenue_chart': 'Revenue Chart',
      'patients_chart': 'Patients Chart',
      'monthly_report': 'Monthly Report',
      'yearly_report': 'Yearly Report',

      // Settings
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'appointment_reminders': 'Appointment Reminders',
      'payment_reminders': 'Payment Reminders',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'about': 'About',
      'version': 'Version',
      'backup_restore': 'Backup & Restore',
      'backup': 'Create Backup',
      'restore': 'Restore from Backup',
      'clear_data': 'Clear Data',
      'privacy_policy': 'Privacy Policy',
      'terms_conditions': 'Terms & Conditions',

      // Messages
      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'info': 'Info',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'no_data': 'No Data',
      'are_you_sure': 'Are you sure?',
      'this_action_cannot_be_undone': 'This action cannot be undone',
      'operation_successful': 'Operation Successful',
      'something_went_wrong': 'Something went wrong',
      'please_try_again': 'Please try again',
      'internet_connection_error': 'Internet Connection Error',
      'field_required': 'This field is required',
      'invalid_email': 'Invalid email address',
      'password_too_short': 'Password is too short',
      'settings_saved_successfully': 'Settings saved successfully',

      // Date & Time
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'this_year': 'This Year',
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
    };
  }
}
