import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/theme_provider.dart';
// [BARU] Impor halaman 'About' yang baru saja kita buat
// (Asumsi Anda menyimpannya di folder yang sama)
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- Logika Mode Gelap (Tetap sama) ---
    final ThemeMode currentMode = themeProvider.themeMode;
    final Brightness platformBrightness = MediaQuery.of(
      context,
    ).platformBrightness;
    final bool isEffectivelyDark =
        (currentMode == ThemeMode.dark) ||
        (currentMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    // --- Akhir Logika Mode Gelap ---

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Opsi Mode Gelap yang sudah ada
          ListTile(
            title: const Text('Mode Gelap'),
            trailing: Switch(
              value: isEffectivelyDark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),

          // [BARU] Tambahkan ListTile untuk navigasi ke Halaman 'About'
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () {
              // Navigasi ke halaman AboutPage saat diketuk
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
