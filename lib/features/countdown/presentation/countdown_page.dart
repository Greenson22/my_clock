import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
  final TextEditingController _nameController = TextEditingController(
    text: defaultTimerName,
  );
  final TextEditingController _timeController = TextEditingController(
    text: defaultTimeString,
  );
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

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // --- FUNGSI KONTROL UI ---
  void _addTimer() {
    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    final int totalSeconds = parseDuration(_timeController.text);
    if (totalSeconds > 0) {
      _service.invoke('addTimer', {'duration': totalSeconds, 'name': name});
      _nameController.text = defaultTimerName;
      _timeController.text = defaultTimeString;
      FocusScope.of(context).unfocus();
    }
  }

  void _removeTimer(String id) => _service.invoke('removeTimer', {'id': id});
  void _clearAllTimers() => _service.invoke('clearAll');
  void _pauseTimer(String id) => _service.invoke('pauseTimer', {'id': id});
  void _resumeTimer(String id) => _service.invoke('resumeTimer', {'id': id});
  void _resetTimer(String id) => _service.invoke('resetTimer', {'id': id});

  // [BARU] Fungsi untuk mengirim perintah update nama ke service
  void _updateTimerName(String id, String newName) {
    if (newName.isNotEmpty) {
      _service.invoke('updateTimerName', {'id': id, 'name': newName});
    }
  }

  // [BARU] Fungsi untuk menampilkan dialog edit nama
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
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: dialogNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama baru',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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

  // --- BUILD WIDGET UTAMA --- (Tidak ada perubahan signifikan)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Multi Timer Modern"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Hapus Semua Timer",
            onPressed: _activeTimers.isEmpty ? null : _clearAllTimers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInputForm(),
          Expanded(
            child: _activeTimers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_off_outlined,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    itemCount: _activeTimers.length,
                    itemBuilder: (context, index) {
                      final timer = _activeTimers[index];
                      return _buildModernTimerCard(timer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildInputForm() {
    // ... (Tidak ada perubahan di sini)
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            FilledButton.icon(
              icon: const Icon(Icons.add_alarm),
              label: const Text(
                "TAMBAH TIMER",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _addTimer,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimerCard(CountdownTimer timer) {
    final bool isPaused = timer.isPaused;
    final bool isDone = timer.isDone;

    final Color stateColor;
    final IconData stateIcon;

    if (isDone) {
      stateColor = Colors.green;
      stateIcon = Icons.check_circle;
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
                // <-- [PERUBAHAN] Bungkus Text dengan Row
                children: [
                  Expanded(
                    child: Text(
                      timer.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    // <-- [PERUBAHAN] Tambahkan tombol edit
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
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: stateColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                if (!isDone)
                  TextButton(
                    onPressed: () => isPaused
                        ? _resumeTimer(timer.id)
                        : _pauseTimer(timer.id),
                    child: Text(isPaused ? "Lanjutkan" : "Jeda"),
                  ),
                TextButton(
                  onPressed: () => _resetTimer(timer.id),
                  child: const Text("Reset"),
                ),
                TextButton(
                  onPressed: () => _removeTimer(timer.id),
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
