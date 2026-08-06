# Charge Companion

An EV Charging Companion App built with Flutter. Designed to integrate with Tuya Smart Plugs for monitoring and controlling your electric vehicle charging sessions.

## Features

*   **Dashboard:** Real-time charging status, estimated completion time, and quick controls.
*   **Vehicle Management:** Support for multiple vehicles with specific battery capacities and charging limits.
*   **Settings:** Configure API credentials and app preferences.

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
