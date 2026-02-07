# دليل الوضع المظلم - كيفية الاستخدام

## 🎯 كيفية استخدام نظام الوضع المظلم

### للمستخدم النهائي:

#### 1. **تفعيل/تعطيل الوضع المظلم**
```
1. افتح التطبيق
2. اذهب إلى الشاشة الرئيسية
3. اضغط على زر القائمة (⋮) أو أيقونة الإعدادات
4. اختر "الإعدادات" (Settings)
5. ابحث عن "الوضع المظلم" (Dark Mode)
6. فعّل أو عطّل الزر (Switch)
7. سيتم حفظ الإعداد تلقائياً
```

#### 2. **التبديل الفوري**
- عند التبديل، سيرى المستخدم رسالة تأكيد خضراء
- جميع الشاشات ستتحول فوراً
- الإعداد سيبقى محفوظاً عند إعادة فتح التطبيق

---

### للمطورين:

#### 1. **الوصول إلى ThemeService**
```dart
import 'package:dental_clinic_app/services/theme_service.dart';

// الحصول على instance
final themeService = ThemeService();

// التحقق من الحالة الحالية
bool isDark = themeService.isDarkMode;

// تغيير الوضع
await themeService.setDarkMode(true);
```

#### 2. **الاستماع للتغييرات**
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.darkModeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    // تحديث الشاشة عند تغيير الوضع
    setState(() {});
  }

  @override
  void dispose() {
    _themeService.darkModeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الشاشة ستتحدث تلقائياً
    return Container();
  }
}
```

#### 3. **استخدام الألوان من الثيم**
```dart
// بدل استخدام الألوان المحددة مسبقاً
// استخدم Theme.of(context) للحصول على الألوان الديناميكية

// ❌ خطأ:
color: Colors.blue[600]

// ✅ صحيح:
color: Theme.of(context).primaryColor

// بعض الأمثلة:
backgroundColor: Theme.of(context).scaffoldBackgroundColor,
foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
borderColor: Theme.of(context).dividerColor,
```

#### 4. **إنشاء Widget يدعم Dark Mode**
```dart
class MyCustomCard extends StatelessWidget {
  final String title;
  final String content;

  const MyCustomCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // الحصول على الثيم الحالي
    final theme = Theme.of(context);
    
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔍 كيفية اختبار الوضع المظلم

### 1. **الاختبار اليدوي**
```
✓ فعّل الوضع المظلم وتحقق من:
  - تحويل جميع الشاشات فوراً
  - حفظ الإعداد عند الإغلاق
  - استرجاع الوضع عند الفتح مجدداً
  
✓ اختبر على أجهزة مختلفة:
  - هواتف صغيرة
  - هواتف كبيرة
  - أجهزة Tablet
  
✓ اختبر جميع الشاشات:
  - الشاشة الرئيسية
  - شاشة المرضى
  - شاشة المواعيد
  - شاشة المدفوعات
  - شاشات التقارير
```

### 2. **الاختبار باستخدام الأوامر**
```bash
# تشغيل جميع اختبارات الوضع المظلم
flutter test test/theme_service_test.dart

# تشغيل اختبار محدد
flutter test test/theme_service_test.dart -k "setDarkMode"

# تشغيل مع تغطية (coverage)
flutter test --coverage test/theme_service_test.dart
```

### 3. **مثال اختبار Unit Test**
```dart
test('Switching dark mode updates all widgets', () async {
  final service = ThemeService();
  await service.init();
  
  // الوضع الفاتح
  expect(service.isDarkMode, false);
  
  // تبديل إلى الوضع المظلم
  await service.setDarkMode(true);
  expect(service.isDarkMode, true);
  
  // التحقق من الـ Notifier
  expect(service.darkModeNotifier.value, true);
});
```

---

## 📊 المقاييس والأداء

### حجم الملفات المضافة:
- `lib/services/theme_service.dart`: ~350 سطر
- `test/theme_service_test.dart`: ~160 سطر
- `DARK_MODE_IMPLEMENTATION.md`: ~400 سطر
- **الإجمالي**: ~910 سطور

### أداء التطبيق:
- ✅ تبديل فوري (بدون تأخير ملحوظ)
- ✅ استهلاك ذاكرة منخفض
- ✅ لا يؤثر على الأداء

---

## 🐛 استكشاف الأخطاء

### المشكلة: الوضع المظلم لا يتطبق عند التبديل

**الحل:**
```dart
// تأكد من أن MyApp يستخدم ValueListenableBuilder
return ValueListenableBuilder<bool>(
  valueListenable: themeService.darkModeNotifier,
  builder: (context, isDarkMode, _) {
    return MaterialApp(
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // ...
    );
  },
);
```

### المشكلة: الإعداد لا يُحفظ

**الحل:**
```dart
// تأكد من استدعاء init() في main()
void main() async {
  await ThemeService().init();
  runApp(const MyApp());
}
```

### المشكلة: الألوان لا تتغير في Widget معين

**الحل:**
```dart
// استخدم Theme.of(context) بدل الألوان المحددة مسبقاً
// بدل:
color: Colors.blue[600]

// استخدم:
color: Theme.of(context).primaryColor
```

---

## 🎨 تخصيص الألوان

### لتغيير الألوان في Dark Mode:

1. افتح `lib/services/theme_service.dart`
2. ابحث عن الدالة `getDarkTheme()`
3. غيّر الألوان كما تريد:

```dart
static ThemeData getDarkTheme() {
  return ThemeData(
    primaryColor: Colors.blue[400],  // غيّر هنا
    scaffoldBackgroundColor: Colors.grey[900],  // أو هنا
    // ...
  );
}
```

### للوضع الفاتح:
1. افتح نفس الملف
2. ابحث عن الدالة `getLightTheme()`
3. غيّر الألوان كما تريد

---

## 📚 الموارد الإضافية

### ملفات ذات صلة:
- `lib/services/theme_service.dart` - تطبيق الخدمة
- `lib/main.dart` - التهيئة والتطبيق
- `lib/screens/settings_screen.dart` - واجهة المستخدم
- `test/theme_service_test.dart` - الاختبارات

### مراجع Flutter:
- [ThemeData Documentation](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Theme class Documentation](https://api.flutter.dev/flutter/material/Theme-class.html)
- [ThemeMode Documentation](https://api.flutter.dev/flutter/material/ThemeMode-class.html)

---

## ✅ قائمة التحقق

تأكد من:
- [ ] تم تهيئة ThemeService في main()
- [ ] MyApp يستخدم ValueListenableBuilder
- [ ] Settings Screen به زر تبديل الوضع المظلم
- [ ] الإعدادات تُحفظ في SharedPreferences
- [ ] جميع الشاشات تستقبل الثيم الجديد
- [ ] الاختبارات تمر بنجاح
- [ ] لا توجد أخطاء compilation

---

## 🚀 الخلاصة

نظام الوضع المظلم جاهز للاستخدام الفوري ويوفر:
- ✅ تبديل فوري وسلس
- ✅ حفظ تلقائي للإعدادات
- ✅ دعم جميع الشاشات
- ✅ ألوان متناسقة
- ✅ أداء ممتاز

**استمتع باستخدام الوضع المظلم! 🌙**
