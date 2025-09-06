import 'package:flutter/material.dart';

// Daftar ikon yang bisa dipilih
const List<IconData> selectableIcons = [
  Icons.timer,
  Icons.hourglass_bottom,
  Icons.av_timer,
  Icons.alarm,
  Icons.watch_later,
  Icons.schedule,
  Icons.kitchen,
  Icons.local_dining,
  Icons.restaurant,
  Icons.sports_esports,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.book,
  Icons.work,
  Icons.school,
  Icons.bedtime,
  Icons.self_improvement,
  Icons.wb_sunny,
  Icons.star,
  Icons.favorite,
  Icons.anchor,
];

class IconPickerDialog extends StatelessWidget {
  final Function(IconData) onIconSelected;

  const IconPickerDialog({super.key, required this.onIconSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Ikon'),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: selectableIcons.map((iconData) {
            return IconButton(
              icon: Icon(iconData),
              iconSize: 32,
              onPressed: () {
                onIconSelected(iconData);
                Navigator.of(context).pop();
              },
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
