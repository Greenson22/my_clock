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

// Fungsi untuk menyimpan dan memuat state
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

          flutterLocalNotificationsPlugin.show(
            timer.id.hashCode,
            'Timer Selesai!',
            'Timer Anda "${timer.name}" telah berakhir.',
            const NotificationDetails(
              // [PERBAIKAN] Ganti 'AndroidDetails' menjadi 'AndroidNotificationDetails'
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

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          persistentNotificationId,
          title,
          content,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
              styleInformation: BigTextStyleInformation(''),
            ),
          ),
        );
      }
    }

    if (stateChanged) await saveTimersToDisk(activeTimers);
    if (activeTimers.every((t) => t.isPaused || t.isDone)) {
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
  });
  service.on('requestInitialTimers').listen((event) {
    service.invoke('updateTimers', {
      'timers': activeTimers.map((t) => t.toJson()).toList(),
    });
  });

  service.on('addTimer').listen((data) async {
    if (data == null) return;
    final newTimer = CountdownTimer(
      id: uuid.v4(),
      name: data['name'] as String? ?? defaultTimerName,
      initialDurationSeconds: data['duration'] as int? ?? defaultTotalSeconds,
      remainingSeconds: data['duration'] as int? ?? defaultTotalSeconds,
      isPaused: true,
      alarmSound: data['alarmSound'] as String?,
      iconCodePoint: data['iconCodePoint'] as int?,
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
  });

  service.on('clearAll').listen((event) async {
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
}
