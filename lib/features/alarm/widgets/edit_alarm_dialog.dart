import 'package:flutter/material.dart';
import '../service/alarm_model.dart';

class EditAlarmDialog extends StatefulWidget {
  final Alarm alarm;
  final Function(String newLabel) onSave;

  const EditAlarmDialog({super.key, required this.alarm, required this.onSave});

  @override
  State<EditAlarmDialog> createState() => _EditAlarmDialogState();
}

class _EditAlarmDialogState extends State<EditAlarmDialog> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.alarm.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_labelController.text.isNotEmpty) {
      widget.onSave(_labelController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Nama Alarm'),
      content: TextField(
        controller: _labelController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nama alarm',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _handleSave, child: const Text('Simpan')),
      ],
    );
  }
}
