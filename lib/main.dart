import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'src/api/api_client.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/utils/background_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Permission.notification.request();

  await ApiClient.loadBaseUrl();
  await initializeService();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  final hasToken = await ApiClient.getToken() != null;
  runApp(
    ProviderScope(
      child: MyApp(settingsController: settingsController, hasToken: hasToken),
    ),
  );
  
  FlutterNativeSplash.remove();
}
