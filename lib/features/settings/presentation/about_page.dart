// lib/features/settings/presentation/about_page.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  // Mengambil versi aplikasi dari package info
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Versi ${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final appColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.timer_outlined,
                          size: 50,
                          color: appColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Multi Timer',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manajemen Timer dan Alarm Andal Anda',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _version,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Deskripsi Aplikasi
            _buildSectionTitle(context, 'Tentang Multi Timer'),
            const SizedBox(height: 8),
            const Text(
              'Multi Timer adalah aplikasi utilitas yang dirancang untuk mengelola beberapa countdown timer dan alarm standar secara bersamaan. Aplikasi ini ideal untuk berbagai aktivitas seperti memasak, berolahraga, belajar, atau situasi apa pun yang memerlukan beberapa pengatur waktu sekaligus. Dengan layanan latar belakang (background service) yang persisten, Multi Timer memastikan semua timer Anda tetap berjalan dan berbunyi bahkan saat aplikasi ditutup atau perangkat di-restart.',
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Fitur Utama (disesuaikan dengan file aplikasi Anda)
            _buildSectionTitle(context, 'Fitur Utama'),
            const SizedBox(height: 8),
            _FeatureTile(
              icon: Icons.hourglass_empty_rounded,
              title: 'Countdown Timer Ganda',
              subtitle:
                  'Buat dan jalankan beberapa timer countdown secara bersamaan.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.alarm_outlined,
              title: 'Alarm Standar',
              subtitle:
                  'Setel alarm harian atau mingguan dengan opsi cepat dan manual.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.notifications_active_outlined,
              title: 'Layanan Latar Belakang (Service)',
              subtitle:
                  'Timer tetap berjalan akurat di latar belakang menggunakan foreground service.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.music_note_outlined,
              title: 'Suara Alarm Kustom (Timer)',
              subtitle:
                  'Pilih file audio Anda sendiri dari penyimpanan perangkat sebagai nada dering timer.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.emoji_emotions_outlined,
              title: 'Ikon Emoji Kustom',
              subtitle:
                  'Personalisasi setiap timer dengan ikon emoji unik dari keyboard atau daftar pilihan.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.drag_handle_rounded,
              title: 'Ubah Urutan (Drag & Drop)',
              subtitle:
                  'Atur ulang tata letak timer Anda dengan mudah menggunakan fitur drag-and-drop.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.dark_mode_outlined,
              title: 'Tema Terang & Gelap',
              subtitle:
                  'Beralih antara mode terang dan gelap yang mengikuti preferensi sistem.',
              appColor: appColor,
            ),

            const Divider(height: 48),

            // --- [MODIFIKASI DI SINI] ---
            // Informasi Pengembang (Diambil dari file referensi Anda)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: appColor,
                    child: const Icon(
                      // Ikon dari file referensi
                      Icons.person_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Dibuat oleh:', style: textTheme.titleMedium), //
                  const SizedBox(height: 4),
                  Text(
                    'Frendy Rikal Gerung, S.Kom.', // Nama Anda
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sarjana Komputer dari Universitas Negeri Manado', // Info dari file referensi
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // --- AKHIR MODIFIKASI ---
          ],
        ),
      ),
    );
  }

  // Helper widget dari file referensi Anda
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

// Helper widget dari file referensi Anda
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color appColor;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.appColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: appColor.withOpacity(0.8), size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}
