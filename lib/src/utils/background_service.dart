import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

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
      initialNotificationTitle: '',
      initialNotificationContent: '',
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

  // Listen to ntfy.sh SSE
  final client = http.Client();
  final request = http.Request('GET', Uri.parse('https://notify.nusantarajaya.co.id/dk_charge_companion_app_yadea/sse'));
  
  try {
    final response = await client.send(request);
    response.stream.transform(utf8.decoder).listen((data) {
      debugPrint('SSE Data received: $data');
      if (data.isNotEmpty) {
        try {
          final lines = data.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              final jsonData = jsonDecode(jsonStr);
              
              if (jsonData['event'] == 'message') {
                List<dynamic> tags = jsonData['tags'] ?? [];
                String emojiPrefix = '';
                for (var tag in tags) {
                  if (tag == 'warning') emojiPrefix += '⚠️ ';
                  if (tag == 'skull') emojiPrefix += '💀 ';
                  if (tag == 'battery') emojiPrefix += '🔋 ';
                  if (tag == 'zap') emojiPrefix += '⚡ ';
                  if (tag == 'white_check_mark') emojiPrefix += '✅ ';
                  if (tag == 'x') emojiPrefix += '❌ ';
                }

                final title = emojiPrefix + (jsonData['title'] ?? 'New Notification');
                final message = jsonData['message'] ?? '';
                
                List<AndroidNotificationAction> actions = [];
                if (jsonData['actions'] != null) {
                  for (var action in jsonData['actions']) {
                    if (action['action'] == 'http') {
                      actions.add(AndroidNotificationAction(
                        action['id'] ?? action['label'],
                        action['label'],
                        showsUserInterface: true,
                      ));
                    }
                  }
                }

                flutterLocalNotificationsPlugin.show(
                  DateTime.now().millisecond,
                  title,
                  message,
                  NotificationDetails(
                    android: AndroidNotificationDetails(
                      'my_foreground_v2',
                      'MY FOREGROUND SERVICE',
                      icon: 'ic_bg_service_small',
                      ongoing: false,
                      importance: Importance.max,
                      priority: Priority.high,
                      playSound: true,
                      sound: const RawResourceAndroidNotificationSound('notification_sound'),
                      channelShowBadge: true,
                      enableVibration: true,
                      actions: actions.isNotEmpty ? actions : null,
                    ),
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing SSE data: $e');
        }
      }
    });
  } catch (e) {
    debugPrint('Error connecting to SSE: $e');
  }
}
