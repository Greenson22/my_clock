import 'package:flutter/material.dart';
import 'features/countdown/presentation/countdown_page.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'monospace', // Set font default jika ingin konsisten
      ),
      home: const CountdownPage(), // Halaman utama kita
      debugShowCheckedModeBanner: false,
    );
  }
}
