import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../service/countdown_utils.dart';
import '../formatters/time_input_formatter.dart';
import 'emoji_picker_dialog.dart'; // <-- Pastikan file ini diimpor

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
  late final TextEditingController _iconController;
  File? _selectedAlarmFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: defaultTimerName);
    _timeController = TextEditingController(text: defaultTimeString);
    _iconController = TextEditingController(text: '⏱️');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _iconController.dispose();
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

  // [BARU] Fungsi untuk membuka dialog pemilih emoji
  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (_) => EmojiPickerDialog(
        onEmojiSelected: (emoji) {
          // Update teks di dalam TextField saat emoji dipilih
          _iconController.text = emoji;
        },
      ),
    );
  }

  void _handleAddTimer() {
    final String name = _nameController.text.isNotEmpty
        ? _nameController.text
        : defaultTimerName;
    final String iconChar = _iconController.text.isNotEmpty
        ? _iconController.text
        : '⏱️';
    widget.onAddTimer(
      name,
      _timeController.text,
      _selectedAlarmFile?.path,
      iconChar,
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
              // TextField untuk input emoji dari keyboard
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _iconController,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 32),
                  decoration: const InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              // [BARU] Tombol untuk membuka daftar emoji
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: _showEmojiPicker,
                tooltip: 'Pilih dari daftar',
              ),
              const SizedBox(width: 4),
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
            label: Expanded(
              child: Text(alarmSoundText, overflow: TextOverflow.ellipsis),
            ),
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
