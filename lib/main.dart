import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'features/countdown/service/countdown_service.dart';
import 'app_widget.dart';
import 'features/settings/application/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  await initializeService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AppWidget(),
    ),
  );
}
