import 'package:flutter/material.dart';

// Daftar emoji yang bisa dipilih
const List<String> selectableEmojis = [
  '⏱️',
  '⌛',
  '⏰',
  '🍳',
  '🍽️',
  '🍕',
  '🎮',
  '🏋️',
  '🏃',
  '📚',
  '💼',
  '🎓',
  '😴',
  '🧘',
  '☀️',
  '⭐',
  '❤️',
  '⚓',
  '🎉',
  '🎁',
  '🎂',
  '🚀',
  '💡',
  '🌱',
  '💻',
  '🎵',
  '🎨',
];

class EmojiPickerDialog extends StatefulWidget {
  final Function(String) onEmojiSelected;
  // [BARU] Tambahkan parameter untuk nilai awal
  final String? initialEmoji;

  const EmojiPickerDialog({
    super.key,
    required this.onEmojiSelected,
    this.initialEmoji, // Terima nilai awal
  });

  @override
  State<EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<EmojiPickerDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // [BARU] Inisialisasi controller dengan nilai awal
    _textController = TextEditingController(text: widget.initialEmoji ?? '⏱️');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // [BARU] Fungsi untuk menyimpan emoji dari text field
  void _submitEmojiFromTextField() {
    if (_textController.text.isNotEmpty) {
      widget.onEmojiSelected(_textController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Simbol'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [BARU] TextField untuk input keyboard
            TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              maxLength: 1,
              autofocus: true,
              style: const TextStyle(fontSize: 48),
              decoration: const InputDecoration(
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
                hintText: 'Ketik di sini',
              ),
              onSubmitted: (_) => _submitEmojiFromTextField(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Atau pilih dari daftar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // [MODIFIKASI] Daftar emoji tetap ada
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: selectableEmojis.map((emoji) {
                return InkWell(
                  onTap: () {
                    widget.onEmojiSelected(emoji);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        // [BARU] Tombol Simpan untuk input dari keyboard
        FilledButton(
          onPressed: _submitEmojiFromTextField,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
