import 'package:uuid/uuid.dart';

// --- KONSTANTA ---
const String notificationChannelId = 'my_foreground_service';
const int persistentNotificationId = 888;
const String defaultTimerName = "Timer Baru";
const String defaultTimeString = "00:00:10";
const int defaultTotalSeconds = 10;
const Uuid uuid = Uuid();
const String kTimersStorageKey = "activeTimersListV2";
// [BARU] Tambahkan konstanta untuk Aksi Notifikasi
const String kStopAlarmActionId = 'STOP_ALARM_ACTION';

// [BARU] Tambahkan konstanta untuk kanal notifikasi prioritas tinggi
const String finishedTimerChannelId = 'finished_timers_channel';
const String finishedTimerChannelName = 'Notifikasi Timer Selesai';
const String finishedTimerChannelDesc =
    'Kanal untuk notifikasi saat timer berakhir.';

// --- FUNGSI HELPER ---
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

String formatDuration(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final duration = Duration(seconds: totalSeconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}
