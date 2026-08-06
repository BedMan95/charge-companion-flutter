# Charge Companion

An EV Charging Companion App built with Flutter. Designed to integrate with Tuya Smart Plugs for monitoring and controlling your electric vehicle charging sessions.

## Features

*   **Dashboard:** Real-time charging status, dynamic power estimation based on Constant Current/Constant Voltage (CC/CV) curves, and real-time AC to DC conversion metrics.
*   **Background Polling:** Continues calculating energy and monitoring Tuya plug status even when the app is closed.
*   **Smart Notifications:** Alerts you once the target percentage is reached or when the charger enters the tapering phase (< 300W), and automatically cuts off the smart plug.
*   **Vehicle Management:** Support for multiple vehicles. Custom overrides for battery voltage, capacity (Ah), charger efficiency, and calibration data without touching the core models.
*   **Modern UI:** Slate and Emerald dark theme, animated pulsing loaders, and keyboard-aware bottom sheets.
*   **Settings:** Configure Tuya IoT API credentials, PLN tariff, and fallback battery parameters.

## Development Requirements

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.0.0 or higher recommended)
*   [Dart SDK](https://dart.dev/get-dart)
*   [Android Studio](https://developer.android.com/studio) (for Android development)
*   **Android:** Android SDK 35 (as per `build.gradle` configuration)

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/BedMan95/charge-companion-flutter.git
    cd charge-companion-flutter
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

## Build APK

The build script includes an auto-versioning feature for Android that increments the build number on each release build. The output APK name will be formatted as `ChargeCompanion_vYY.MM.DD.[build_number]_[variant].apk`.

**To build a debug APK:**
```bash
flutter build apk --debug
```

**To build a release APK:**
```bash
flutter build apk --release
```
