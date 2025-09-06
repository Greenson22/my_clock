import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:file_picker/file_picker.dart';
import '../service/countdown_service.dart';

// (TimeInputFormatter class tetap sama, tidak ada perubahan)
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 6) {
      newText = newText.substring(0, 6);
    }
    String formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if ((i == 1 || i == 3) && i != newText.length - 1) {
        formattedText += ':';
      }
    }
    int selectionIndex = formattedText.length;
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

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
  }

  // --- FUNGSI KONTROL UI ---
  void _addTimer(String name, String timeString, String? alarmSoundPath) {
    final int totalSeconds = parseDuration(timeString);
    if (totalSeconds > 0) {
      _service.invoke('addTimer', {
        'duration': totalSeconds,
        'name': name,
        'alarmSound': alarmSoundPath,
      });
    }
  }

  void _stopAlarm() => _service.invoke('stopAlarm');
  void _removeTimer(String id) => _service.invoke('removeTimer', {'id': id});
  void _clearAllTimers() => _service.invoke('clearAll');
  void _pauseTimer(String id) => _service.invoke('pauseTimer', {'id': id});
  void _resumeTimer(String id) => _service.invoke('resumeTimer', {'id': id});
  void _resetTimer(String id) => _service.invoke('resetTimer', {'id': id});

  void _updateTimerName(String id, String newName) {
    if (newName.isNotEmpty) {
      _service.invoke('updateTimerName', {'id': id, 'name': newName});
    }
  }

  Future<void> _showEditNameDialog(CountdownTimer timer) async {
    final TextEditingController dialogNameController = TextEditingController(
      text: timer.name,
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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
                _updateTimerName(timer.id, dialogNameController.text);
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
      barrierDismissible: false,
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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Timer'),
          content: Text(
            'Apakah Anda yakin ingin menghapus timer "${timer.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                _removeTimer(timer.id);
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
          child: _AddTimerSheet(
            onAddTimer: (name, timeString, alarmSoundPath) {
              _addTimer(name, timeString, alarmSoundPath);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // --- BUILD WIDGET UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Multi Timer"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
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
                return _buildModernTimerCard(timer);
              },
            ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildModernTimerCard(CountdownTimer timer) {
    final bool isPaused = timer.isPaused;
    final bool isDone = timer.isDone;

    final Color stateColor;
    final IconData stateIcon;

    if (isDone) {
      stateColor = Colors.orange.shade700;
      stateIcon = Icons.alarm_on;
    } else if (isPaused) {
      stateColor = Colors.grey.shade600;
      stateIcon = Icons.pause_circle_filled;
    } else {
      stateColor = Theme.of(context).primaryColor;
      stateIcon = Icons.play_circle_filled;
    }

    final double progress = timer.initialDurationSeconds > 0
        ? timer.remainingSeconds / timer.initialDurationSeconds
        : 0.0;

    final String alarmInfo = timer.alarmSound != null
        ? 'Alarm: ${timer.alarmSound!.split('/').last}'
        : 'Alarm: Default';

    return Card(
      elevation: isPaused ? 1.0 : 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaused ? Colors.grey.shade200 : stateColor,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          children: [
            ListTile(
              leading: Icon(stateIcon, color: stateColor, size: 40),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      timer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () => _showEditNameDialog(timer),
                    tooltip: 'Ubah Nama',
                  ),
                ],
              ),
              trailing: Text(
                isDone ? "SELESAI" : formatDuration(timer.remainingSeconds),
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'monospace',
                  color: stateColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: stateColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarmInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // [PERBAIKAN DI SINI] Ubah logika untuk menampilkan tombol
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                // Tombol utama (Matikan Alarm, Lanjutkan, Jeda)
                if (isDone)
                  FilledButton.icon(
                    icon: const Icon(Icons.alarm_off),
                    label: const Text("Matikan Alarm"),
                    onPressed: _stopAlarm,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                    ),
                  )
                else if (isPaused)
                  TextButton(
                    onPressed: () => _resumeTimer(timer.id),
                    child: const Text("Lanjutkan"),
                  )
                else // (jika sedang berjalan)
                  TextButton(
                    onPressed: () => _pauseTimer(timer.id),
                    child: const Text("Jeda"),
                  ),

                // Tampilkan tombol "Reset" jika timer dijeda atau sudah selesai
                if (isPaused)
                  TextButton(
                    onPressed: () => _resetTimer(timer.id),
                    child: const Text("Reset"),
                  ),

                // Selalu tampilkan tombol "Hapus"
                TextButton(
                  onPressed: () => _showDeleteConfirmationDialog(timer),
                  child: Text(
                    "Hapus",
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// (Widget _AddTimerSheet tidak berubah)
class _AddTimerSheet extends StatefulWidget {
  final Function(String name, String timeString, String? alarmSoundPath)
  onAddTimer;

  const _AddTimerSheet({required this.onAddTimer});

  @override
  State<_AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<_AddTimerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _timeController;
  File? _selectedAlarmFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: defaultTimerName);
    _timeController = TextEditingController(text: defaultTimeString);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickAlarmSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedAlarmFile = File(result.files.single.path!);
      });
    }
  }

  void _handleAddTimer() {
    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    widget.onAddTimer(name, _timeController.text, _selectedAlarmFile?.path);
  }

  @override
  Widget build(BuildContext context) {
    final String alarmSoundText = _selectedAlarmFile != null
        ? _selectedAlarmFile!.path.split('/').last
        : 'Default';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tambah Timer Baru',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Timer',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeController,
            textAlign: TextAlign.center,
            autofocus: true,
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.music_note_outlined),
            label: Expanded(
              child: Text(alarmSoundText, overflow: TextOverflow.ellipsis),
            ),
            onPressed: _pickAlarmSound,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_alarm),
            label: const Text("SIMPAN TIMER"),
            onPressed: _handleAddTimer,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
