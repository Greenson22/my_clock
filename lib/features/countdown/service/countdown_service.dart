import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

// --- VARIABEL GLOBAL & KONFIGURASI ---
// Semua konstanta dan helper yang perlu diakses oleh UI dan Service
// ditempatkan di sini.

const String notificationChannelId = 'my_foreground_service';
const int notificationId = 888;
const String defaultTimerName = "Timer Baru";
const String defaultTimeString = "00:00:10"; // HH:MM:SS
const int defaultTotalSeconds = 10;

/// Mengubah string format "HH:MM:SS", "MM:SS", atau "SS" menjadi total detik (int).
int parseDuration(String hms) {
  try {
    final parts = hms.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    int totalSeconds = 0;
    if (parts.length == 3) {
      totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      totalSeconds = parts[0] * 60 + parts[1];
    } else if (parts.length == 1) {
      totalSeconds = parts[0];
    }
    return totalSeconds;
  } catch (e) {
    return 0;
  }
}

/// Mengubah total detik (int) menjadi format string "HH:MM:SS".
String formatDuration(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final duration = Duration(seconds: totalSeconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// --- LOGIKA SERVICE ( INISIALISASI DAN BACKGROUND ISOLATE) ---

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Fungsi utama inisialisasi service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, // Menunjuk ke entry point background
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: defaultTimerName,
      initialNotificationContent: 'Menunggu...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

/// ENTRY POINT UNTUK BACKGROUND ISOLATE
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((event) => service.stopSelf());

  int hitungan = defaultTotalSeconds;
  String timerName = defaultTimerName;
  Timer? timer;

  service.on('start').listen((event) {
    timer?.cancel();
    final data = event as Map<String, dynamic>?;
    hitungan = data?['duration'] as int? ?? defaultTotalSeconds;
    timerName = data?['name'] as String? ?? defaultTimerName;

    if (hitungan <= 0) {
      service.invoke('update', {'count': 0});
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (hitungan > 0) {
        hitungan--;
      } else {
        hitungan = 0;
        timer.cancel();
      }

      final String sisaWaktuFormatted = formatDuration(hitungan);

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            timerName,
            'Sisa Waktu: $sisaWaktuFormatted',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'MY FOREGROUND SERVICE',
                icon: 'ic_bg_service_small',
                ongoing: true,
                autoCancel: false,
              ),
            ),
          );
        }
      }

      service.invoke('update', {'count': hitungan});

      if (hitungan == 0) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          timerName,
          'Waktu Habis!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: false,
            ),
          ),
        );
      }
    });
  });

  service.on('reset').listen((event) {
    timer?.cancel();
    hitungan = defaultTotalSeconds;
    timerName = defaultTimerName;
    service.invoke('update', {'count': hitungan});

    flutterLocalNotificationsPlugin.show(
      notificationId,
      timerName,
      'Timer di-reset ke ${formatDuration(hitungan)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small',
          ongoing: true,
        ),
      ),
    );
  });
}
