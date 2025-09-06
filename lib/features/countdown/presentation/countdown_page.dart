import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// Impor package yang baru ditambahkan
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../service/countdown_model.dart';
import '../service/countdown_utils.dart';
import 'widgets/add_timer_sheet.dart';
import 'widgets/timer_card.dart';
import 'widgets/emoji_picker_dialog.dart';

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  List<CountdownTimer> _activeTimers = [];
  final FlutterBackgroundService _service = FlutterBackgroundService();
  // [KEMBALIKAN] State untuk mengontrol mode pengurutan
  bool _isReorderEnabled = false;

  @override
  void initState() {
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

  // [KEMBALIKAN] Fungsi untuk menangani event reorder
  void _onReorder(int oldIndex, int newIndex) {
    // Pastikan state diupdate agar UI terasa responsif
    setState(() {
      final CountdownTimer item = _activeTimers.removeAt(oldIndex);
      _activeTimers.insert(newIndex, item);
    });

    // Kirim urutan baru ke background service untuk disimpan
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
          // [KEMBALIKAN] Tombol untuk mengaktifkan mode urut
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
              // ... (Widget untuk state kosong tidak berubah)
            )
          // [UBAH] Gunakan ReorderableGridView.builder
          : ReorderableGridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _activeTimers.length,
              dragEnabled:
                  _isReorderEnabled, // Kontrol drag hanya saat mode aktif
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final timer = _activeTimers[index];
                return TimerCard(
                  key: ValueKey(
                    timer.id,
                  ), // Key sangat penting untuk reordering
                  timer: timer,
                  // [BARU] Kirim status mode urut ke TimerCard
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

  // ... (Semua fungsi dialog tidak berubah)
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
    final TextEditingController dialogNameController = TextEditingController(
      text: timer.name,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol untuk mengubah ikon
              InkWell(
                onTap: () {
                  Navigator.of(context).pop(); // Tutup dialog edit nama
                  _showEditIconDialog(timer); // Buka dialog edit ikon
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
              // Field untuk mengubah nama
              TextField(
                controller: dialogNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama timer',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
