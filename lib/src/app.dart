import 'ui/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/dashboard_view.dart';
import 'ui/settings_view.dart';
import 'ui/vehicle_management_view.dart';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController, required this.hasToken,
  });

  final SettingsController settingsController;
  final bool hasToken;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          initialRoute: hasToken ? DashboardView.routeName : LoginView.routeName,
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF020617), // slate-950
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF020617),
              elevation: 0,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF0F172A), // slate-900
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)), // slate-400
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)), // slate-800
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)), // slate-800
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2), // emerald-500
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF10B981), // emerald-500
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              elevation: 4,
              insetPadding: const EdgeInsets.all(16),
            ),
          ),
          themeMode: settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return const SettingsView();
                  case VehicleManagementView.routeName:
                    return const VehicleManagementView();
                  case LoginView.routeName:
                    return const LoginView();
                  case DashboardView.routeName:
                  default:
                    return const DashboardView();
                }
              },
            );
          },
        );
      },
    );
  }
}
