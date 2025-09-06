import 'package:flutter/material.dart';
import '../service/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit; // Tambahkan callback onEdit

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit, // Tambahkan parameter onEdit
  });

  @override
  Widget build(BuildContext context) {
    final timeStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: alarm.isActive
          ? Theme.of(context).colorScheme.onSurface
          : Colors.grey,
    );

    final labelStyle = TextStyle(
      fontSize: 16,
      color: alarm.isActive
          ? Theme.of(context).colorScheme.onSurface
          : Colors.grey,
    );

    return Card(
      // Bungkus dengan InkWell agar bisa diklik untuk edit
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(alarm.time.format(context), style: timeStyle),
          subtitle: Text(alarm.label, style: labelStyle),
          trailing: Wrap(
            spacing: 0,
            children: [
              Switch(value: alarm.isActive, onChanged: (_) => onToggle()),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
