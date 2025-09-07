import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickAlarmInput extends StatefulWidget {
  // Kita menggunakan Key agar file induk (add_alarm_sheet) dapat mengakses State widget ini.
  const QuickAlarmInput({super.key});

  @override
  // [DIUBAH] Merujuk ke kelas State yang sekarang publik
  State<QuickAlarmInput> createState() => QuickAlarmInputState();
}

// [DIUBAH] Nama kelas dibuat menjadi publik dengan menghapus '_'
class QuickAlarmInputState extends State<QuickAlarmInput> {
  late final TextEditingController _minutesController;

  // Jadikan ini 'public' agar bisa diakses melalui GlobalKey
  int get minutes => int.tryParse(_minutesController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _setDurationFromChip(int minutes) {
    setState(() {
      _minutesController.text = minutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ini adalah UI yang dipindahkan dari _buildQuickInput() di file sheet asli
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
}
