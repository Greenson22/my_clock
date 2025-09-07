import 'dart:ui'; // [MODIFIKASI BARU] Tambahkan impor ini
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [MODIFIKASI BARU] Tambahkan impor ini

import 'features/countdown/service/countdown_service.dart';
import 'features/alarm/service/alarm_service.dart';
import 'app_widget.dart';
import 'features/settings/application/theme_provider.dart';
import 'features/countdown/service/countdown_utils.dart';

// [MODIFIKASI UTAMA DI SINI]
// Kita ubah fungsi ini untuk menggunakan SharedPreferences
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) async {
  // Hanya proses jika ID aksinya sesuai
  if (response.actionId == kStopAlarmActionId) {
    // Saat aplikasi ditutup, callback ini berjalan di isolatnya sendiri.
    // Kita HARUS menginisialisasi plugin yang diperlukan di sini secara manual.
    DartPluginRegistrant.ensureInitialized();

    // Alih-alih service.invoke(), kita gunakan SharedPreferences sebagai "papan pesan"
    // yang dapat dibaca oleh background service yang sedang berjalan.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('STOP_ALARM_VIA_NOTIFICATION_FLAG', true);
  }
}
// --- AKHIR BLOK MODIFIKASI ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_bg_service_small');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Inisialisasi plugin dan teruskan callback top-level yang sudah diperbarui
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  await initializeService();
  await AlarmService().loadAlarms();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AppWidget(),
    ),
  );
}
