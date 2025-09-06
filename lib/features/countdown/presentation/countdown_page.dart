import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../service/countdown_service.dart'; // Impor service (termasuk Model)

class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});
  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  // State UI adalah List dari Model Timer kita
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

    // Pastikan service jalan
    // (di file service, autoStart sudah true, jadi ini akan menyambung ke service yg ada)
    _service.startService();
    _service.invoke('setAsForeground');

    // Listener UTAMA: Mendengarkan list timer terbaru dari service
    _service.on('updateTimers').listen((data) {
      if (data == null || data['timers'] == null) return;

      final List timerDataList = data['timers'] as List;
      if (mounted) {
        // Pastikan widget masih ada di tree
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

  // --- FUNGSI KONTROL UI (Hanya mengirim perintah ke Service) ---

  void _addTimer() {
    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    final int totalSeconds = parseDuration(_timeController.text);

    if (totalSeconds > 0) {
      _service.invoke('addTimer', {'duration': totalSeconds, 'name': name});
      _nameController.text = defaultTimerName; // Reset input field
      _timeController.text = defaultTimeString;
      FocusScope.of(context).unfocus(); // Tutup keyboard
    }
  }

  void _removeTimer(String id) => _service.invoke('removeTimer', {'id': id});
  void _clearAllTimers() => _service.invoke('clearAll');
  void _pauseTimer(String id) => _service.invoke('pauseTimer', {'id': id});
  void _resumeTimer(String id) => _service.invoke('resumeTimer', {'id': id});
  void _resetTimer(String id) => _service.invoke('resetTimer', {'id': id});

  // --- BUILD WIDGET UTAMA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Multi Timer (Persistent)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Hapus Semua Timer",
            onPressed: _activeTimers.isEmpty ? null : _clearAllTimers,
          ),
        ],
      ),
      body: Column(
        children: [
          // BAGIAN 1: FORM INPUT
          _buildInputForm(), // Memecah form ke widget sendiri agar rapi
          const Divider(),

          // BAGIAN 2: LIST VIEW TIMER YANG AKTIF
          Expanded(
            child: _activeTimers.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada timer aktif.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // Padding agar tidak tertutup
                    itemCount: _activeTimers.length,
                    itemBuilder: (context, index) {
                      final timer = _activeTimers[index];
                      // Build setiap card timer
                      return _buildTimerCard(timer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  /// Widget untuk Form Input di bagian atas
  Widget _buildInputForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Timer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.label_outline),
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
                    labelText: 'Durasi (JJ:MM:DD)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _addTimer,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.add_alarm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget untuk membangun setiap Card Timer di ListView
  Widget _buildTimerCard(CountdownTimer timer) {
    // Tentukan warna dan style berdasarkan state timer
    final bool isPaused = timer.isPaused;
    final bool isDone = timer.isDone;
    Color cardColor = isDone
        ? Colors.green.shade50
        : (isPaused ? Colors.grey.shade100 : Colors.white);
    Color timeColor = isDone
        ? Colors.green
        : (isPaused ? Colors.grey.shade700 : Colors.indigo);

    return Card(
      elevation: isPaused ? 1.0 : 4.0, // Beri efek 'aktif' jika sedang jalan
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Nama Timer dan Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Text(
                  isDone ? "SELESAI" : formatDuration(timer.remainingSeconds),
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'monospace',
                    color: timeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Baris Tombol Kontrol
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol PAUSE atau RESUME (PLAY)
                if (!isDone) // Hanya tampilkan jika belum selesai
                  IconButton(
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    color: Theme.of(context).primaryColorDark,
                    tooltip: isPaused ? "Lanjutkan" : "Jeda",
                    onPressed: () => isPaused
                        ? _resumeTimer(timer.id)
                        : _pauseTimer(timer.id),
                  ),

                // Tombol RESET
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.orange.shade800,
                  tooltip: "Reset Timer",
                  onPressed: () => _resetTimer(timer.id),
                ),

                // Tombol HAPUS
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade700,
                  tooltip: "Hapus Timer",
                  onPressed: () => _removeTimer(timer.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
