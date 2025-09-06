import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/settings/application/theme_provider.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      themeMode: themeProvider.themeMode, // Menggunakan themeMode dari provider
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
