import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../service/countdown_utils.dart';
import '../formatters/time_input_formatter.dart';
import 'emoji_picker_dialog.dart';

class AddTimerSheet extends StatefulWidget {
  final Function(
    String name,
    String timeString,
    String? alarmSoundPath,
    String? iconChar,
  )
  onAddTimer;

  const AddTimerSheet({super.key, required this.onAddTimer});

  @override
  State<AddTimerSheet> createState() => _AddTimerSheetState();
}

class _AddTimerSheetState extends State<AddTimerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _timeController;
  String _selectedIconChar = '⏱️';
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

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (_) => EmojiPickerDialog(
        initialEmoji: _selectedIconChar,
        onEmojiSelected: (emoji) {
          setState(() {
            _selectedIconChar = emoji;
          });
        },
      ),
    );
  }

  void _handleAddTimer() {
    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    widget.onAddTimer(
      name,
      _timeController.text,
      _selectedAlarmFile?.path,
      _selectedIconChar,
    );
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 60,
                child: OutlinedButton(
                  onPressed: _showIconPicker,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedIconChar,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Timer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
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
          OutlinedButton.icon(
            icon: const Icon(Icons.music_note_outlined),
            // [FIX] Hapus widget Expanded di sini
            label: Text(alarmSoundText, overflow: TextOverflow.ellipsis),
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
