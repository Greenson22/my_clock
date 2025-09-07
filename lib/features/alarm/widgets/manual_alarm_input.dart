import 'package:flutter/material.dart';

class ManualAlarmInput extends StatefulWidget {
  // Kita juga menggunakan Key di sini
  const ManualAlarmInput({super.key});

  @override
  // [DIUBAH] Merujuk ke kelas State yang sekarang publik
  State<ManualAlarmInput> createState() => ManualAlarmInputState();
}

// [DIUBAH] Nama kelas dibuat menjadi publik dengan menghapus '_'
class ManualAlarmInputState extends State<ManualAlarmInput> {
  late TimeOfDay _selectedTime;
  List<bool> _selectedDays = List.filled(7, false);

  // Jadikan state internal ini 'public' melalui getter
  TimeOfDay get selectedTime => _selectedTime;
  List<bool> get selectedDays => _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
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

  void _toggleAllDays() {
    setState(() {
      final bool areAllSelected = _selectedDays.every((day) => day == true);
      _selectedDays = List.filled(7, !areAllSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ini adalah UI yang dipindahkan dari _buildManualInput()
    final List<String> dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final bool allDaysSelected = _selectedDays.every((day) => day == true);

    return Column(
      key: const ValueKey('manual'), // Key untuk AnimatedSwitcher
      children: [
        Text(
          'Pilih waktu spesifik:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        Center(
          child: FilterChip(
            label: const Text('Setiap Hari'),
            selected: allDaysSelected,
            onSelected: (isSelected) {
              _toggleAllDays();
            },
          ),
        ),
      ],
    );
  }
}
