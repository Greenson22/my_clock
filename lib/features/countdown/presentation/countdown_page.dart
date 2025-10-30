import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../service/countdown_model.dart';
import '../service/countdown_utils.dart';
import 'widgets/add_timer_sheet.dart';
import 'widgets/timer_card.dart';
import 'widgets/emoji_picker_dialog.dart';
import 'formatters/time_input_formatter.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  List<CountdownTimer> _activeTimers = [];
  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _isReorderEnabled = false;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi inisialisasi yang baru
    initializeAndLoadTimers();
  }

  // [BARU] Buat fungsi async untuk inisialisasi
  Future<void> initializeAndLoadTimers() async {
    // Pastikan service sudah berjalan sebelum melanjutkan
    await _service.startService();
    _service.invoke('setAsForeground');

    // Setup listener untuk menerima update data timer
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

    // Minta data timer awal setelah semuanya siap
    _service.invoke('requestInitialTimers');
  }

  void _addTimer(
    String name,
    String timeString,
    String? alarmSoundPath,
    String? iconChar,
  ) {
    final int totalSeconds = parseDuration(timeString);
    if (totalSeconds > 0) {
      _service.invoke('addTimer', {
        'duration': totalSeconds,
        'name': name,
        'alarmSound': alarmSoundPath,
        'iconChar': iconChar,
      });
    }
  }

  void _stopAlarm() => _service.invoke('stopAlarm');
  void _clearAllTimers() => _service.invoke('clearAll');

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final CountdownTimer item = _activeTimers.removeAt(oldIndex);
      _activeTimers.insert(newIndex, item);
    });
    _service.invoke('reorderTimers', {
      'timers': _activeTimers.map((t) => t.toJson()).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Multi Timer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_activeTimers.length > 1)
            IconButton(
              icon: Icon(_isReorderEnabled ? Icons.check : Icons.drag_handle),
              tooltip: _isReorderEnabled
                  ? "Selesai Mengurutkan"
                  : "Ubah Urutan",
              onPressed: () {
                setState(() {
                  _isReorderEnabled = !_isReorderEnabled;
                });
              },
            ),
          if (_activeTimers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: "Hapus Semua Timer",
              onPressed: _showClearAllConfirmationDialog,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTimerSheet,
        label: const Text('Timer Baru'),
        icon: const Icon(Icons.add),
      ),
      body: _activeTimers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Belum ada timer",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tekan tombol 'Timer Baru' untuk memulai.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ReorderableGridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // [MODIFIKASI] Diubah dari 0.9 ke 0.85 untuk memberi sedikit
                // ruang tinggi ekstra dan memperbaiki overflow.
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _activeTimers.length,
              dragEnabled: _isReorderEnabled,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final timer = _activeTimers[index];
                return TimerCard(
                  key: ValueKey(timer.id),
                  timer: timer,
                  isReorderEnabled: _isReorderEnabled,
                  onStopAlarm: _stopAlarm,
                  onResume: () =>
                      _service.invoke('resumeTimer', {'id': timer.id}),
                  onPause: () =>
                      _service.invoke('pauseTimer', {'id': timer.id}),
                  onReset: () =>
                      _service.invoke('resetTimer', {'id': timer.id}),
                  onDelete: () => _showDeleteConfirmationDialog(timer),
                  onEdit: () => _showEditTimerDialog(timer),
                );
              },
            ),
    );
  }

  void _showAddTimerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddTimerSheet(
            onAddTimer: (name, timeString, alarmSoundPath, iconChar) {
              _addTimer(name, timeString, alarmSoundPath, iconChar);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(CountdownTimer timer) {
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
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

  Future<void> _showClearAllConfirmationDialog() {
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
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

  Future<void> _showEditTimerDialog(CountdownTimer timer) async {
    final TextEditingController nameController = TextEditingController(
      text: timer.name,
    );
    final TextEditingController timeController = TextEditingController(
      text: formatDuration(timer.initialDurationSeconds),
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Timer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditIconDialog(timer);
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timer.iconChar ?? '⏱️',
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.edit_outlined, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama timer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Durasi (JJ:MM:DD)',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                    TimeInputFormatter(),
                  ],
                ),
              ],
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
                if (nameController.text.isNotEmpty &&
                    nameController.text != timer.name) {
                  _service.invoke('updateTimerName', {
                    'id': timer.id,
                    'name': nameController.text,
                  });
                }
                final newDurationSeconds = parseDuration(timeController.text);
                if (newDurationSeconds > 0 &&
                    newDurationSeconds != timer.initialDurationSeconds) {
                  _service.invoke('updateTimerDuration', {
                    'id': timer.id,
                    'duration': newDurationSeconds,
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

  Future<void> _showEditIconDialog(CountdownTimer timer) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EmojiPickerDialog(
          initialEmoji: timer.iconChar,
          onEmojiSelected: (emoji) {
            _service.invoke('updateTimerIcon', {
              'id': timer.id,
              'iconChar': emoji,
            });
          },
        );
      },
    );
  }
}
