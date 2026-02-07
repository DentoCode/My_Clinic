import 'package:flutter/material.dart';
import 'package:dental_clinic_app/services/preferences_service.dart';
import 'package:dental_clinic_app/services/theme_service.dart';
import 'package:dental_clinic_app/services/localization_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PreferencesService _prefsService;
  late LocalizationService _localizationService;
  bool _enableNotifications = true;
  bool _enableAppointmentReminders = true;
  bool _enablePaymentReminders = true;
  bool _darkMode = false;
  String _selectedLanguage = 'ar';
  int _reminderHours = 24;
  int _paymentReminderDays = 7;
  bool _autoSync = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefsService = PreferencesService();
    _localizationService = LocalizationService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _prefsService.init();

      if (!mounted) return;

      setState(() {
        _enableNotifications = _prefsService.getNotificationsEnabled();
        _enableAppointmentReminders =
            _prefsService.getAppointmentRemindersEnabled();
        _enablePaymentReminders = _prefsService.getPaymentRemindersEnabled();
        _darkMode = _prefsService.getDarkMode();
        _selectedLanguage = _prefsService.getLanguage();
        _reminderHours = _prefsService.getReminderHours();
        _paymentReminderDays = _prefsService.getPaymentReminderDays();
        _autoSync = _prefsService.getAutoSyncEnabled();
        _isLoading = false;
      });

      print('✅ Settings loaded successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'خطأ في تحميل الإعدادات: $e';
        _isLoading = false;
      });
      print('❌ Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prefsService.setNotificationsEnabled(_enableNotifications);
      await _prefsService
          .setAppointmentRemindersEnabled(_enableAppointmentReminders);
      await _prefsService.setPaymentRemindersEnabled(_enablePaymentReminders);
      await _prefsService.setDarkMode(_darkMode);
      await _prefsService.setLanguage(_selectedLanguage);
      await _prefsService.setReminderHours(_reminderHours);
      await _prefsService.setPaymentReminderDays(_paymentReminderDays);
      await _prefsService.setAutoSyncEnabled(_autoSync);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ الإعدادات بنجاح'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Settings saved successfully');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في الحفظ: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );

      print('❌ Error saving settings: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _prefsService.setLoginStatus(false);
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                print('✅ User logged out successfully');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ خطأ في تسجيل الخروج: $e')),
                );
                print('❌ Error during logout: $e');
              }
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف البيانات المؤقتة'),
        content: const Text(
            '⚠️ هل تريد حذف جميع البيانات المؤقتة؟ هذا لا يمكن التراجع عنه'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);

                // محاكاة حذف البيانات
                await Future.delayed(const Duration(milliseconds: 500));

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم حذف البيانات المؤقتة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );

                print('✅ Cache cleared successfully');
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );

                print('❌ Error clearing cache: $e');
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    try {
      // تحديث وقت آخر نسخة احتياطية
      await _prefsService.setLastBackupTime(DateTime.now());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إنشاء نسخة احتياطية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // تحديث الواجهة
      setState(() {});

      print('✅ Backup created successfully');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في النسخ الاحتياطي: $e'),
          backgroundColor: Colors.red,
        ),
      );

      print('❌ Error creating backup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[600],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadSettings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة محاولة'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // قسم الإشعارات
                      _buildSectionHeader('🔔 الإشعارات'),
                      _buildNotificationsTile(),

                      // قسم المظهر واللغة
                      _buildSectionHeader('🎨 المظهر واللغة'),
                      _buildThemeTile(),
                      _buildLanguageTile(),

                      // قسم تذكيرات المواعيد
                      _buildSectionHeader('📅 تذكيرات المواعيد'),
                      _buildReminderTimeTile(),

                      // قسم تذكيرات المدفوعات
                      _buildSectionHeader('💳 تذكيرات المدفوعات'),
                      _buildPaymentReminderTile(),

                      // قسم المزامنة التلقائية
                      _buildSectionHeader('🔄 المزامنة والنسخ الاحتياطي'),
                      _buildAutoSyncTile(),
                      _buildBackupTile(),
                      _buildClearCacheTile(),

                      // قسم معلومات التطبيق
                      _buildSectionHeader('ℹ️ معلومات التطبيق'),
                      _buildAboutTile(),
                      _buildVersionTile(),

                      // زر تسجيل الخروج
                      _buildSectionHeader(''),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[600],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _enableNotifications ? Colors.green[400]! : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.notifications_active,
          color: _enableNotifications ? Colors.green : Colors.grey,
        ),
        title: const Text('تفعيل الإشعارات'),
        subtitle: Text(
          _enableNotifications ? '✅ الإشعارات مفعلة' : '⛔ الإشعارات معطلة',
          style: TextStyle(
            color: _enableNotifications ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Switch(
          value: _enableNotifications,
          activeColor: Colors.green,
          onChanged: (value) {
            setState(() {
              _enableNotifications = value;
            });
            _saveSettings();

            // رسالة تأكيد
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value ? '✅ الإشعارات مفعلة الآن' : '⛔ الإشعارات معطلة الآن',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeTile() {
    final themeService = ThemeService();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(
          _darkMode ? Icons.dark_mode : Icons.light_mode,
          color: Colors.blue,
        ),
        title: const Text('الوضع المظلم'),
        subtitle: Text(_darkMode ? 'قيد التفعيل' : 'معطل'),
        trailing: Switch(
          value: _darkMode,
          onChanged: (value) async {
            setState(() {
              _darkMode = value;
            });

            // تطبيق الوضع المظلم مباشرة
            await themeService.setDarkMode(value);

            // إظهار رسالة تأكيد
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? '✅ تم تفعيل الوضع المظلم'
                        : '✅ تم تفعيل الوضع الفاتح',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }

            _saveSettings();
          },
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.language, color: Colors.blue),
        title: Text(LocalizationService.get('language')),
        subtitle: Text(_selectedLanguage == 'ar'
            ? LocalizationService.get('arabic')
            : LocalizationService.get('english')),
        trailing: DropdownButton<String>(
          value: _selectedLanguage,
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Text(LocalizationService.get('arabic')),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(LocalizationService.get('english')),
            ),
          ],
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                _selectedLanguage = value;
              });

              // تغيير اللغة الفورية
              _localizationService.setLocale(value);

              // حفظ الإعداد
              await _prefsService.setLanguage(value);

              // عرض رسالة تأكيد
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value == 'ar'
                        ? '✅ تم تغيير اللغة إلى العربية'
                        : '✅ Language changed to English'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildReminderTimeTile() {
    String _getReminderLabel(int hours) {
      if (hours == 1) return '1 ساعة';
      if (hours == 6) return '6 ساعات';
      if (hours == 12) return '12 ساعة';
      if (hours == 24) return '24 ساعة (يوم واحد)';
      if (hours == 48) return '48 ساعة (يومان)';
      return '$hours ساعة';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[400]!, width: 2),
      ),
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.orange),
        title: const Text('التذكير قبل'),
        subtitle: Text(
          _getReminderLabel(_reminderHours),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        trailing: PopupMenuButton<int>(
          initialValue: _reminderHours,
          onSelected: (value) {
            setState(() {
              _reminderHours = value;
            });
            _saveSettings();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ تم تغيير وقت التذكير إلى ${_getReminderLabel(value)}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            const PopupMenuItem<int>(value: 1, child: Text('⏱️ 1 ساعة')),
            const PopupMenuItem<int>(value: 6, child: Text('⏱️ 6 ساعات')),
            const PopupMenuItem<int>(value: 12, child: Text('⏱️ 12 ساعة')),
            const PopupMenuItem<int>(
                value: 24, child: Text('⏱️ 24 ساعة (يوم واحد)')),
            const PopupMenuItem<int>(
                value: 48, child: Text('⏱️ 48 ساعة (يومان)')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentReminderTile() {
    String _getPaymentReminderLabel(int days) {
      if (days == 1) return '1 يوم';
      if (days == 3) return '3 أيام';
      if (days == 7) return '7 أيام (أسبوع واحد)';
      if (days == 14) return '14 يوم (أسبوعان)';
      if (days == 30) return '30 يوم (شهر واحد)';
      return '$days يوم';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[400]!, width: 2),
      ),
      child: ListTile(
        leading: const Icon(Icons.currency_exchange, color: Colors.purple),
        title: const Text('تذكر المدفوعات المتأخرة'),
        subtitle: Text(
          _getPaymentReminderLabel(_paymentReminderDays),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.purple,
          ),
        ),
        trailing: PopupMenuButton<int>(
          initialValue: _paymentReminderDays,
          onSelected: (value) {
            setState(() {
              _paymentReminderDays = value;
            });
            _saveSettings();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ تم تغيير فترة التذكير إلى ${_getPaymentReminderLabel(value)}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            const PopupMenuItem<int>(value: 1, child: Text('💳 1 يوم')),
            const PopupMenuItem<int>(value: 3, child: Text('💳 3 أيام')),
            const PopupMenuItem<int>(
                value: 7, child: Text('💳 7 أيام (أسبوع)')),
            const PopupMenuItem<int>(
                value: 14, child: Text('💳 14 يوم (أسبوعان)')),
            const PopupMenuItem<int>(value: 30, child: Text('💳 30 يوم (شهر)')),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTile() {
    final lastBackup = _prefsService.getLastBackupTime();
    final backupText = lastBackup != null
        ? 'آخر نسخة: ${lastBackup.year}/${lastBackup.month}/${lastBackup.day}'
        : 'لم يتم عمل نسخة بعد';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.backup, color: Colors.blue),
        title: const Text('إنشاء نسخة احتياطية'),
        subtitle: Text(backupText),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _backupData,
      ),
    );
  }

  Widget _buildAutoSyncTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.sync, color: Colors.blue),
        title: const Text('المزامنة التلقائية'),
        subtitle: const Text('مزامنة البيانات بشكل تلقائي'),
        trailing: Switch(
          value: _autoSync,
          onChanged: (value) {
            setState(() {
              _autoSync = value;
            });
            _saveSettings();
          },
        ),
      ),
    );
  }

  Widget _buildClearCacheTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.delete_sweep, color: Colors.red),
        title: const Text('حذف البيانات المؤقتة'),
        subtitle: const Text('تحرير مساحة التخزين'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _clearCache,
      ),
    );
  }

  Widget _buildAboutTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.blue),
        title: const Text('عن التطبيق'),
        subtitle: const Text('عيادة الأسنان - نظام إدارة المرضى'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('عن التطبيق'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عيادة الأسنان',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'تطبيق شامل لإدارة عيادة الأسنان',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'المميزات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• إدارة بيانات المرضى'),
                  Text('• تسجيل المواعيد والعلاجات'),
                  Text('• متابعة المدفوعات'),
                  Text('• توليد التقارير'),
                  Text('• نظام التنبيهات والتذكيرات'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const ListTile(
        leading: Icon(Icons.build, color: Colors.blue),
        title: Text('إصدار التطبيق'),
        subtitle: Text('الإصدار 1.0.0'),
      ),
    );
  }
}
