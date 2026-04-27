# 🎮 Match Masters - بازی Match-3 رقابتی

بازی Match-3 با هوش مصنوعی، بوستر، لیدربرد و سیستم جام.

## قابلیت‌ها
- تخته ۷×۷ با ۶ نوع جواهر
- هوش مصنوعی رقیب
- سیستم بوستر (شارژ با مچ‌کردن)
- تایمر ۱۵ ثانیه برای هر نوبت
- ۵ دور رقابتی
- لیدربرد با ذخیره جام‌ها
- سیستم لیگ (برنز / نقره / طلا / افسانه‌ای)
- راهنمایی (Hint)

## ساخت APK

### روش ۱ — GitHub Actions (خودکار)
1. این پروژه رو Fork یا Upload کن به GitHub
2. Actions → Build APK → Run workflow
3. APK از بخش Artifacts دانلود کن

### روش ۲ — محلی
```bash
flutter pub get
flutter build apk --release
```
APK در مسیر: `build/app/outputs/flutter-apk/app-release.apk`

## ساختار پروژه
```
lib/
├── main.dart          # نقطه ورود
├── game_state.dart    # منطق بازی (Provider)
└── screens/
    ├── home_screen.dart
    ├── game_screen.dart
    ├── result_screen.dart
    └── leaderboard_screen.dart
```
