## Smaller Android builds

Run from the `user_app` directory:

```powershell
flutter build apk --release --split-per-abi
```

For sample data with login skipped:

```powershell
flutter build apk --release --split-per-abi --dart-define=TEST_MODE=true
```

Outputs are in `build/app/outputs/flutter-apk/`. Install one APK matching the
device architecture, usually `app-arm64-v8a-release.apk` for a modern Android
phone. Debug APKs contain development tooling and are larger.

Category photos are JPEGs capped at 1600 pixels on the longest edge, encoded at
quality 82. Keep originals outside the bundled `assets` folder. After replacing
category photos, the Windows helper can optimize them:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/optimize-assets.ps1
flutter test test/category_media_test.dart
```

The helper changes category PNG photos to JPEG. `CategoryMedia` resolves the
category covers and three project photos dynamically; retain all four images
per category even if a literal-path search does not find references.
