import 'package:flutter/material.dart';
// Hapus impor CountdownPage
// import 'features/countdown/presentation/countdown_page.dart';
// Impor DashboardPage yang baru
import 'features/dashboard/presentation/dashboard_page.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      themeMode: ThemeMode.system, // Mengikuti tema sistem
      // Ubah home dari CountdownPage ke DashboardPage
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
