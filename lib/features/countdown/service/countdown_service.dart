import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:uuid/uuid.dart'; // Impor paket UUID

// --- KONSTANTA (Sama seperti sebelumnya) ---
const String notificationChannelId = 'my_foreground_service';
const int persistentNotificationId = 888; // Notifikasi service yg persisten
const String defaultTimerName = "Timer Baru";
const String defaultTimeString = "00:00:10";
const int defaultTotalSeconds = 10;
const Uuid uuid = Uuid();

// --- DATA MODEL ---
// Kita butuh class untuk merepresentasikan setiap timer
class CountdownTimer {
  final String id;
  final String name;
  int remainingSeconds;

  CountdownTimer({
    required this.id,
    required this.name,
    required this.remainingSeconds,
  });

  // Metode untuk mengirim data antar isolate (wajib ada)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'remainingSeconds': remainingSeconds,
  };

  factory CountdownTimer.fromJson(Map<String, dynamic> json) => CountdownTimer(
    id: json['id'],
    name: json['name'],
    remainingSeconds: json['remainingSeconds'],
  );
}

// --- FUNGSI HELPER (Sama seperti sebelumnya) ---

int parseDuration(String hms) {
  try {
    final parts = hms.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    int totalSeconds = 0;
    if (parts.length == 3)
      totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2];
    else if (parts.length == 2)
      totalSeconds = parts[0] * 60 + parts[1];
    else if (parts.length == 1)
      totalSeconds = parts[0];
    return totalSeconds;
  } catch (e) {
    return 0;
  }
}

String formatDuration(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final duration = Duration(seconds: totalSeconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// --- INISIALISASI SERVICE (Sama seperti sebelumnya) ---

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Layanan Timer Aktif',
      initialNotificationContent: 'Tidak ada timer berjalan.',
      foregroundServiceNotificationId: persistentNotificationId,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// ------------------------------------------------------------------
// --- LOGIKA UTAMA BACKGROUND ISOLATE (ROMBAKAN TOTAL) ---
// ------------------------------------------------------------------

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Variabel state di dalam background service
  List<CountdownTimer> activeTimers = []; // Ini adalah List of Timers kita
  Timer? globalTicker; // Ini adalah SATU-SATUNYA Ticker

  // Fungsi yang dipanggil setiap 1 detik oleh Ticker
  void onTick(Timer timer) {
    if (activeTimers.isEmpty) {
      // Jika tidak ada timer lagi, matikan ticker global untuk hemat baterai
      globalTicker?.cancel();
      globalTicker = null;
      return;
    }

    String notificationBodySummary = ""; // Untuk notifikasi persisten

    // Loop mundur agar kita bisa menghapus item dari list dengan aman
    for (int i = activeTimers.length - 1; i >= 0; i--) {
      final timer = activeTimers[i];
      timer.remainingSeconds--;

      // Tambahkan ke ringkasan notifikasi
      notificationBodySummary +=
          "${timer.name}: ${formatDuration(timer.remainingSeconds)}\n";

      if (timer.remainingSeconds <= 0) {
        // TIMER SELESAI!

        // 1. Tampilkan notifikasi BARU (non-persisten) bahwa timer ini selesai
        // Kita gunakan hashcode ID sebagai ID Notifikasi unik
        flutterLocalNotificationsPlugin.show(
          timer.id.hashCode,
          'Timer Selesai!',
          'Timer Anda "${timer.name}" telah berakhir.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              importance: Importance.high, // Penting agar berbunyi
              priority: Priority.high,
              ongoing: false,
            ),
          ),
        );

        // 2. Hapus dari list aktif
        activeTimers.removeAt(i);
      }
    }

    // UPDATE UI: Kirim seluruh list timer yang sudah diupdate ke UI
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });

    // UPDATE NOTIFIKASI PERSISTEN: Tampilkan ringkasan semua timer yg berjalan
    String title = activeTimers.isEmpty
        ? "Layanan Timer Aktif"
        : "${activeTimers.length} Timer Berjalan";

    String content = activeTimers.isEmpty
        ? "Tidak ada timer berjalan."
        : notificationBodySummary.trim(); // Ringkasan timer

    flutterLocalNotificationsPlugin.show(
      persistentNotificationId, // ID Notif Persisten (selalu 888)
      title,
      content,
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small',
          ongoing: true,
          autoCancel: false,
          styleInformation: BigTextStyleInformation(
            content,
          ), // Agar bisa tampil banyak baris
        ),
      ),
    );
  }

  // Fungsi untuk memulai ticker global HANYA JIKA belum berjalan
  void startGlobalTickerIfNeeded() {
    if (globalTicker == null || !globalTicker!.isActive) {
      globalTicker = Timer.periodic(const Duration(seconds: 1), onTick);
    }
  }

  // --- Event Listeners (Perintah dari UI) ---

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((event) => service.stopSelf());

  // PERINTAH BARU: Tambah Timer
  service.on('addTimer').listen((data) {
    if (data == null) return;

    final newTimer = CountdownTimer(
      id: uuid.v4(), // Buat ID unik
      name: data['name'] as String? ?? defaultTimerName,
      remainingSeconds: data['duration'] as int? ?? defaultTotalSeconds,
    );

    activeTimers.add(newTimer);
    startGlobalTickerIfNeeded(); // Mulai ticker (jika belum jalan)
  });

  // PERINTAH BARU: Hapus Timer Spesifik
  service.on('removeTimer').listen((data) {
    if (data == null) return;
    final String idToRemove = data['id'] as String;
    activeTimers.removeWhere((timer) => timer.id == idToRemove);
    // Ticker akan otomatis stop sendiri di 'onTick' jika list-nya jadi kosong
  });

  // PERINTAH BARU: Hapus Semua Timer
  service.on('clearAll').listen((event) {
    activeTimers.clear();
    globalTicker?.cancel();
    globalTicker = null;

    // Kirim update list kosong ke UI
    service.invoke('updateTimers', {'timers': []});

    // Reset notifikasi persisten
    flutterLocalNotificationsPlugin.show(
      persistentNotificationId,
      "Layanan Timer Aktif",
      "Tidak ada timer berjalan.",
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
  });
}
