import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:just_audio/just_audio.dart';

import 'countdown_model.dart';
import 'countdown_utils.dart';

// Fungsi penyimpanan (tetap sama)
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

  final audioPlayer = AudioPlayer();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<CountdownTimer> activeTimers = [];
  Timer? globalTicker;

  void onTick(Timer timer) async {
    // [MODIFIKASI 1: TAMBAHKAN BLOK INI DI PALING ATAS onTick]
    // Ini adalah "listener" baru kita. Ia memeriksa SharedPreferences setiap detik.
    final prefs = await SharedPreferences.getInstance();
    final bool stopAlarmFlag =
        prefs.getBool('STOP_ALARM_VIA_NOTIFICATION_FLAG') ?? false;

    if (stopAlarmFlag) {
      audioPlayer.stop();
      FlutterRingtonePlayer().stop();

      // Hapus flag-nya agar tidak dieksekusi lagi
      await prefs.setBool('STOP_ALARM_VIA_NOTIFICATION_FLAG', false);

      // Karena kita sudah menghentikan audio, kita juga harus menghapus
      // semua notifikasi "selesai" yang mungkin masih aktif.
      for (final timer in activeTimers) {
        if (timer.isDone) {
          flutterLocalNotificationsPlugin.cancel(timer.id.hashCode);
        }
      }
    }
    // --- AKHIR BLOK MODIFIKASI 1 ---

    bool stateChanged = false;
    for (final timer in activeTimers) {
      if (!timer.isPaused && !timer.isDone) {
        timer.remainingSeconds--;
        stateChanged = true;

        if (timer.remainingSeconds <= 0) {
          timer.remainingSeconds = 0;
          timer.isDone = true;
          timer.isPaused = true;

          // ... (logika memutar audio tetap sama) ...
          if (timer.alarmSound != null && timer.alarmSound!.isNotEmpty) {
            try {
              await audioPlayer.setFilePath(timer.alarmSound!);
              audioPlayer.setLoopMode(LoopMode.one);
              audioPlayer.play();
            } catch (e) {
              FlutterRingtonePlayer().playAlarm(looping: true);
            }
          } else {
            FlutterRingtonePlayer().playAlarm(looping: true);
          }

          // ... (logika menampilkan notifikasi tetap sama) ...
          flutterLocalNotificationsPlugin.show(
            timer.id.hashCode,
            'Timer Selesai!',
            'Timer Anda "${timer.name}" telah berakhir.',
            NotificationDetails(
              android: AndroidNotificationDetails(
                finishedTimerChannelId,
                finishedTimerChannelName,
                importance: Importance.high,
                priority: Priority.high,
                ongoing: false,
                autoCancel: true,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    kStopAlarmActionId,
                    'Matikan Alarm',
                    cancelNotification: false,
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    // Mengirim pembaruan ke UI
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });

    // ... (logika notifikasi foreground service tetap sama) ...
    final runningTimers = activeTimers
        .where((t) => !t.isPaused && !t.isDone)
        .toList();
    final int runningCount = runningTimers.length;
    String title;
    String content;
    if (runningCount > 0) {
      title = "$runningCount Timer Berjalan";
      content = runningTimers
          .map((t) => "${t.name}: ${formatDuration(t.remainingSeconds)}")
          .join('\n');
    } else if (activeTimers.isNotEmpty) {
      title = "Semua Timer Dijeda";
      content = "Jalankan timer untuk melihat progres di sini.";
    } else {
      title = "Layanan Timer Aktif";
      content = "Tambahkan timer baru untuk memulai.";
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          persistentNotificationId,
          title,
          content,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Layanan Timer Berjalan',
              icon: 'ic_bg_service_small',
              ongoing: true,
              styleInformation: BigTextStyleInformation(''),
            ),
          ),
        );
      }
    }

    if (stateChanged) await saveTimersToDisk(activeTimers);

    // [PERBAIKAN DI SINI]
    // Ticker harus tetap berjalan jika ada timer yang 'isDone' (sedang berdering),
    // agar bisa mendengarkan event 'stopAlarmFlag' dari notifikasi.
    // Ticker hanya boleh berhenti jika daftar timer kosong ATAU
    // semua timer secara eksplisit 'isPaused' (dan tidak 'isDone').
    if (activeTimers.isEmpty ||
        activeTimers.every((t) => t.isPaused && !t.isDone)) {
      globalTicker?.cancel();
      globalTicker = null;
    }
  }

  void startGlobalTickerIfNeeded() {
    if (globalTicker == null || !globalTicker!.isActive) {
      globalTicker = Timer.periodic(const Duration(seconds: 1), onTick);
    }
  }

  activeTimers = await loadTimersFromDisk();
  service.invoke('updateTimers', {
    'timers': activeTimers.map((t) => t.toJson()).toList(),
  });
  if (activeTimers.any((t) => !t.isPaused && !t.isDone)) {
    startGlobalTickerIfNeeded();
  }

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((event) => service.stopSelf());

  service.on('stopAlarm').listen((event) {
    audioPlayer.stop();
    FlutterRingtonePlayer().stop();
    for (final timer in activeTimers) {
      if (timer.isDone) {
        flutterLocalNotificationsPlugin.cancel(timer.id.hashCode);
      }
    }
  });

  // [MODIFIKASI 2: HAPUS LISTENER INI]
  // Listener ini tidak akan pernah menerima apa pun saat aplikasi ditutup.
  /*
  service.on('stopAlarmFromNotification').listen((data) {
    // ... KODE INI DIHAPUS ...
  });
  */
  // --- AKHIR BLOK MODIFIKASI 2 ---

  service.on('requestInitialTimers').listen((event) {
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });
  });

  // ... (SISA SEMUA LISTENER ANDA TETAP SAMA) ...
  // 'addTimer', 'removeTimer', 'clearAll', 'pauseTimer', 'resumeTimer',
  // 'resetTimer', 'updateTimerIcon', 'updateTimerName', 'updateTimerDuration',
  // 'reorderTimers' ... semua kode ini biarkan seperti apa adanya.

  service.on('addTimer').listen((data) async {
    if (data == null) return;
    final newTimer = CountdownTimer(
      id: uuid.v4(),
      name: data['name'] as String? ?? defaultTimerName,
      initialDurationSeconds: data['duration'] as int? ?? defaultTotalSeconds,
      remainingSeconds: data['duration'] as int? ?? defaultTotalSeconds,
      isPaused: true,
      alarmSound: data['alarmSound'] as String?,
      iconChar: data['iconChar'] as String?,
    );
    activeTimers.add(newTimer);
    await saveTimersToDisk(activeTimers);
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });
  });

  service.on('removeTimer').listen((data) async {
    if (data == null) return;
    activeTimers.removeWhere((timer) => timer.id == data['id'] as String);
    await saveTimersToDisk(activeTimers);
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });
    flutterLocalNotificationsPlugin.cancel(data['id'].hashCode);
  });

  service.on('clearAll').listen((event) async {
    for (final timer in activeTimers) {
      flutterLocalNotificationsPlugin.cancel(timer.id.hashCode);
    }
    activeTimers.clear();
    globalTicker?.cancel();
    globalTicker = null;
    await saveTimersToDisk(activeTimers);
    service.invoke('updateTimers', {'timers': []});
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
    audioPlayer.stop();
    FlutterRingtonePlayer().stop();
    flutterLocalNotificationsPlugin.cancel(timer.id.hashCode);
  });

  service.on('updateTimerIcon').listen((data) async {
    if (data == null) return;
    try {
      final timerToUpdate = activeTimers.firstWhere((t) => t.id == data['id']);
      timerToUpdate.iconChar = data['iconChar'] as String?;
      await saveTimersToDisk(activeTimers);
      service.invoke('updateTimers', {
        'timers': activeTimers.map((t) => t.toJson()).toList(),
      });
    } catch (e) {
      // Timer tidak ditemukan
    }
  });

  service.on('updateTimerName').listen((data) async {
    if (data == null) return;
    try {
      final timerToUpdate = activeTimers.firstWhere((t) => t.id == data['id']);
      timerToUpdate.name = data['name'];
      await saveTimersToDisk(activeTimers);
      service.invoke('updateTimers', {
        'timers': activeTimers.map((t) => t.toJson()).toList(),
      });
    } catch (e) {
      // Timer tidak ditemukan
    }
  });

  service.on('updateTimerDuration').listen((data) async {
    if (data == null) return;
    try {
      final timerToUpdate = activeTimers.firstWhere((t) => t.id == data['id']);
      final newDuration = data['duration'] as int;

      timerToUpdate.initialDurationSeconds = newDuration;
      timerToUpdate.remainingSeconds = newDuration;
      timerToUpdate.isPaused = true;
      timerToUpdate.isDone = false;

      await saveTimersToDisk(activeTimers);
      service.invoke('updateTimers', {
        'timers': activeTimers.map((t) => t.toJson()).toList(),
      });
      flutterLocalNotificationsPlugin.cancel(timerToUpdate.id.hashCode);
    } catch (e) {
      // Timer tidak ditemukan
    }
  });

  service.on('reorderTimers').listen((data) async {
    if (data == null || data['timers'] == null) return;
    final List timerDataList = data['timers'] as List;
    activeTimers = timerDataList
        .map(
          (timerJson) =>
              CountdownTimer.fromJson(timerJson as Map<String, dynamic>),
        )
        .toList();
    await saveTimersToDisk(activeTimers);
  });
}
