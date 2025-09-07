import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Diperlukan untuk FilteringTextInputFormatter
import 'package:uuid/uuid.dart';
import '../service/alarm_model.dart';

const Uuid uuid = Uuid();

// Enum baru untuk mengontrol mode input yang dipilih
enum AlarmInputMethod { quick, manual }

class AddAlarmSheet extends StatefulWidget {
  final Function(Alarm) onAddAlarm;

  const AddAlarmSheet({super.key, required this.onAddAlarm});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  // Kontroler UI
  late final TextEditingController _labelController;
  late final TextEditingController _minutesController;
  late TimeOfDay _selectedTime;
  List<bool> _selectedDays = List.filled(7, false);

  // State untuk mengontrol SegmentedButton
  Set<AlarmInputMethod> _selectedMethod = {AlarmInputMethod.quick};

  @override
  void initState() {
    super.initState();
    // Inisialisasi semua state yang diperlukan
    _labelController = TextEditingController(text: 'Alarm');
    _minutesController = TextEditingController(text: '10');
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan pemilih waktu manual
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

  // Helper untuk mengatur nilai di controller saat chip diklik
  void _setDurationFromChip(int minutes) {
    setState(() {
      _minutesController.text = minutes.toString();
    });
  }

  // --- [BARU] FUNGSI HELPER UNTUK MEMILIH SEMUA HARI ---
  void _toggleAllDays() {
    setState(() {
      // Cek apakah semua hari (every) saat ini bernilai true
      final bool areAllSelected = _selectedDays.every((day) => day == true);

      if (areAllSelected) {
        // Jika semua sudah dipilih, batalkan semua pilihan
        _selectedDays = List.filled(7, false);
      } else {
        // Jika belum semua dipilih (atau hanya sebagian), pilih semua
        _selectedDays = List.filled(7, true);
      }
    });
  }
  // --- AKHIR FUNGSI BARU ---

  // --- SATU FUNGSI SIMPAN UTAMA ---
  void _saveAlarm() {
    final String label = _labelController.text.isNotEmpty
        ? _labelController.text
        : 'Alarm';
    Alarm? newAlarm;

    // Tentukan alarm mana yang akan dibuat berdasarkan mode yang dipilih
    if (_selectedMethod.first == AlarmInputMethod.quick) {
      // --- Logika Mode Cepat (dari input menit) ---
      final int minutesToAdd = int.tryParse(_minutesController.text) ?? 0;
      if (minutesToAdd <= 0) return; // Jangan simpan jika menit tidak valid

      final totalDuration = Duration(minutes: minutesToAdd);
      final targetDateTime = DateTime.now().add(totalDuration);
      final targetTimeOfDay = TimeOfDay.fromDateTime(targetDateTime);

      newAlarm = Alarm(
        id: uuid.v4(),
        label: label,
        time: targetTimeOfDay,
        days: List.filled(7, false), // Mode cepat selalu non-berulang
        isActive: true,
      );
    } else {
      // --- Logika Mode Manual (dari pemilih waktu) ---
      newAlarm = Alarm(
        id: uuid.v4(),
        label: label,
        time: _selectedTime,
        days: _selectedDays, // Gunakan hari yang dipilih pengguna
        isActive: true,
      );
    }

    // Panggil callback dan tutup sheet
    widget.onAddAlarm(newAlarm);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding utama, termasuk untuk viewInsets (keyboard)
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle drag sheet (estetika)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tambah Alarm Baru',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // 1. Input Label (Umum untuk kedua mode)
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label Alarm',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Pemilih Mode (Segmented Button)
          SegmentedButton<AlarmInputMethod>(
            segments: const [
              ButtonSegment(
                value: AlarmInputMethod.quick,
                label: Text('Cepat'),
                icon: Icon(Icons.timer_10_select_outlined),
              ),
              ButtonSegment(
                value: AlarmInputMethod.manual,
                label: Text('Manual'),
                icon: Icon(Icons.edit_calendar_outlined),
              ),
            ],
            selected: _selectedMethod,
            onSelectionChanged: (Set<AlarmInputMethod> newSelection) {
              setState(() {
                // Pastikan selalu ada satu yang dipilih
                if (newSelection.isNotEmpty) {
                  _selectedMethod = newSelection;
                }
              });
            },
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // 3. UI Kondisional (Hanya tampilkan UI untuk mode yang dipilih)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _selectedMethod.first == AlarmInputMethod.quick
                ? _buildQuickInput() // Tampilkan UI Cepat
                : _buildManualInput(), // Tampilkan UI Manual
          ),

          const SizedBox(height: 24),

          // 4. Tombol Simpan Utama (Satu tombol untuk semua)
          FilledButton.icon(
            icon: const Icon(Icons.add_alarm),
            label: const Text("SIMPAN ALARM"),
            onPressed: _saveAlarm, // Panggil fungsi simpan utama
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

  // Widget helper untuk UI Input Cepat
  Widget _buildQuickInput() {
    return Column(
      key: const ValueKey('quick'), // Key untuk AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setel alarm dalam (menit):',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _minutesController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
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
      ],
    );
  }

  // Widget helper untuk UI Input Manual
  Widget _buildManualInput() {
    final List<String> dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    // --- [BARU] Hitung status terpilih untuk FilterChip ---
    final bool allDaysSelected = _selectedDays.every((day) => day == true);

    return Column(
      key: const ValueKey('manual'), // Key untuk AnimatedSwitcher
      children: [
        Text(
          'Pilih waktu spesifik:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        // InkWell besar untuk menampilkan pemilih waktu
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          child: InkWell(
            onTap: () => _selectTime(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Ulangi setiap:', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        // ToggleButtons dibuat sedikit lebih besar dan di-center
        Center(
          child: ToggleButtons(
            isSelected: _selectedDays,
            onPressed: (index) {
              setState(() {
                _selectedDays[index] = !_selectedDays[index];
              });
            },
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
            children: List.generate(
              7,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(dayLabels[index]),
              ),
            ),
          ),
        ),

        // --- [BARU] CHIP UNTUK MEMILIH SEMUA HARI ---
        const SizedBox(height: 8),
        Center(
          child: FilterChip(
            label: const Text('Setiap Hari'),
            selected: allDaysSelected,
            onSelected: (isSelected) {
              // Panggil fungsi helper yang kita buat sebelumnya
              _toggleAllDays();
            },
          ),
        ),
        // --- AKHIR BLOK BARU ---
      ],
    );
  }
}
