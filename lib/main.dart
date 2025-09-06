import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Impor logika service kita
import 'features/countdown/service/countdown_service.dart';
// Impor widget root app kita
import 'app_widget.dart';

void main() async {
  // --- INI ADALAH ENTRY POINT ---
  // Tugasnya hanya melakukan setup awal.

  // 1. Pastikan Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Minta izin yang diperlukan
  await Permission.notification.request();

  // 3. Inisialisasi background service (dari file service kita)
  await initializeService();

  // 4. Jalankan UI Aplikasi (dari file app_widget kita)
  runApp(const AppWidget());
}
