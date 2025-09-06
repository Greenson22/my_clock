import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Input Formatter
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// --- VARIABEL GLOBAL & KONFIGURASI ---
const String notificationChannelId = 'my_foreground_service';
const int notificationId = 888;

// Nilai Default Baru
const String defaultTimerName = "Timer Baru";
const String defaultTimeString = "00:00:10"; // HH:MM:SS
const int defaultTotalSeconds = 10;

// --- HELPER FUNCTIONS (WAJIB DI TOP-LEVEL AGAR BISA DIAKSES BACKGROUND) ---

/// Mengubah string format "HH:MM:SS", "MM:SS", atau "SS" menjadi total detik (int).
int parseDuration(String hms) {
  try {
    final parts = hms.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    int totalSeconds = 0;
    if (parts.length == 3) {
      // Format HH:MM:SS
      totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      // Format MM:SS
      totalSeconds = parts[0] * 60 + parts[1];
    } else if (parts.length == 1) {
      // Format SS
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
  // .toString() menghasilkan format "H:MM:SS.mmmmmm". Kita perlu memformatnya:
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// -------------------------------------------------------------------
// --- LOGIKA SERVICE ( INISIALISASI DAN BACKGROUND ISOLATE) ---
// -------------------------------------------------------------------

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
      initialNotificationTitle: defaultTimerName, // Judul Notif Awal
      initialNotificationContent: 'Menunggu...', // Konten Notif Awal
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

// ENTRY POINT UNTUK BACKGROUND ISOLATE
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

  // Variabel state di dalam background service
  int hitungan = defaultTotalSeconds;
  String timerName = defaultTimerName;
  Timer? timer;

  // Dengarkan perintah 'start' dari UI
  service.on('start').listen((event) {
    timer?.cancel(); // Selalu matikan timer lama

    // Ambil data BARU (Durasi & Nama) dari UI
    final data = event as Map<String, dynamic>?;
    hitungan = data?['duration'] as int? ?? defaultTotalSeconds;
    timerName = data?['name'] as String? ?? defaultTimerName;

    if (hitungan <= 0) {
      service.invoke('update', {'count': 0});
      return;
    }

    // Mulai Timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (hitungan > 0) {
        hitungan--;
      } else {
        hitungan = 0;
        timer.cancel(); // Stop saat 0
      }

      // Format sisa waktu ke HH:MM:SS
      final String sisaWaktuFormatted = formatDuration(hitungan);

      // Update Notifikasi Foreground (WAJIB)
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            timerName, // PERUBAHAN: Gunakan Nama Timer sebagai Judul Notifikasi
            'Sisa Waktu: $sisaWaktuFormatted', // PERUBAHAN: Gunakan format HH:MM:SS
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

      // Kirim data (total detik) kembali ke UI
      service.invoke('update', {'count': hitungan});

      // Jika selesai, update notifikasi terakhir
      if (hitungan == 0) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          timerName, // Judul Notif
          'Waktu Habis!', // Konten Notif
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: false, // Selesai, notifikasi bisa di-swipe
            ),
          ),
        );
      }
    });
  });

  // Dengarkan perintah 'reset' dari UI
  service.on('reset').listen((event) {
    timer?.cancel();
    hitungan = defaultTotalSeconds; // Kembalikan detik ke default
    timerName = defaultTimerName; // Kembalikan nama ke default
    service.invoke('update', {'count': hitungan}); // Kirim update ke UI

    // Update notifikasi ke state reset
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

// ----------------------------------------------------
// --- FUNGSI MAIN DAN UI APLIKASI (FLUTTER WIDGET) ---
// ----------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request(); // Minta izin notif
  await initializeService(); // Siapkan service

  runApp(const CountdownApp());
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const CountdownPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  // State UI: Menampilkan sisa waktu dalam format string
  String _textToDisplay = formatDuration(defaultTotalSeconds);
  bool _isRunning = false;

  // Controller untuk DUA TextField baru
  final TextEditingController _nameController = TextEditingController(
    text: defaultTimerName,
  );
  final TextEditingController _timeController = TextEditingController(
    text: defaultTimeString,
  );

  @override
  void initState() {
    super.initState();
    final service = FlutterBackgroundService();

    // Pastikan service jalan dan di foreground saat app dibuka
    service.startService();
    service.invoke('setAsForeground');

    // UI mendengarkan data (sisa detik) dari service
    service.on('update').listen((data) {
      if (data != null && data.containsKey('count')) {
        int countInSeconds = data['count'] as int;
        setState(() {
          // PERUBAHAN: Format detik yang diterima sebelum ditampilkan
          _textToDisplay = formatDuration(countInSeconds);
          _isRunning = countInSeconds > 0;
        });

        // Jika hitungan selesai, reset field UI ke default
        if (countInSeconds == 0 && !_isRunning) {
          _nameController.text = defaultTimerName;
          _timeController.text = defaultTimeString;
        }
      }
    });
  }

  @override
  void dispose() {
    // Jangan lupa dispose KEDUA controller
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FlutterBackgroundService();

    return Scaffold(
      appBar: AppBar(title: const Text("Timer Service Kustom")),
      body: SingleChildScrollView(
        // Agar UI tidak error jika keyboard muncul
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                // Tampilan Angka Countdown Utama (Format HH:MM:SS)
                Text(
                  _textToDisplay,
                  style: const TextStyle(
                    fontSize: 64.0, // Ukuran font disesuaikan
                    fontFamily:
                        'monospace', // Font monospace agar angka tidak 'lompat-lompat'
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 40),

                // Input Field 1: Nama Timer
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 18),
                  enabled: !_isRunning, // Nonaktif saat timer jalan
                  decoration: InputDecoration(
                    labelText: 'Nama Timer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 20),

                // Input Field 2: Durasi
                TextField(
                  controller: _timeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  enabled: !_isRunning, // Nonaktif saat timer jalan
                  decoration: InputDecoration(
                    labelText: 'Set Durasi (JJ:MM:DD)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.datetime, // Keyboard yang sesuai
                ),
                const SizedBox(height: 30),

                // Baris Tombol Kontrol
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tombol Mulai
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _isRunning
                          ? null // Nonaktif jika sedang berjalan
                          : () {
                              // 1. Baca input dari kedua controller
                              final String name =
                                  _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : defaultTimerName;
                              final String timeString = _timeController.text;

                              // 2. Parse string waktu ke total detik
                              final int totalSeconds = parseDuration(
                                timeString,
                              );

                              // 3. Validasi (hanya mulai jika lebih dari 0)
                              if (totalSeconds > 0) {
                                // 4. Kirim KEDUA data (detik & nama) ke service
                                service.invoke('start', {
                                  'duration': totalSeconds,
                                  'name': name,
                                });
                              }
                            },
                      child: const Text('Mulai'),
                    ),
                    const SizedBox(width: 20),

                    // Tombol Reset
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        // 1. Kirim perintah 'reset' ke service
                        service.invoke('reset');
                        // 2. Perbarui field UI kembali ke nilai default
                        _nameController.text = defaultTimerName;
                        _timeController.text = defaultTimeString;
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
