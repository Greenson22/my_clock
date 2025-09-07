import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- PERBAIKAN LOGIKA DIMULAI DI SINI ---

    // 1. Dapatkan mode tema saat ini dari provider
    final ThemeMode currentMode = themeProvider.themeMode;

    // 2. Dapatkan pengaturan brightness dari sistem perangkat (via context)
    final Brightness platformBrightness = MediaQuery.of(
      context,
    ).platformBrightness;

    // 3. Tentukan apakah UI secara efektif sedang gelap
    // Ini benar jika:
    //    a) Mode di-set manual ke Dark
    //    ATAU
    //    b) Mode di-set ke System DAN sistem saat ini sedang Dark.
    final bool isEffectivelyDark =
        (currentMode == ThemeMode.dark) ||
        (currentMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);

    // --- AKHIR PERBAIKAN LOGIKA ---

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Mode Gelap'),
            trailing: Switch(
              // 4. Gunakan nilai boolean baru yang sudah kita hitung
              value: isEffectivelyDark,
              onChanged: (value) {
                // Fungsi toggleTheme sudah benar (mengatur ke Light atau Dark)
                themeProvider.toggleTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
