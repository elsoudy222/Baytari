// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بيطري';

  @override
  String get arabic => 'العربية';

  @override
  String get emptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get english => 'الإنجليزية';

  @override
  String get errorTitle => 'حدث خطأ ما';

  @override
  String get home => 'الرئيسية';

  @override
  String get homeDescription =>
      'هذه هي النسخة الأولية M0. سيتم إضافة المزايا واحدة تلو الأخرى: تسجيل الدخول، الحيوانات، الأطباء، المواعيد، الجدول، لوحة التحكم والإعدادات.';

  @override
  String get language => 'اللغة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get supabaseConfigured => 'تم إعداد Supabase.';

  @override
  String get supabaseNotConfigured =>
      'لم يتم إعداد Supabase بعد. التطبيق يعمل في وضع العرض.';

  @override
  String get theme => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSystem => 'النظام';

  @override
  String get welcome => 'أهلاً بك في بيطري';

  @override
  String get welcomeMessage =>
      'ابحث عن طبيب بيطري واحجز موعداً لحيوانك الأليف.';
}
