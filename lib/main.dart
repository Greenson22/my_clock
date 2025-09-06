import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// --- VARIABEL GLOBAL ---
const String notificationChannelId = 'my_foreground_service';
const int notificationId = 888;
const String initialText = "10";

// --- FUNGSI UTAMA UNTUK SERVICE INITIALIZATION ---

// 1. Inisialisasi plugin Notifikasi Lokal (diperlukan oleh service)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. Fungsi untuk inisialisasi Service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Konfigurasi Channel Notifikasi
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // deskripsi
    importance:
        Importance.low, // Ganti ke Importance.high jika Anda ingin suara
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Konfigurasi service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // Ini menjalankan fungsi onStart saat service dipanggil
      onStart: onStart,
      // Otomatis mulai service saat aplikasi startup (jika sudah pernah jalan)
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Countdown Service',
      initialNotificationContent: 'Menunggu untuk mulai...',
      foregroundServiceNotificationId: notificationId,
    ),
    // Konfigurasi iOS (saat ini kosong)
    iosConfiguration: IosConfiguration(),
  );
}

// 3. ENTRY POINT UNTUK BACKGROUND ISOLATE
// Ini adalah fungsi yang akan dijalankan di THREAD TERPISAH (Background).
// Fungsi ini TIDAK BISA mengakses variabel atau state dari UI.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Hanya diperlukan untuk plugin background (wajib ada)
  DartPluginRegistrant.ensureInitialized();

  // Pastikan service ini adalah instance Android
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

  // --- LOGIKA UTAMA COUNTDOWN ---
  int hitungan = int.tryParse(initialText) ?? 10;
  Timer? timer;

  // Dengarkan perintah 'start' dari UI
  service.on('start').listen((event) {
    // Jika timer sudah berjalan, batalkan dulu
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (hitungan > 0) {
        hitungan--;
      } else {
        hitungan = 0;
        timer.cancel(); // Hentikan timer saat mencapai 0
      }

      // Update Notifikasi Foreground (INI WAJIB)
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            'Countdown Berjalan',
            'Sisa Waktu: $hitungan detik',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                'MY FOREGROUND SERVICE',
                icon:
                    'ic_bg_service_small', // Pastikan Anda punya ikon ini di android/app/src/main/res/drawable
                ongoing: true,
              ),
            ),
          );
        }
      }

      // Kirim data (hitungan) kembali ke UI
      service.invoke('update', {'count': hitungan});

      // Jika selesai, update notifikasi
      if (hitungan == 0) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Countdown Selesai',
          'Waktu Habis!',
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
    hitungan = int.tryParse(initialText) ?? 10;
    // Kirim state reset kembali ke UI
    service.invoke('update', {'count': hitungan});
    // Update notifikasi
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Countdown Service',
      'Timer di-reset ke $hitungan',
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

// --- Fungsi Main dan UI Aplikasi ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Minta izin notifikasi (WAJIB untuk Android 13+)
  await Permission.notification.request();
  // Inisialisasi service
  await initializeService();

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
  String _textToDisplay = initialText; // Teks yang akan ditampilkan di UI
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final service = FlutterBackgroundService();

    // Mulai service saat UI dibuka
    // Kita juga periksa apakah service sudah berjalan (misal dari boot)
    service.startService();
    service.invoke('setAsForeground');

    // UI mulai "mendengarkan" data yang dikirim dari service (dari 'update')
    service.on('update').listen((data) {
      if (data != null && data.containsKey('count')) {
        setState(() {
          _textToDisplay = data['count'].toString();
          // Cek apakah sedang berjalan
          _isRunning = data['count'] > 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = FlutterBackgroundService();

    return Scaffold(
      appBar: AppBar(title: const Text("Countdown (Mode Service)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _textToDisplay,
              style: const TextStyle(
                fontSize: 120.0,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  // Tombol 'Mulai' mengirim perintah 'start' ke service
                  onPressed: _isRunning
                      ? null // Nonaktifkan jika sedang berjalan
                      : () => service.invoke('start'),
                  child: const Text('Mulai'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  // Tombol 'Reset' mengirim perintah 'reset' ke service
                  onPressed: () => service.invoke('reset'),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
