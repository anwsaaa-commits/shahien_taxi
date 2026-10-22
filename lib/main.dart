name: Build Flutter APK

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: "zulu"
          java-version: "17"

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22.2"
          channel: "stable"

      - name: Create Project Structure
        run: |
          flutter create . --org com.shahien.taxi --project-name shahien_taxi --no-pub

      - name: Fix Android Manifest Location Permission
        run: |
          MANIFEST_PATH="android/app/src/main/AndroidManifest.xml"
          if [ -f "$MANIFEST_PATH" ]; then
            sed -i '/<application/i \    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />' "$MANIFEST_PATH"
          fi

      - name: Force Modern Kotlin Version
        run: |
          BUILD_GRADLE="android/build.gradle"
          if [ -f "$BUILD_GRADLE" ]; then
            echo "buildscript { ext.kotlin_version = '1.9.24' }" | cat - "$BUILD_GRADLE" > temp && mv temp "$BUILD_GRADLE"
          fi
          SETTINGS_GRADLE="android/settings.gradle"
          if [ -f "$SETTINGS_GRADLE" ]; then
            sed -i "s/id \"org.jetbrains.kotlin.android\" version .*/id \"org.jetbrains.kotlin.android\" version \"1.9.24\" apply false/" "$SETTINGS_GRADLE"
          fi

      - name: Get Dependencies
        run: |
          flutter pub get
          flutter pub run flutter_launcher_icons

      - name: Build APK (Debug Mode)
        run: flutter build apk --debug --no-tree-shake-icons -PkotlinVersion=1.9.24

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: build/app/outputs/flutter-apk/app-debug.apk
