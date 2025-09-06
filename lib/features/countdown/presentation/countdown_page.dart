import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../service/countdown_model.dart';
import '../service/countdown_utils.dart';
import 'widgets/add_timer_sheet.dart';
import 'widgets/timer_card.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  List<CountdownTimer> _activeTimers = [];
  final FlutterBackgroundService _service = FlutterBackgroundService();

  @override
  void initState() {
    // ... (initState tetap sama) ...
    super.initState();
    _service.startService();
    _service.invoke('setAsForeground');

    _service.on('updateTimers').listen((data) {
      if (data == null || data['timers'] == null) return;
      final List timerDataList = data['timers'] as List;
      if (mounted) {
        setState(() {
          _activeTimers = timerDataList
              .map(
                (timerJson) =>
                    CountdownTimer.fromJson(timerJson as Map<String, dynamic>),
              )
              .toList();
        });
      }
    });

    _service.invoke('requestInitialTimers');
  }

  // [PERUBAHAN] Fungsi _addTimer sekarang menerima parameter ikon
  void _addTimer(
    String name,
    String timeString,
    String? alarmSoundPath,
    int? iconCodePoint,
  ) {
    final int totalSeconds = parseDuration(timeString);
    if (totalSeconds > 0) {
      _service.invoke('addTimer', {
        'duration': totalSeconds,
        'name': name,
        'alarmSound': alarmSoundPath,
        'iconCodePoint': iconCodePoint, // <-- Kirim data ikon
      });
    }
  }

  // ... (sisa fungsi tidak ada perubahan) ...
  void _stopAlarm() => _service.invoke('stopAlarm');
  void _clearAllTimers() => _service.invoke('clearAll');

  // --- FUNGSI DIALOG ---
  Future<void> _showEditNameDialog(CountdownTimer timer) async {
    final TextEditingController dialogNameController = TextEditingController(
      text: timer.name,
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Nama Timer'),
          content: TextField(
            controller: dialogNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama baru',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (dialogNameController.text.isNotEmpty) {
                  _service.invoke('updateTimerName', {
                    'id': timer.id,
                    'name': dialogNameController.text,
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearAllConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus semua timer?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Semua'),
              onPressed: () {
                _clearAllTimers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(CountdownTimer timer) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Timer'),
          content: Text(
            'Apakah Anda yakin ingin menghapus timer "${timer.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                _service.invoke('removeTimer', {'id': timer.id});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddTimerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddTimerSheet(
            // [PERUBAHAN] Sesuaikan callback untuk menerima data ikon
            onAddTimer: (name, timeString, alarmSoundPath, iconCodePoint) {
              _addTimer(name, timeString, alarmSoundPath, iconCodePoint);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method tetap sama) ...
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Multi Timer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Hapus Semua Timer",
            onPressed: _activeTimers.isEmpty
                ? null
                : _showClearAllConfirmationDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTimerSheet,
        label: const Text('Timer Baru'),
        icon: const Icon(Icons.add_alarm),
      ),
      body: _activeTimers.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Belum ada timer",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: _activeTimers.length,
              itemBuilder: (context, index) {
                final timer = _activeTimers[index];
                return TimerCard(
                  timer: timer,
                  onStopAlarm: _stopAlarm,
                  onResume: () =>
                      _service.invoke('resumeTimer', {'id': timer.id}),
                  onPause: () =>
                      _service.invoke('pauseTimer', {'id': timer.id}),
                  onReset: () =>
                      _service.invoke('resetTimer', {'id': timer.id}),
                  onDelete: () => _showDeleteConfirmationDialog(timer),
                  onEditName: () => _showEditNameDialog(timer),
                );
              },
            ),
    );
  }
}
