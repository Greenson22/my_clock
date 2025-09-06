import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../service/alarm_model.dart';

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
  List<bool> _selectedDays = List.filled(7, false); // [Sen, Sel, ..., Min]

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _labelController = TextEditingController(text: 'Alarm');
  }

  @override
  void dispose() {
    _labelController.dispose();
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
          InkWell(
            onTap: () => _selectTime(context),
            child: Text(
              _selectedTime.format(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
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
          FilledButton.icon(
            icon: const Icon(Icons.add_alarm),
            label: const Text("SIMPAN ALARM"),
            onPressed: _handleAddAlarm,
            style: FilledButton.styleFrom(
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
