# Local Android build compatibility patch

Source: `on_audio_query_android` **1.1.0** from pub.dev, upstream repository:
https://github.com/LucJosin/on_audio_query/tree/main/packages/on_audio_query_android

The upstream license is retained in `LICENSE`. This copy is selected through
the root `pubspec.yaml` dependency override; the global pub cache is untouched.

Local changes:
- Remove the legacy Kotlin Gradle Plugin and obsolete AGP/KGP buildscript pins.
- Use built-in Kotlin and `kotlin.compilerOptions` with Java/Kotlin target 17.
- Declare the namespace and compile/minimum SDK directly (36/24).
- Remove the legacy manifest `package` attribute; Gradle owns the namespace.
- Require the SDK baseline used by this app (Flutter 3.50 / Dart 3.14).

Migration reference:
https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors

No query behavior or public API is intentionally changed. Replace this copy
with an upstream release when it supports built-in Kotlin, and remove the
dependency override after validating device-library queries and artwork.
