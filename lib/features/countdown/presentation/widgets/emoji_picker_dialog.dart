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

class EmojiPickerDialog extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerDialog({super.key, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Simbol'),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: selectableEmojis.map((emoji) {
            return InkWell(
              onTap: () {
                onEmojiSelected(emoji);
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
