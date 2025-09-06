import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// --- KONSTANTA --- (Tidak ada perubahan)
const String notificationChannelId = 'my_foreground_service';
const int persistentNotificationId = 888;
const String defaultTimerName = "Timer Baru";
const String defaultTimeString = "00:00:10";
const int defaultTotalSeconds = 10;
const Uuid uuid = Uuid();
const String kTimersStorageKey = "activeTimersListV2";

// --- DATA MODEL ---
class CountdownTimer {
  final String id;
  String name; // <-- [PERUBAHAN] Hapus keyword 'final'
  final int initialDurationSeconds;
  int remainingSeconds;
  bool isPaused;
  bool isDone;

  CountdownTimer({
    required this.id,
    required this.name, // <-- Tidak perlu diubah di sini
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    this.isPaused = false,
    this.isDone = false,
  });

  // Metode toJson dan fromJson tidak perlu diubah
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initialDurationSeconds': initialDurationSeconds,
    'remainingSeconds': remainingSeconds,
    'isPaused': isPaused,
    'isDone': isDone,
  };

  factory CountdownTimer.fromJson(Map<String, dynamic> json) => CountdownTimer(
    id: json['id'] as String,
    name: json['name'] as String,
    initialDurationSeconds: json['initialDurationSeconds'] as int,
    remainingSeconds: json['remainingSeconds'] as int,
    isPaused: json['isPaused'] as bool? ?? false,
    isDone: json['isDone'] as bool? ?? false,
  );
}

// --- FUNGSI HELPER & INISIALISASI --- (Tidak ada perubahan)
// ... (semua fungsi parseDuration, formatDuration, initializeService, save/load TimersToDisk tetap sama)
// --- (Saya singkat agar fokus pada perubahan) ---

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
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Layanan Timer Aktif',
      initialNotificationContent: 'Memuat timer...',
      foregroundServiceNotificationId: persistentNotificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

Future<void> saveTimersToDisk(List<CountdownTimer> timers) async {
  final prefs = await SharedPreferences.getInstance();
  final List<Map<String, dynamic>> timerJsonList = timers
      .map((t) => t.toJson())
      .toList();
  final String jsonString = jsonEncode(timerJsonList);
  await prefs.setString(kTimersStorageKey, jsonString);
}

Future<List<CountdownTimer>> loadTimersFromDisk() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString(kTimersStorageKey);
  if (data == null) return [];

  try {
    final List<dynamic> decodedList = jsonDecode(data) as List;
    return decodedList
        .map((item) => CountdownTimer.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
}

// ENTRY POINT UTAMA SERVICE
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  List<CountdownTimer> activeTimers = [];
  Timer? globalTicker;

  // ... (Fungsi onTick dan startGlobalTickerIfNeeded tidak ada perubahan) ...
  void onTick(Timer timer) async {
    bool stateChanged = false;
    String notificationBodySummary = "";

    for (final timer in activeTimers) {
      if (!timer.isPaused && !timer.isDone) {
        timer.remainingSeconds--;
        stateChanged = true;

        if (timer.remainingSeconds <= 0) {
          timer.remainingSeconds = 0;
          timer.isDone = true;
          timer.isPaused = true;

          flutterLocalNotificationsPlugin.show(
            timer.id.hashCode,
            'Timer Selesai!',
            'Timer Anda "${timer.name}" telah berakhir.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'MY FOREGROUND SERVICE',
                importance: Importance.high,
                priority: Priority.high,
                ongoing: false,
              ),
            ),
          );
        }
      }
      final status = timer.isDone
          ? "[Selesai]"
          : (timer.isPaused ? "[Paused]" : "");
      notificationBodySummary +=
          "${timer.name}: ${formatDuration(timer.remainingSeconds)} $status\n";
    }

    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });

    int runningCount = activeTimers
        .where((t) => !t.isPaused && !t.isDone)
        .length;
    String title = runningCount > 0
        ? "$runningCount Timer Berjalan"
        : "Semua Timer Dijeda";
    if (activeTimers.isEmpty) title = "Layanan Timer Aktif";

    String content = activeTimers.isEmpty
        ? "Tidak ada timer berjalan."
        : notificationBodySummary.trim();

    flutterLocalNotificationsPlugin.show(
      persistentNotificationId,
      title,
      content,
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'MY FOREGROUND SERVICE',
          icon: 'ic_bg_service_small',
          ongoing: true,
          autoCancel: false,
          styleInformation: BigTextStyleInformation(content),
        ),
      ),
    );

    if (stateChanged) {
      await saveTimersToDisk(activeTimers);
    }

    bool allPausedOrDone = activeTimers.every((t) => t.isPaused || t.isDone);
    if (activeTimers.isEmpty || allPausedOrDone) {
      globalTicker?.cancel();
      globalTicker = null;
    }
  }

  void startGlobalTickerIfNeeded() {
    if (globalTicker == null || !globalTicker!.isActive) {
      globalTicker = Timer.periodic(const Duration(seconds: 1), onTick);
    }
  }

  // --- SAAT SERVICE STARTUP --- (Tidak ada perubahan)
  activeTimers = await loadTimersFromDisk();
  service.invoke('updateTimers', {
    'timers': activeTimers.map((t) => t.toJson()).toList(),
  });
  if (activeTimers.any((t) => !t.isPaused && !t.isDone)) {
    startGlobalTickerIfNeeded();
  }

  // --- Event Listeners ---
  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((event) => service.stopSelf());

  // ... (Listener addTimer, removeTimer, clearAll, pause, resume, reset tetap sama) ...
  service.on('addTimer').listen((data) async {
    if (data == null) return;
    final int duration = data['duration'] as int? ?? defaultTotalSeconds;

    final newTimer = CountdownTimer(
      id: uuid.v4(),
      name: data['name'] as String? ?? defaultTimerName,
      initialDurationSeconds: duration,
      remainingSeconds: duration,
      isPaused: false,
      isDone: false,
    );

    activeTimers.add(newTimer);
    await saveTimersToDisk(activeTimers);
    startGlobalTickerIfNeeded();
  });

  service.on('removeTimer').listen((data) async {
    if (data == null) return;
    final String idToRemove = data['id'] as String;
    activeTimers.removeWhere((timer) => timer.id == idToRemove);
    await saveTimersToDisk(activeTimers);
  });

  service.on('clearAll').listen((event) async {
    activeTimers.clear();
    globalTicker?.cancel();
    globalTicker = null;
    await saveTimersToDisk(activeTimers);
    service.invoke('updateTimers', {'timers': []});
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

  service.on('pauseTimer').listen((data) async {
    if (data == null) return;
    final timer = activeTimers.firstWhere((t) => t.id == data['id']);
    timer.isPaused = true;
    await saveTimersToDisk(activeTimers);
  });

  service.on('resumeTimer').listen((data) async {
    if (data == null) return;
    final timer = activeTimers.firstWhere((t) => t.id == data['id']);
    timer.isPaused = false;
    timer.isDone = false;
    await saveTimersToDisk(activeTimers);
    startGlobalTickerIfNeeded();
  });

  service.on('resetTimer').listen((data) async {
    if (data == null) return;
    final timer = activeTimers.firstWhere((t) => t.id == data['id']);
    timer.remainingSeconds = timer.initialDurationSeconds;
    timer.isPaused = true;
    timer.isDone = false;
    await saveTimersToDisk(activeTimers);
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });
  });

  // [BARU] Tambahkan listener untuk mengubah nama timer
  service.on('updateTimerName').listen((data) async {
    if (data == null) return;
    final String id = data['id'] as String;
    final String newName = data['name'] as String;

    try {
      final timerToUpdate = activeTimers.firstWhere((t) => t.id == id);
      timerToUpdate.name = newName;
      await saveTimersToDisk(activeTimers);

      // Kirim update manual agar UI segera refresh jika ticker sedang tidak jalan
      service.invoke('updateTimers', {
        'timers': activeTimers.map((t) => t.toJson()).toList(),
      });
    } catch (e) {
      // Timer tidak ditemukan, abaikan
    }
  });
}
