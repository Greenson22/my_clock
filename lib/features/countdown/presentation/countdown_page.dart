import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// Impor file service kita
import '../service/countdown_service.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  // State UI sekarang adalah LIST of Timers, bukan lagi satu string
  List<CountdownTimer> _runningTimers = [];

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

    // Listener UTAMA. Sekarang mendengarkan 'updateTimers' (bukan 'update')
    service.on('updateTimers').listen((data) {
      if (data == null || data['timers'] == null) return;

      final List timerDataList = data['timers'] as List;
      setState(() {
        // Konversi data JSON (Map) dari service menjadi List<CountdownTimer>
        _runningTimers = timerDataList
            .map(
              (timerJson) =>
                  CountdownTimer.fromJson(timerJson as Map<String, dynamic>),
            )
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _addTimer() {
    final service = FlutterBackgroundService();

    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    final String timeString = _timeController.text;

    final int totalSeconds = parseDuration(timeString); // Gunakan helper

    if (totalSeconds > 0) {
      // Kirim perintah BARU: 'addTimer' dengan data
      service.invoke('addTimer', {'duration': totalSeconds, 'name': name});

      // Reset field input setelah ditambahkan
      _nameController.text = defaultTimerName;
      _timeController.text = defaultTimeString;
      // Tutup keyboard
      FocusScope.of(context).unfocus();
    }
  }

  void _removeTimer(String id) {
    final service = FlutterBackgroundService();
    // Kirim perintah BARU: 'removeTimer' dengan ID
    service.invoke('removeTimer', {'id': id});
  }

  void _clearAllTimers() {
    final service = FlutterBackgroundService();
    // Kirim perintah BARU: 'clearAll'
    service.invoke('clearAll');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Multi Timer Service"),
        actions: [
          // Tombol Hapus Semua
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Hapus Semua Timer",
            onPressed: _runningTimers.isEmpty ? null : _clearAllTimers,
          ),
        ],
      ),
      body: Column(
        children: [
          // BAGIAN 1: FORM INPUT
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Timer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Set Durasi (JJ:MM:DD)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol 'Add' (Menggantikan 'Mulai')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addTimer,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // BAGIAN 2: LIST VIEW TIMER YANG AKTIF
          Expanded(
            child: _runningTimers.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada timer aktif.\nTambahkan timer di atas.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _runningTimers.length,
                    itemBuilder: (context, index) {
                      final timer = _runningTimers[index];
                      return ListTile(
                        title: Text(
                          timer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        // Tampilan sisa waktu
                        subtitle: Text(
                          formatDuration(timer.remainingSeconds),
                          style: const TextStyle(
                            fontSize: 24,
                            fontFamily: 'monospace',
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.redAccent,
                          ),
                          tooltip: "Hapus Timer Ini",
                          onPressed: () =>
                              _removeTimer(timer.id), // Hapus timer spesifik
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
