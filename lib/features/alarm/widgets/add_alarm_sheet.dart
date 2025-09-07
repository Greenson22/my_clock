import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../service/alarm_model.dart';

// Impor widget yang baru saja kita buat
import 'quick_alarm_input.dart';
import 'manual_alarm_input.dart';

const Uuid uuid = Uuid();

enum AlarmInputMethod { quick, manual }

class AddAlarmSheet extends StatefulWidget {
  final Function(Alarm) onAddAlarm;
  const AddAlarmSheet({super.key, required this.onAddAlarm});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  late final TextEditingController _labelController;
  Set<AlarmInputMethod> _selectedMethod = {AlarmInputMethod.quick};

  // [DIPERBAIKI] Gunakan nama kelas State yang sudah publik
  final _quickInputKey = GlobalKey<QuickAlarmInputState>();
  final _manualInputKey = GlobalKey<ManualAlarmInputState>();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: 'Alarm');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveAlarm() {
    final String label = _labelController.text.isNotEmpty
        ? _labelController.text
        : 'Alarm';
    Alarm? newAlarm;

    if (_selectedMethod.first == AlarmInputMethod.quick) {
      final int minutesToAdd = _quickInputKey.currentState?.minutes ?? 0;
      if (minutesToAdd <= 0) return;

      final totalDuration = Duration(minutes: minutesToAdd);
      final targetDateTime = DateTime.now().add(totalDuration);
      final targetTimeOfDay = TimeOfDay.fromDateTime(targetDateTime);

      newAlarm = Alarm(
        id: uuid.v4(),
        label: label,
        time: targetTimeOfDay,
        days: List.filled(7, false),
        isActive: true,
      );
    } else {
      final time = _manualInputKey.currentState?.selectedTime;
      final days = _manualInputKey.currentState?.selectedDays;

      if (time == null || days == null) return;

      newAlarm = Alarm(
        id: uuid.v4(),
        label: label,
        time: time,
        days: days,
        isActive: true,
      );
    }

    widget.onAddAlarm(newAlarm);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Center(
            child: Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _selectedMethod.first == AlarmInputMethod.quick
                ? QuickAlarmInput(key: _quickInputKey)
                : ManualAlarmInput(key: _manualInputKey),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add_alarm),
            label: const Text("SIMPAN ALARM"),
            onPressed: _saveAlarm,
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
