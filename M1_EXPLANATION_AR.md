# شرح M1 — تسجيل الدخول والحسابات (Auth + Profiles)

**التاريخ:** 2026-11-07 — **البرانش:** `feature/auth` (من `dev`) — **الحالة:** الكود خلص واتأكد (`flutter analyze` نضيف، و24 اختبار ناجحين)، بس **التجربة الحقيقية على Supabase لسه ما اتعملتش** لأن مفتاح الـ anon key مش موجود عندي — هتجربها بنفسك بالخطوات اللي في آخر الملف.

---

## 1. M1 بيعمل إيه بالظبط؟

بعد M1 التطبيق بقى فيه حسابات حقيقية:

- **إنشاء حساب** بإيميل وباسورد، مع اختيار الدور: **صاحب حيوان أليف** أو **طبيب بيطري**.
- **تسجيل دخول** بإيميل وباسورد.
- **الملف الشخصي**: شاشة بتعرض اسمك وإيميلك ودورك ورقم تليفونك، وتقدر تعدّل الاسم والتليفون، وتسجّل خروج.
- **الجلسة بتتحفظ**: لو قفلت التطبيق وفتحته تاني وانت مسجل دخول، هتدخل على طول من غير ما تكتب الباسورد تاني.
- **حماية الصفحات**: لو مش مسجل دخول وSupabase متظبط، التطبيق يودّيك على شاشة الدخول لوحده. ولو مسجل دخول وحاولت تروح لشاشة الدخول، يودّيك على الرئيسية.

واللي لسه **مش** في M1: الحيوانات (M2)، البحث عن أطباء (M3)، الحجز (M4)، لوحة تحكم الطبيب والجدول (M5). كل ده مراحل جاية.

---

## 2. رحلة المستخدم خطوة بخطوة

### إنشاء حساب جديد
1. من الرئيسية تدوس **تسجيل الدخول**، وبعدين **إنشاء حساب جديد**.
2. تختار دورك (صاحب حيوان / طبيب بيطري)، وتكتب اسمك وإيميلك وباسورد (6 أحرف على الأقل) وتأكيد الباسورد، والتليفون اختياري.
3. التطبيق بيبعت البيانات دي لـ Supabase Auth، اللي بينشئ حساب.
4. هنا فيه حالتين، حسب إعدادات مشروعك في Supabase (راجع قسم 6):
   - **تأكيد الإيميل مقفول:** بتتسجل دخول على طول، وصفّك في جدول `profiles` بيتعمل فوراً، وبتروح على الرئيسية.
   - **تأكيد الإيميل مفتوح (الافتراضي):** الشاشة بتقولك "تم إنشاء الحساب! تحقق من بريدك الإلكتروني لتأكيد الحساب، ثم سجل الدخول." بتفتح الإيميل وتدوس لينك التأكيد، وبعدين تسجل دخول عادي — وصفّ `profiles` بيتعمل في أول تسجيل دخول.

### تسجيل الدخول
1. تكتب الإيميل والباسورد وتدوس تسجيل الدخول.
2. لو البيانات صح، التطبيق بيجيب ملفك الشخصي من جدول `profiles` ويدخّلك على الرئيسية.
3. لو غلط، بتظهر رسالة "حدث خطأ ما. حاول مرة أخرى." (الرسالة التقنية الحقيقية بتتسجل في الـ state للتصحيح بس، مش بتظهر للمستخدم).

### فتح التطبيق تاني (استعادة الجلسة)
- أول ما التطبيق يفتح، `AuthCubit.checkSession()` بيسأل Supabase: "في حد مسجل دخول؟" — Supabase نفسه هو اللي حافظ الجلسة على الجهاز، التطبيق مش بيحفظ أي توكن بنفسه.
- لو فيه جلسة، بيجيب الملف الشخصي ويدخّلك على الرئيسية. لو مفيش، بيودّيك على شاشة الدخول.

### تعديل الملف الشخصي وتسجيل الخروج
- من الرئيسية تدوس على اسمك فتروح لشاشة **ملفي الشخصي**، تدوس **تعديل الملف الشخصي**، تغيّر الاسم أو التليفون، وتدوس **حفظ** — التعديل بيظهر فوراً في كل الشاشات.
- زرار **تسجيل الخروج** بيمسح الجلسة ويرجعك لشاشة الدخول.

> **ملحوظة مهمة عن الدور:** من شاشة تعديل الملف الشخصي **مش** تقدر تغيّر دورك (من صاحب حيوان لطبيب مثلاً). ده مقصود: المستخدم مينفعش يرقّي نفسه بنفسه. تغيير الدور هيكون شغل الأدمن في مرحلة جاية.

---

## 3. جدول `profiles` في Supabase — وإزاي بيتعمل

### الملف
`supabase/migrations/20261107000001_auth_profiles.sql` — ده ملف SQL واحد، بتشغّله مرة واحدة من لوحة تحكم Supabase (الخطوات في قسم 6). **الجداول التانية من الخطة (عيادات، أطباء، حيوانات، مواعيد...) مش في الملف ده** — كل مرحلة هتجيب ملف migration بتاعها.

### الجدول
| العمود | النوع | معناه |
|---|---|---|
| `id` | uuid | نفس رقم حساب Supabase بالظبط — هو المفتاح الأساسي، ومرتبط بجدول `auth.users` (لو اتمسح الحساب، الصف بيتمسح لوحده) |
| `role` | `user_role` | الدور: `owner` / `vet` / `staff_vet` / `clinic_admin` |
| `full_name` | text | الاسم الكامل |
| `phone` | text | التليفون (اختياري) |
| `email` | text | الإيميل |
| `avatar_url` | text | صورة البروفايل — لسه فاضية، الرفع هييجي في مرحلة جاية |
| `created_at` / `updated_at` | وقت | `updated_at` بيتحدّث لوحده عند كل تعديل (trigger في الملف) |

### الأمان (RLS — Row Level Security)
الأمان متفعل على الجدول، ومعناه: **من غير policy، محدش يقدر يقرأ أو يكتب حاجة خالص**، حتى لو مسجل دخول. الملف بيعمل 4 قواعد:
1. **كل واحد يشوف صفه هو بس.**
2. **أي حد مسجل دخول يقدر يشوف ملفات الأطباء البيطريين بس** (عشان مرحلة M3 "تصفح الأطباء" تقدر تعرضهم — ملفات أصحاب الحيوانات التانيين بتفضل مخفية).
3. **كل واحد ينشئ صفه هو بس** (رقم الصف لازم يساوي رقم حسابه).
4. **كل واحد يعدّل صفه هو بس.**
- **مفيش قاعدة للحذف عمداً:** الصف بيتمسح لوحده لما الحساب يتمسح، ومحدش يقدر يمسح صف حد تاني.

### ليه مفيش trigger في الداتابيز بينشئ الصف؟
قرار مقصود، ومكتوب في تعليقات ملف الـ SQL:
- **التطبيق هو اللي بينشئ صف الـ profile**، من البيانات اللي اتحفظت في حساب Supabase وقت التسجيل (الاسم والدور — `signUp(data: {...})`).
- ده بيشتغل **سواء تأكيد الإيميل مفتوح أو مقفول**: لو التأكيد مفتوح، مفيش جلسة بعد التسجيل فمستحيل نعمل insert وقتها — الصف بيتعمل في أول تسجيل دخول بعد التأكيد، من نفس البيانات المحفوظة.
- وكل الطرق (تسجيل بعد إنشاء الحساب، أول دخول بعد التأكيد، استعادة الجلسة) بتعدّي من نفس الدالة `_ensureProfile` في الكود — فالصف لا بيتعمل مرتين ولا بيكون ناقص أبداً.

---

## 4. الكود ماشي إزاي؟ (Clean Architecture)

نفس المسار الإجباري بتاع المشروع، من غير أي استثناء:

```
الشاشة (UI) → AuthCubit → UseCase → عقد الـ Repository (domain)
    → تنفيذ الـ Repository (data) → DataSource → Supabase
```

| الطبقة | الملفات | وظيفتها |
|---|---|---|
| **Domain — الكيانات** | `domain/entities/profile.dart` — `Profile` (الملف الشخصي) و `domain/entities/user_role.dart` — `UserRole` (الدور) | تعريف "يعني إيه ملف شخصي" ب Dart نضيف، من غير أي import من Flutter أو Supabase. `UserRole.fromString` بتحوّل نص الداتابيز (`staff_vet`) للـ enum، وأي قيمة غريبة بترجع `owner` بدل ما التطبيق يقع. |
| **Domain — العقد** | `domain/repositories/auth_repository.dart` | عقد `AuthRepository`: خمس عمليات بس (تسجيل حساب، دخول، خروج، الملف الحالي، تعديل الملف). كل عملية بترجع `Result` — يا `Success` بالقيمة، يا `FailureResult` بالخطأ. مفيش حاجة هنا بترمي exception. |
| **Domain — الـ UseCases** | `domain/usecases/` — خمس ملفات، واحد لكل عملية | كل UseCase عملية واحدة بس وبينادي الـ Repository. الـ Cubit بينادي الـ UseCase، مش الـ Repository على طول. |
| **Data — الموديل** | `data/models/profile_model.dart` | `ProfileModel`: بيحوّل بين JSON بتاع الداتابيز (`full_name`, `avatar_url`) وبين كائن `Profile`. فيه `toJson` للإنشاء، و `toUpdateJson` للتعديل (من غير `role` عمداً — شوف قسم 2). |
| **Data — الـ DataSource** | `data/datasources/auth_remote_data_source.dart` (العقد) + `supabase_auth_remote_data_source.dart` (التنفيذ) | **الملف الوحيد في الفيتشر اللي بيستورد Supabase.** فيه `signUp` (بيحفظ الاسم والدور في metadata الحساب)، و `signIn`، و `signOut`، و `getCurrentProfile`، و `updateProfile`، و `_ensureProfile` اللي بتجيب الصف أو تنشئه لو مش موجود. |
| **Data — تنفيذ الـ Repository** | `data/repositories/auth_repository_impl.dart` | بينادي الـ DataSource وبيحوّل الأخطاء لـ `Failure` (خطأ auth → `AuthFailure`، Supabase مش متظبط → `NotConfiguredFailure`، الباقي → `ServerFailure`). |
| **Presentation — الـ Cubit** | `presentation/cubit/auth_cubit.dart` + `auth_state.dart` | `AuthCubit` هو مصدر الحقيقة الوحيد لـ "مين مسجل دخول". كل عملية: Loading ← UseCase ← النتيجة. الحالات: `initial` (لسه ما اتفحصتش)، `loading`، `authenticated`، `unauthenticated`، `awaitingConfirmation` (مستني تأكيد الإيميل). فيه **نسخة واحدة** للتطبيق كله، `BaytariApp` هي اللي بتنشئها وبتقفلها. |
| **Presentation — الشاشات** | `presentation/screens/login_screen.dart` / `register_screen.dart` / `profile_screen.dart` | فورمات وتحقق من البيانات بس — مفيش أي كود Supabase أو API هنا. بعد الدخول الناجح، الـ redirect بتاع الـ Router هو اللي بينقلك للرئيسية. |
| **Presentation — ويدجت** | `presentation/widgets/role_selector.dart` | زرار اختيار الدور (صاحب حيوان / طبيب) في شاشة التسجيل. |
| **DI** | `di/register_auth.dart` | تسجيل GetIt بالترتيب: DataSource ← Repository ← UseCases ← Cubit. متسجل في `injection_container.dart` بعد الـ core. |
| **Core — جديد** | `core/errors/result.dart` | نوع `Result<T>` الصغير (يا `Success` يا `FailureResult`) — معمول بـ `sealed class` في Dart 3 بدل ما نضيف مكتبة `dartz`، حسب قاعدة "ممنوع مكتبات من غير داعي". |
| **الترجمة** | `core/localization/l10n/app_en.arb` + `app_ar.arb` | 26 نص جديد (تسجيل الدخول، إنشاء حساب، البريد، كلمة المرور، رسائل التحقق...) بالعربي والإنجليزي — مفيش أي نص مكتوب جوه الشاشات. |
| **الروتينج** | `core/routing/app_router.dart` | بقى مصنع `AppRouter.create(authCubit:, supabaseConfigured:)` بدل الـ static router — عشان الـ redirect يقرأ حالة الـ Auth ويعيد حساب نفسه كل ما الحالة تتغير (عن طريق `_CubitRefresh` اللي بيحوّل stream بتاع الـ Cubit لـ `ChangeNotifier`). قواعد الـ redirect مكتوبة بالتفصيل في تعليقات الملف. |

### ملفات اتعدلت بره فيتشر الـ auth
- `lib/app/app.dart`: بقى `StatefulWidget` — بينشئ `AuthCubit` والـ `GoRouter` مرة واحدة في `initState` وبيقفلهم في `dispose` (لو اتعملوا في `build`، كل تغيير ثيم/لغة كان هيعيد بناء الـ Router ويضيّع مكانك في التنقل).
- `lib/injection_container.dart`: تسجيل `registerAuth`.
- `lib/features/home/.../home_screen.dart`: بطاقة دخول — لو مسجل دخول بتعرض اسمك وزرار "ملفي الشخصي"، ولو لأ بتعرض زرار "تسجيل الدخول".
- `lib/core/utils/validators.dart`: تحقق جديد `isValidPassword` (6 أحرف على الأقل — ده شرط Supabase).
- `lib/core/constants/supabase_constants.dart`: تحديث التعليق (جدول `profiles` بقى موجود من M1).
- `lib/features/auth/README.md`: وصف الفيتشر بعد M1.
- `README.md` (بتاع التطبيق): حالة المشروع بقت M1 خلصانة، ولينك للملف ده.

**مفيش مكتبات جديدة اتضافت في M1.** كل حاجة اتعملت بالمكتبات اللي كانت موجودة في M0.

---

## 5. الاختبارات (24 اختبار، كلهم ناجحين)

| الملف | عدد | بيختبر إيه |
|---|---|---|
| `test/app_cubit_test.dart` + `test/widget_test.dart` | 6 | اختبارات M0 زي ما هي — لسه شغالة (الرئيسية والإعدادات). |
| `test/features/auth/auth_usecases_test.dart` | 7 | كل UseCase: النجاح بيرجع `Success`، والفشل بيرجع نفس الـ `Failure` — منهم حالة "التسجيل رجّع null عشان تأكيد الإيميل مطلوب". |
| `test/features/auth/auth_cubit_test.dart` | 8 | الـ Cubit: استعادة جلسة موجودة، مفيش جلسة، دخول ناجح وفاشل، تسجيل بحساب فوري وبتأكيد إيميل، خروج، تعديل الملف. |
| `test/features/auth/login_screen_test.dart` | 3 | شاشة الدخول بتظهر بالعربي مع ملحوظة وضع العرض، والفورم الفاضي بيطلع رسائل التحقق، والإرسال الصحيح بينادي `signIn`. |
| `test/features/auth/fake_auth_repository.dart` | — | مش اختبار — ده الـ fake repository اللي الاختبارات بتستخدمه بدل Supabase الحقيقي (مش بيعمل أي اتصال شبكة). |

التحقق اللي اتعمل:
```
flutter analyze   → No issues found!
flutter test      → All tests passed! (24 اختبار)
```
واتأكدت كمان بالـ grep: مفيش أي import من Flutter في `domain/`، مفيش `Text('...')` مكتوب جوه أي ويدجت، مفيش `Color(0x...)` ولا `Colors.` بره `core/theme`، ومفيش أي مفتاح Supabase أو لينك المشروع مكتوب في الكود.

---

## 6. إزاي تشغّل M1 عندك (خطوتين، انت اللي بتعملهم)

### الخطوة 1 — شغّل الـ migration في Supabase (مرة واحدة)
1. افتح [Supabase Dashboard](https://supabase.com/dashboard) وادخل على مشروع **Baytari** (اللينك: `https://jzvwytisqravbqzzznfk.supabase.co`).
2. من القايمة الشمال: **SQL Editor** ← **New query**.
3. افتح الملف `supabase/migrations/20261107000001_auth_profiles.sql` من الريبو، انسخ محتواه كله، والصقه في الـ SQL Editor.
4. دوس **Run**. لو ظهر "Success. No rows returned" يبقى تمام.
5. للتأكيد: روح **Table Editor** وهتلاقي جدول `profiles` موجود، و **Authentication ← Policies** هتلاقي الـ 4 policies بتوعه.

> لو شغّلت الملف مرتين بالغلط مفيش مشكلة — كل جملة فيه فيها `IF NOT EXISTS` أو `DROP ... IF EXISTS` فهو آمن لإعادة التشغيل.

### الخطوة 2 — شغّل التطبيق بالمفاتيح
المفتاح **مش** موجود في الكود ولا في الشات — بتجيبه من لوحة تحكم Supabase: **Project Settings ← API ← Project URL + anon / publishable key**، وبعدين من جوّه مجلد Baytari عندك على الماك (المكان اللي نزلت فيه الريبو):

```bash
flutter run \
  --dart-define SUPABASE_URL=https://jzvwytisqravbqzzznfk.supabase.co \
  --dart-define SUPABASE_ANON_KEY=PUT_YOUR_ANON_KEY_HERE
```

من غير الـ `--dart-define` التطبيق هيشتغل عادي في **وضع العرض**: الرئيسية هتقول "لم يتم إعداد Supabase بعد"، وشاشة الدخول هتقول إن تسجيل الدخول مش متاح — من غير ما يقع.

### إعداد اختياري: تأكيد الإيميل
في Supabase: **Authentication ← Providers ← Email ← Confirm email**:
- **لو خليته مفتوح (الافتراضي):** المستخدم الجديد لازم يأكد إيميله قبل ما يدخل — التطبيق بيتعامل مع ده (شوف قسم 2).
- **لو قفلته (للتجربة السريعة):** التسجيل بيدخّل على طول من غير إيميل. مناسب وانت بتجرب M1، بس للنسخة الحقيقية الأفضل تسيبه مفتوح.

### جرّب إيه بعد التشغيل؟
1. أنشئ حساب بدور **صاحب حيوان**، وادخل بيه.
2. اقفل التطبيق وافتحه تاني — لازم تلاقي نفسك لسه مسجل دخول.
3. عدّل اسمك من شاشة الملف الشخصي، وتأكد إنه اتغير.
4. سجّل خروج — لازم ترجع لشاشة الدخول.
5. (اختياري) أنشئ حساب تاني بدور **طبيب**، وافتح **Table Editor ← profiles** في Supabase وتأكد إن الصفين موجودين بالدور الصح.

---

## 7. اللي ما اتأكدش (بصراحة)

- **التجربة الحقيقية على Supabase ما اتعملتش**: مفيش anon key عندي، فمقدرتش أجرب إنشاء حساب ودخول فعليين ضد مشروعك. الاختبارات كلها بتستخدم fake repository، والكود اتراجع سطر بسطر مقابل API بتاع `supabase_flutter 2.18.3`، بس أول تجربة حقيقية لازم تكون من عندك بالخطوات اللي فوق — ولو ظهر أي خطأ من Supabase (مثلاً رسالة مختلفة)، ابعتلي نص الخطأ وهصلحه.
- **البرانش محلياً**: مجلد التطبيق عندي مش git repo (الدفع للـ GitHub بيتم بأداة الـ snapshot)، فمقدرتش أعمل `git checkout feature/auth` بنفسي — الشغل جاهز في مجلد التطبيق على إنه يترفع على برانش `feature/auth`، والـ merge على `dev` خطوة منفصلة بعد ما تتأكد.

---

## 8. خريطة الملفات (M1)

**اتعملت جديدة (21 ملف):**
- `supabase/migrations/20261107000001_auth_profiles.sql`
- `lib/core/errors/result.dart`
- `lib/features/auth/domain/entities/{profile,user_role}.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/domain/usecases/{sign_up,sign_in,sign_out,get_current_profile,update_profile}_usecase.dart`
- `lib/features/auth/data/models/profile_model.dart`
- `lib/features/auth/data/datasources/{auth_remote_data_source,supabase_auth_remote_data_source}.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/features/auth/di/register_auth.dart`
- `lib/features/auth/presentation/cubit/{auth_cubit,auth_state}.dart`
- `lib/features/auth/presentation/screens/{login,register,profile}_screen.dart`
- `lib/features/auth/presentation/widgets/role_selector.dart`
- `test/features/auth/{fake_auth_repository,auth_usecases_test,auth_cubit_test,login_screen_test}.dart`

**اتعدلت (9 ملفات):** `lib/app/app.dart`، `lib/injection_container.dart`، `lib/core/routing/app_router.dart`، `lib/core/utils/validators.dart`، `lib/core/constants/supabase_constants.dart`، `lib/core/localization/l10n/app_{en,ar}.arb` (+ الملفات المتولدة `generated/`)، `lib/features/home/.../home_screen.dart`، `lib/features/auth/README.md`، `README.md`.
