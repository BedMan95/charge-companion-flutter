import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/tuya_api.dart';
import '../db/database_helper.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground_v2', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max, // importance must be at low or higher level
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground_v2',
      initialNotificationTitle: 'Charge Companion',
      initialNotificationContent: 'Service berjalan di latar',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Background charging logic loop
  while (true) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeMs = prefs.getInt('startTimeMs');

      if (startTimeMs != null) {
        // CHARGING STATE
        final data = await TuyaApi.getDeviceStatus();
        if (data != null && data['status'] != null) {
          final statusList = data['status'] as List<dynamic>;

          final relayStatus = statusList.firstWhere(
              (s) => s['code'] == 'switch_1',
              orElse: () => {'value': false})['value'] as bool;

          final curPower = (statusList.firstWhere(
                  (s) => s['code'] == 'cur_power',
                  orElse: () => {'value': 0})['value'] as num) /
              10.0;

          if (relayStatus) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final lastFetch = prefs.getInt('lastFetchTimeMs') ?? now;
            final elapsedHours = (now - lastFetch) / (1000 * 3600);

            if (elapsedHours > 0) {
              final currentPowerKw = curPower / 1000.0;
              final energyAddedKwh = currentPowerKw * elapsedHours;

              final accumulated = (prefs.getDouble('accumulatedEnergyKWh') ?? 0.0) + energyAddedKwh;
              await prefs.setDouble('accumulatedEnergyKWh', accumulated);
              await prefs.setInt('lastFetchTimeMs', now);

              // Update power history for smoothing
              final powerHistoryStr = prefs.getString('powerHistoryKw') ?? '';
              final historyList = powerHistoryStr.isEmpty
                  ? <double>[]
                  : powerHistoryStr.split(',').map((e) => double.tryParse(e) ?? 0.0).toList();

              historyList.add(currentPowerKw);
              if (historyList.length > 10) historyList.removeAt(0);

              await prefs.setString('powerHistoryKw', historyList.join(','));
              await prefs.setDouble('smoothedPowerKw',
                historyList.isEmpty ? 0.0 : historyList.reduce((a, b) => a + b) / historyList.length);

              // Calculate new percent
              final efisiensi = prefs.getDouble('efisiensiCharger') ?? 0.82;

              // We need battery capacity. Let's try to get active vehicle first.
              double batCapacityKwh = 0.0;
              final useRealtime = prefs.getBool('useRealtime') ?? true;

              if (useRealtime) {
                final db = await DatabaseHelper.instance.database;
                final maps = await db.rawQuery('''
                  SELECT uv.*, em.battery_volt, em.battery_ah, em.efisiensi_charger
                  FROM user_vehicles uv
                  LEFT JOIN ev_models em ON uv.ev_model_id = em.id
                  WHERE uv.is_active = 1
                  LIMIT 1
                ''');
                if (maps.isNotEmpty) {
                  final map = maps.first;
                  final v = (map['custom_battery_volt'] ?? map['battery_volt'] ?? 72) as num;
                  final ah = (map['custom_battery_ah'] ?? map['battery_ah'] ?? 38) as num;
                  batCapacityKwh = (v.toDouble() * ah.toDouble()) / 1000.0;
                }
              }

              if (batCapacityKwh == 0.0) {
                // Fallback to settings
                final v = prefs.getDouble('batteryVolt') ?? 72.0;
                final ah = prefs.getDouble('batteryAh') ?? 38.0;
                batCapacityKwh = (v * ah) / 1000.0;
              }

              final energyDcCharged = accumulated * efisiensi;
              final addedPercentage = (energyDcCharged / batCapacityKwh) * 100;

              final target = prefs.getDouble('persenTarget') ?? 100.0;
              final awal = prefs.getDouble('persenAwal') ?? 0.0;
              final newPersen = (awal + addedPercentage).clamp(0.0, target);

              await prefs.setDouble('persenRealtime', newPersen);

              // Check completion condition: Target reached OR Power dropped indicating full
              if (curPower > 0 && curPower < 50.0) {
                int lowPowerCount = prefs.getInt('lowPowerCount') ?? 0;
                lowPowerCount++;
                await prefs.setInt('lowPowerCount', lowPowerCount);
              } else {
                await prefs.setInt('lowPowerCount', 0);
              }

              final lowPowerCount = prefs.getInt('lowPowerCount') ?? 0;
              // 4 consecutive reads at 30s interval = 2 minutes
              final isTrickleFinished = lowPowerCount >= 4;

              if (newPersen >= target && isTrickleFinished) {
                // Charge Complete!
                await TuyaApi.sendCommand([{'code': 'switch_1', 'value': false}]);
                await prefs.remove('startTimeMs');
                await prefs.remove('lastFetchTimeMs');
                await prefs.remove('hasNotifiedLowPower');
                await prefs.remove('lowPowerCount');

                flutterLocalNotificationsPlugin.show(
                  999,
                  '✅ Pengisian Selesai',
                  isTrickleFinished
                      ? 'Daya stabil di bawah 50W selama 2 menit (Baterai Penuh).'
                      : 'Baterai telah mencapai target.',
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'my_foreground_v2',
                      'MY FOREGROUND SERVICE',
                      icon: 'ic_bg_service_small',
                      importance: Importance.max,
                      priority: Priority.high,
                      playSound: true,
                    ),
                  ),
                );
              } else if (elapsedHours > 0.01 && curPower > 0 && curPower < 300.0) {
                // Notifikasi daya di bawah 300W (hanya sekali per sesi)
                final hasNotified = prefs.getBool('hasNotifiedLowPower') ?? false;
                if (!hasNotified) {
                  flutterLocalNotificationsPlugin.show(
                    998,
                    '⚠️ Fase Tapering',
                    'Daya pengisian menurun di bawah 300 Watt (${curPower.toStringAsFixed(0)}W).',
                    const NotificationDetails(
                      android: AndroidNotificationDetails(
                        'my_foreground_v2',
                        'MY FOREGROUND SERVICE',
                        icon: 'ic_bg_service_small',
                        importance: Importance.defaultImportance,
                        priority: Priority.defaultPriority,
                        playSound: true,
                      ),
                    ),
                  );
                  await prefs.setBool('hasNotifiedLowPower', true);
                }
              }
            }
          }
        }

        // When charging, loop every 5 seconds for more responsive UI
        await Future.delayed(const Duration(seconds: 5));
      } else {
        // Not charging, relax loop to 5 minutes
        await Future.delayed(const Duration(minutes: 5));
      }
    } catch (e) {
      debugPrint('Background loop error: $e');
      // If error, wait 5 seconds before retry to prevent spam
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
