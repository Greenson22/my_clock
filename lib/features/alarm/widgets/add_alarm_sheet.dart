import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Diperlukan untuk FilteringTextInputFormatter
import 'package:uuid/uuid.dart';
import '../service/alarm_model.dart';
// Kita TIDAK LAGI memerlukan TimeInputFormatter, jadi importnya dihapus.

const Uuid uuid = Uuid();

class AddAlarmSheet extends StatefulWidget {
  final Function(Alarm) onAddAlarm;

  const AddAlarmSheet({super.key, required this.onAddAlarm});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  late TimeOfDay _selectedTime;
  late final TextEditingController _labelController;
  List<bool> _selectedDays = List.filled(7, false);

  // --- MODIFIKASI UI INPUT DURASI ---
  // Controller ini sekarang hanya akan menampung MENIT (bukan HH:MM:SS)
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _labelController = TextEditingController(text: 'Alarm');
    // Default durasi adalah 10 menit.
    _minutesController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minutesController.dispose(); // Dispose controller menit
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // --- LOGIKA UTAMA YANG DISESUAIKAN (LEBIH SEDERHANA) ---
  void _handleSetAlarmFromDuration() {
    // 1. Baca input dari controller menit
    final int minutesToAdd = int.tryParse(_minutesController.text) ?? 0;

    if (minutesToAdd <= 0) {
      // Jika durasi 0 atau negatif, jangan lakukan apa-apa
      return;
    }

    final totalDuration = Duration(minutes: minutesToAdd);

    // 2. Hitung waktu target
    final now = DateTime.now();
    final targetDateTime = now.add(totalDuration);
    final targetTimeOfDay = TimeOfDay.fromDateTime(targetDateTime);

    // 3. Buat Alarm baru
    final newAlarm = Alarm(
      id: uuid.v4(),
      label: _labelController.text.isNotEmpty ? _labelController.text : 'Alarm',
      time: targetTimeOfDay,
      days: List.filled(7, false), // Alarm durasi adalah satu kali kejadian
      isActive: true,
    );

    // 4. Panggil callback simpan
    widget.onAddAlarm(newAlarm);

    // 5. Tutup sheet
    Navigator.pop(context);
  }

  // Fungsi simpan manual (via time picker) tetap ada
  void _handleAddAlarm() {
    final newAlarm = Alarm(
      id: uuid.v4(),
      label: _labelController.text,
      time: _selectedTime,
      days: _selectedDays,
      isActive: true,
    );
    widget.onAddAlarm(newAlarm);
    Navigator.pop(context);
  }

  // Helper untuk mengatur nilai di controller saat chip diklik
  void _setDurationFromChip(int minutes) {
    _minutesController.text = minutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tambah Alarm Baru',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label Alarm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- UI INPUT DURASI BARU YANG LEBIH BAIK ---
          Text(
            'Setel alarm dalam (menit):',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Menit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Setel langsung
              FilledButton(
                onPressed: _handleSetAlarmFromDuration, // Panggil fungsi simpan
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: const Text('Setel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // CHIP PRESET DURASI
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.center,
            children: [
              InputChip(
                label: const Text('5 mnt'),
                onPressed: () => _setDurationFromChip(5),
              ),
              InputChip(
                label: const Text('10 mnt'),
                onPressed: () => _setDurationFromChip(10),
              ),
              InputChip(
                label: const Text('15 mnt'),
                onPressed: () => _setDurationFromChip(15),
              ),
              InputChip(
                label: const Text('30 mnt'),
                onPressed: () => _setDurationFromChip(30),
              ),
              InputChip(
                label: const Text('1 Jam'),
                onPressed: () => _setDurationFromChip(60),
              ),
            ],
          ),

          // --- AKHIR BLOK INPUT DURASI BARU ---
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),

          Text(
            'Atau setel waktu spesifik (Manual):',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectTime(context),
            child: Text(
              _selectedTime.format(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          ToggleButtons(
            isSelected: _selectedDays,
            onPressed: (index) {
              setState(() {
                _selectedDays[index] = !_selectedDays[index];
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: List.generate(
              7,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(dayLabels[index]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tombol simpan manual
          OutlinedButton.icon(
            icon: const Icon(Icons.alarm_add),
            label: const Text("SIMPAN ALARM MANUAL"),
            onPressed: _handleAddAlarm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
