# شرح جزء المصادقة الجديد (Auth UI) — بيطري

> ده شرح بالعربي لكل اللي اتعمل في مرحلة `feature/auth-ui`: إعادة تصميم
> شاشات الدخول والتسجيل حسب تصميم Figma، وإضافة نسيان كلمة المرور،
> والتحقق برمز OTP من الإيميل، واسم المستخدم والصورة، والتحقق من رخصة
> الطبيب/الملجأ. كل الكود فيه تعليقات بالإنجليزي بتشرح كل ملف، والشرح
> ده بيجمع الصورة الكاملة.

## 1) الشاشات الجديدة/المعدّلة ومطابقتها لتصميم Figma

| الشاشة | ملف الكود | علاقتها بـ Figma |
|---|---|---|
| تسجيل الدخول | `lib/features/auth/presentation/screens/login_screen.dart` | `Log_in.png`: "Welcome back!" مع علامة بيطري، خانة "Email or Phone Number"، خانة كلمة المرور مع زر إظهار/إخفاء (العين)، رابط "Forgot your password?"، زر "Log in" تركوازي، فاصل "or log in with"، أزرار Google / X / Facebook |
| التسجيل (معالج متعدد الخطوات) | `lib/features/auth/presentation/screens/register_screen.dart` | `Sign_Up.png` + `Sign_Up_-_community_member_1/2/3.png` + `Sign_Up_-_VET_1..5.png` + `Sign_Up_-_Shelter_1..7.png` |
| نسيان كلمة المرور (4 خطوات) | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | `Forgot_password.png` + `OTP.png` / `OTP-1.png` + `Create_New_Password.png` + `password_confirmation.png` |
| ودجت مشتركة | `lib/features/auth/presentation/widgets/auth_scaffold.dart` (الإطار: بطاقة Mint والخلفية)، `otp_code_input.dart` (4 خانات للرمز)، `password_rules.dart` (قائمة قواعد كلمة المرور)، `social_login_buttons.dart`، `country_code_picker.dart` | نفس الستايل في كل شاشات Figma |

### ترتيب خطوات التسجيل حسب الدور (زي التصميم بالظبط)

1. **اختيار الدور** — 3 كروت: Community Member / Veterinarian / Shelter
   (رسم مبسّط: فقاعة + أيقونة بنفس ألوان التطبيق، مش صورة من Figma).
2. **بيانات الحساب** — الاسم الأول، الاسم الأخير، الإيميل، رقم الهاتف
   (كود الدولة: مصر ‎+20 افتراضي، مع شاشة اختيار كود فيها مصر أولاً ثم
   دول شائعة). الطبيب: اختيار Clinic owner / Staff vet، ولو Staff vet
   بتظهر قائمة "Pick the clinic you work with". الملجأ: Shelter owner /
   Shelter worker، ولو worker بتظهر قائمة "Pick the shelter you work with".
3. **تعيين كلمة المرور** — Create Password + Confirm Password، مع قائمة
   قواعد حيّة: 8 أحرف على الأقل، حروف كبيرة وصغيرة، رقم واحد على الأقل —
   كل قاعدة بتخضر وعليها علامة ✓ أول ما تتحقق.
4. **التحقق من الرخصة** — للطبيب والملجأ بس، قبل الـ OTP (زي ترتيب
   التصميم): "Verify Your License" — تصوير الرخصة بالكاميرا أو اختيار
   صورة، مع Upload Photo / Retake.
5. **رمز التحقق OTP** — 6 خانات، رابط Resend Code، وزر Skip في شاشة
   التسجيل زي التصميم. **ملاحظة مهمة**: التصميم فيه 4 خانات، لكن رمز
   Supabase مكوّن من 6 أرقام على الأقل (الطول بيتظبط في لوحة التحكم
   بين 6 و 10 أرقام بس — مستحيل يبقى 4)، فالواجهة اتعملت 6 خانات عشان
   الرمز الحقيقي يدخل أصلاً، وباقي الستايل زي Figma بالظبط (التفاصيل
   في قسم 4، نقطة 2).
6. **اسم المستخدم والصورة** — "Welcome To Baytari!"، خانة username،
   "Add Profile Photo" (اختيار من المعرض أو الكاميرا).
7. **تأكيد إنشاء الحساب** — نص المجتمع: "You can now start exploring the
   app and connecting with your local community!" ونص الطبيب: "You can now
   manage your clinic, take appointments, and connect with the community."
   (الملجأ بياخد نص المجتمع)، مع زر "Go to Home" تركوازي.

### نسيان كلمة المرور (4 خطوات)

1. **Reset Your Password** — إيميل + زر "Send OTP".
2. **Enter Verification Code** — 6 خانات (التصميم 4 — شوف النقطة 2 في
   قسم 4)، ولو الكود غلط بتظهر رسالة حمرا:
   "Wrong Code. Please try again or reset your code." + رابط Resend Code.
3. **Create New Password** — نفس قائمة القواعد الحيّة + تأكيد كلمة المرور.
4. **نجاح** — "Your Password Was Reset Successfully!" + زر "Go to Home"
   (بيودّي على شاشة الدخول لأن المستخدم مسجّل خروج).

## 2) قرارات مهمة لازم تعرفها

### الـ OTP بيروح للإيميل بس — مش للموبايل
التصميم مكتوب فيه "Email or Phone Number"، لكن في v1 الـ OTP بيتبعت
**للإيميل فقط**. إرسال OTP برسالة SMS محتاج مزوّد SMS مدفوع (زي Twilio)
ومش في نطاق المرحلة دي. رقم الموبايل بيتجمع في التسجيل وبيتخزّن على
البروفايل، لكن رموز التحقق وإعادة تعيين كلمة المرور بتتبعت للإيميل.
الكود مش بيدّعي إن OTP الموبايل شغال.

### تسجيل الدخول الاجتماعي (Google / X / Facebook): واجهة بس
الأزرار موجودة في التصميم، لكن الضغط عليها بيظهر رسالة "coming soon"
مترجمة. تسجيل الدخول الاجتماعي محتاج إعداد مزوّد OAuth في Supabase
وGoogle Cloud / Meta — مش في نطاق المرحلة دي، والكود مش بيعمل تسجيل
دخول وهمي.

### اختيار العيادة/الملجأ للموظفين: ملاحظة نصّية مؤقتاً
لسه مفيش عيادات أو ملاجئ في قاعدة البيانات (هتتبني في المراحل الجاية)،
فالقائمة المنسدلة بتوضّح إن الاختيار هيتوفر قريباً، واختيار الموظف
بيتسجّل كـ **ملاحظة نصّية** على البروفايل (`workplace_note`) مش كمفتاح
أجنبي. لما تتبني جداول العيادات/الملاجئ، الملاحظة دي بتتبدّل بارتباط
حقيقي.

### الـ OTP بيعتمد على إعدادات Supabase — اقرأ قسم 4 قبل التجربة
لو الـ OTP مش مفعّل في مشروعك، التطبيق بيقع على السلوك القديم من M1:
بعد التسجيل بيظهر "تأكيد الإيميل مطلوب" (حالة `awaitingConfirmation`).

## 3) قاعدة البيانات — ملف هجرة جديد (لسه ما اتطبّقش)

الملف: `supabase/migrations/20261107000002_auth_ui.sql`

**لسه ما اتطبّقش — لازم تطبّقه انت من لوحة تحكم Supabase** بنفس طريقة
هجرة M1: افتح SQL Editor في مشروع `jzvwytisqravbqzzznfk`، انسخ محتوى
الملف، ونفّذ. الهجرة آمنة للتكرار (idempotent): فيها `IF NOT EXISTS`
و `DROP POLICY IF EXISTS` فلو اتنفّذت مرتين مش هتكسر حاجة.

اللي بتعمله الهجرة:
- بتضيف دورين جداد لنوع `user_role`: `shelter_owner` و `shelter_worker`.
- بتضيف 3 أعمدة لجدول `profiles`: `username text UNIQUE` و
  `license_url text` و `workplace_note text` (ملاحظة نصّية لاختيار
  الموظف للعيادة/الملجأ لحد ما تتبني الجداول دي).
- بتنشئ bucket تخزين `avatars` (صور البروفايل) و `licenses` (صور الرخص)،
  مع سياسات RLS تسمح لكل مستخدم يرفع ويقرأ ملفاته هو بس.

## 4) إعدادات Supabase اللي لازم تتأكد منها

قبل ما تجرّب الـ OTP، افتح لوحة تحكم Supabase لمشروعك:

1. **Authentication → Providers → Email**: تأكد إن مزوّد Email مفعّل،
   وإن خيار **"Confirm email"** مفعّل. ده اللي بيخلي Supabase يبعت
   رموز OTP للإيميل.
2. **Authentication → Email Templates → Confirm signup**: تأكد إن
   القالب فيه المتغير `{{ .Token }}` — ده الرمز اللي المستخدم بيدخّله
   في الخانات.
   **طول الرمز — نقطة مهمة وحُسمت في الكود**: شاشات Figma فيها 4 خانات،
   لكن رمز الـ OTP من Supabase مكوّن من **6 أرقام افتراضياً**، والطول
   بيتظبط في لوحة التحكم (Authentication → Sign In / Providers → Email
   → **Email OTP length**) بين **6 و 10 أرقام بس — مستحيل يبقى 4**.
   عشان كده الواجهة اتعملت **6 خانات** (نفس ستايل Figma: حدود Mint،
   صناديق مستديرة، والحالة الحمرا للكود الغلط)، والكود بيقبل الرمز
   الـ 6 أرقام زي ما بييجي من الإيميل. **اللي عليك: سيب "Email OTP
   length" على 6 في لوحة التحكم** (الافتراضي)، ولو غيّرته لـ 7–10 لازم
   تقولّي أعدّل عدد الخانات في التطبيق لنفس الرقم. (الكلام ده متأكد
   منه من توثيق Supabase نفسه: "users key in a six-digit code" والطول
   قابل للضبط بين 6 و 10.)
3. **Authentication → Email Templates → Reset password**: نفس الكلام —
   القالب لازم فيه `{{ .Token }}` عشان رمز الاسترداد (6 أرقام برضه).
4. **Storage**: بعد تطبيق الهجرة، اتأكد إن الـ buckets `avatars` و
   `licenses` ظاهرين في Storage.
5. لو الـ OTP مش شغال أصلاً (مثلاً الإيميلات مش بتوصل في الخطة المجانية
   أو الـ SMTP مش مظبوط)، التسجيل لسه شغال بالطريقة القديمة: Supabase
   بيبعت لينك تأكيد، والتطبيق بيعرض حالة "تأكيد الإيميل مطلوب".
   الكود بيستخدم `verifyOTP` مع `OtpType.signup` و `OtpType.recovery`
   من `supabase_flutter 2.18.3` (متأكد منها من الكود المثبّت عندنا).

## 5) المعمارية — نفس Clean Architecture

- **Use cases جديدة** في `lib/features/auth/domain/usecases/`:
  `RequestOtpUseCase` (للـ signup والـ recovery)، `VerifyOtpUseCase`،
  `ResetPasswordUseCase`، `UpdateUsernameAndAvatarUseCase`،
  `UploadLicenseUseCase`، `UploadAvatarUseCase`.
- **العقد (Repository)** اتوسّع في
  `lib/features/auth/domain/repositories/auth_repository.dart`،
  والتنفيذ في `auth_repository_impl.dart`، والاتصال بـ Supabase في
  `supabase_auth_remote_data_source.dart` — فيه `signInWithOtp` و
  `verifyOTP` و `updateUser` ورفع الملفات لـ Storage
  (`uploadBinary` / `getPublicUrl`).
- **الـ Cubit** (`auth_cubit.dart`) اتوسّع بأكشنات: `requestSignupOtp`،
  `requestPasswordReset`، `verifySignupOtp`، `verifyRecoveryOtp`،
  `resetPassword`، `completeProfile` (اسم المستخدم + الصورة)،
  `uploadLicense` — و `AuthAction` جديدة: `otpSent`، `otpVerified`،
  `passwordReset`، `profileCompleted`، `licenseUploaded`، والشاشات
  بتتنقل بناءً عليها.
- **الـ DI** في `injection_container.dart`: كل الـ use cases الجديدة
  متسجلة بالترتيب الصحيح.
- **الترجمة**: كل النصوص الجديدة في `app_en.arb` و `app_ar.arb`
  (حوالي 80 مفتاح جديد) — مفيش نص مكتوب مباشرة في الواجهة، ومفيش لون
  مكتوب مباشرة برّه `core/theme` (حتى اللون الأزرق بتاع Facebook بقى
  `AppColors.facebookBlue` في الثيم).
- **الـ Profile** اتوسّع: `username`، `licenseUrl`، `workplaceNote`،
  ودورين جداد `shelterOwner` و `shelterWorker` في `UserRole`.
- **اعتماد جديد واحد مبرر**: `image_picker ^1.1.2` — لاختيار صورة
  البروفايل والرخصة من المعرض أو الكاميرا.
- **المسارات الجديدة** في `app_router.dart` (كلها عامة، الحارس مش
  بيحوّل منها): `/forgot-password`، `/forgot-password/verify`،
  `/forgot-password/new-password`، `/forgot-password/success`. مسار
  التسجيل `/register` زي ما هو، بس الشاشة بقت المعالج الجديد.

## 6) الملفات اللي اتغيّرت/اتعملت

**ملفات جديدة:**
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/widgets/auth_scaffold.dart`
- `lib/features/auth/presentation/widgets/country_code_picker.dart`
- `lib/features/auth/presentation/widgets/otp_code_input.dart`
- `lib/features/auth/presentation/widgets/password_rules.dart`
- `lib/features/auth/presentation/widgets/social_login_buttons.dart`
- `lib/features/auth/domain/usecases/request_otp_usecase.dart`
- `lib/features/auth/domain/usecases/verify_otp_usecase.dart`
- `lib/features/auth/domain/usecases/reset_password_usecase.dart`
- `lib/features/auth/domain/usecases/update_username_and_avatar_usecase.dart`
- `lib/features/auth/domain/usecases/upload_license_usecase.dart`
- `lib/features/auth/domain/usecases/upload_avatar_usecase.dart`
- `supabase/migrations/20261107000002_auth_ui.sql`
- `test/features/auth/auth_ui_test.dart`
- `AUTH_UI_EXPLANATION_AR.md` (الملف ده)

**ملفات اتعدّلت:**
- `lib/features/auth/presentation/screens/login_screen.dart` (إعادة تصميم كاملة)
- `lib/features/auth/presentation/screens/register_screen.dart` (بقت معالج 7 خطوات)
- `lib/features/auth/presentation/screens/profile_screen.dart` (تسمية الدورين الجداد)
- `lib/features/auth/domain/entities/profile.dart` + `profile_model.dart` (الحقول الجديدة)
- `lib/features/auth/domain/entities/user_role.dart` (الدورين الجداد)
- `lib/features/auth/domain/repositories/auth_repository.dart` + `auth_repository_impl.dart`
- `lib/features/auth/data/datasources/supabase_auth_remote_data_source.dart` (OTP + رفع ملفات)
- `lib/features/auth/presentation/cubit/auth_cubit.dart` + `auth_state.dart`
- `lib/core/routing/app_router.dart` (مسارات نسيان كلمة المرور)
- `lib/core/theme/app_colors.dart` (لون Facebook في الثيم)
- `lib/injection_container.dart` (تسجيل الـ use cases الجديدة)
- `lib/core/localization/l10n/app_en.arb` + `app_ar.arb` (مفاتيح جديدة)
- `pubspec.yaml` (إضافة `image_picker`)
- `README.md` (تحديث الحالة)
- `test/features/auth/fake_auth_repository.dart` + `auth_cubit_test.dart` + `login_screen_test.dart` (تحديث للـ API الجديد)

**ملف اتمسح:** `lib/features/auth/presentation/widgets/role_selector.dart`
(القديم بتاع اختيار الدور في شاشة التسجيل — المعالج الجديد فيه كروت
الدور بتاعته).

## 7) إزاي تختبر

1. طبّق الهجرة `20261107000002_auth_ui.sql` من SQL Editor (قسم 3).
2. اتأكد من إعدادات الإيميل/OTP في Supabase (قسم 4) — وسيب طول الـ OTP
   على 6 (الافتراضي) عشان يطابق الـ 6 خانات في الواجهة.
3. شغّل التطبيق:
   `flutter run --dart-define SUPABASE_URL=https://jzvwytisqravbqzzznfk.supabase.co --dart-define SUPABASE_ANON_KEY=...`
4. جرّب: تسجيل دخول قديم → نسيان كلمة المرور (إيميل → كود → كلمة جديدة
   → دخول بالجديدة) → تسجيل جديد كـ Community Member (كل الخطوات) →
   تسجيل جديد كـ Veterinarian (مع الرخصة) → تسجيل جديد كـ Shelter.
5. الاختبارات الآلية: `flutter analyze` نظيف، و `flutter test` كلها
   ناجحة (48 اختبار: 30 القدام + 18 جداد في `auth_ui_test.dart`).

## 8) اللي لسه مؤجل (مش في المرحلة دي)

- تسجيل الدخول بـ Google / X / Facebook (واجهة بس، رسالة "coming soon").
- OTP للموبايل عبر SMS (الإيميل بس في v1).
- اختيار عيادة/ملجأ حقيقي من قاعدة البيانات (ملاحظة نصّية مؤقتاً).
- **انحراف واحد مقصود عن التصميم**: خانات الـ OTP عددها 6 مش 4، لأن
  رمز Supabase 6 أرقام على الأقل ومستحيل يبقى 4 — بـ 4 خانات كان
  التحقق هيفشل دايماً (التفاصيل في قسم 4، نقطة 2).
