// lib/features/countdown/service/countdown_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'background_handler.dart';
import 'countdown_utils.dart'; // <-- Pastikan ini diimpor

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // [MODIFIKASI] Buat dua kanal notifikasi

  // 1. Kanal untuk Foreground Service (Prioritas Rendah, tanpa suara & pop-up)
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    notificationChannelId, // 'my_foreground_service'
    'Layanan Timer Berjalan', // Nama baru yang lebih deskriptif
    description: 'Menampilkan timer yang sedang aktif di latar belakang.',
    importance:
        Importance.low, // Prioritas rendah agar tidak muncul sebagai heads-up
  );

  // 2. Kanal untuk Timer Selesai (Prioritas Tinggi, dengan suara & pop-up)
  const AndroidNotificationChannel finishedTimerChannel =
      AndroidNotificationChannel(
        finishedTimerChannelId, // ID kanal baru
        finishedTimerChannelName, // Nama kanal baru
        description: finishedTimerChannelDesc, // Deskripsi kanal baru
        importance:
            Importance.high, // Prioritas tinggi agar muncul sebagai heads-up
      );

  final plugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // Daftarkan kedua kanal ke sistem
  await plugin?.createNotificationChannel(serviceChannel);
  await plugin?.createNotificationChannel(finishedTimerChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      // Layanan utama tetap berjalan di kanal prioritas rendah
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Layanan Timer Aktif',
      initialNotificationContent: 'Memuat timer...',
      foregroundServiceNotificationId: persistentNotificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}
