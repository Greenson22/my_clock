import 'package:flutter/material.dart';
import 'features/countdown/presentation/countdown_page.dart';

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
      home: const CountdownPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
