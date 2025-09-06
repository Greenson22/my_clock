import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// Impor file service kita untuk mengakses helper dan konstanta
import '../service/countdown_service.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  String _textToDisplay = formatDuration(defaultTotalSeconds);
  bool _isRunning = false;

  final TextEditingController _nameController = TextEditingController(
    text: defaultTimerName,
  );
  final TextEditingController _timeController = TextEditingController(
    text: defaultTimeString,
  );

  @override
  void initState() {
    super.initState();
    final service = FlutterBackgroundService();

    service.startService();
    service.invoke('setAsForeground');

    service.on('update').listen((data) {
      if (data != null && data.containsKey('count')) {
        int countInSeconds = data['count'] as int;
        setState(() {
          _textToDisplay = formatDuration(countInSeconds); // Gunakan helper
          _isRunning = countInSeconds > 0;
        });

        if (countInSeconds == 0 && !_isRunning) {
          _nameController.text = defaultTimerName;
          _timeController.text = defaultTimeString;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FlutterBackgroundService();

    return Scaffold(
      appBar: AppBar(title: const Text("Timer Service Kustom")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                Text(
                  _textToDisplay,
                  style: const TextStyle(
                    fontSize: 64.0,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 18),
                  enabled: !_isRunning,
                  decoration: InputDecoration(
                    labelText: 'Nama Timer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _timeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  enabled: !_isRunning,
                  decoration: InputDecoration(
                    labelText: 'Set Durasi (JJ:MM:DD)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 30),
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
                      onPressed: _isRunning
                          ? null
                          : () {
                              final String name =
                                  _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : defaultTimerName;
                              final String timeString = _timeController.text;

                              final int totalSeconds = parseDuration(
                                timeString,
                              ); // Gunakan helper

                              if (totalSeconds > 0) {
                                service.invoke('start', {
                                  'duration': totalSeconds,
                                  'name': name,
                                });
                              }
                            },
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
                      onPressed: () {
                        service.invoke('reset');
                        _nameController.text = defaultTimerName;
                        _timeController.text = defaultTimeString;
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
