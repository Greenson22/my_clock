import 'package:flutter/material.dart';

import '../../service/countdown_model.dart';
import '../../service/countdown_utils.dart';

class TimerCard extends StatelessWidget {
  final CountdownTimer timer;
  final VoidCallback onStopAlarm;
  final VoidCallback onResume;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onEditName;

  const TimerCard({
    super.key,
    required this.timer,
    required this.onStopAlarm,
    required this.onResume,
    required this.onPause,
    required this.onReset,
    required this.onDelete,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaused = timer.isPaused;
    final bool isDone = timer.isDone;

    final Color stateColor;

    if (isDone) {
      stateColor = Colors.orange.shade700;
    } else if (isPaused) {
      stateColor = Colors.grey.shade600;
    } else {
      stateColor = Theme.of(context).primaryColor;
    }

    // [PERUBAHAN] Tampilkan ikon kustom atau ikon default
    final IconData displayIcon = timer.iconCodePoint != null
        ? IconData(timer.iconCodePoint!, fontFamily: 'MaterialIcons')
        : Icons.timer; // Ikon default jika tidak ada

    final double progress = timer.initialDurationSeconds > 0
        ? timer.remainingSeconds / timer.initialDurationSeconds
        : 0.0;

    final String alarmInfo = timer.alarmSound != null
        ? 'Alarm: ${timer.alarmSound!.split('/').last}'
        : 'Alarm: Default';

    return Card(
      elevation: isPaused ? 1.0 : 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaused ? Colors.grey.shade200 : stateColor,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                displayIcon,
                color: stateColor,
                size: 40,
              ), // [PERUBAHAN] Gunakan displayIcon
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      timer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: onEditName,
                    tooltip: 'Ubah Nama',
                  ),
                ],
              ),
              trailing: Text(
                isDone ? "SELESAI" : formatDuration(timer.remainingSeconds),
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'monospace',
                  color: stateColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: stateColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarmInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDone)
                  FilledButton.icon(
                    icon: const Icon(Icons.alarm_off, size: 20),
                    label: const Text("Matikan Alarm"),
                    onPressed: onStopAlarm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.orange.shade700,
                    ),
                  )
                else if (isPaused)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: onResume,
                    tooltip: 'Lanjutkan',
                    color: Theme.of(context).primaryColorDark,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: onPause,
                    tooltip: 'Jeda',
                    color: Theme.of(context).primaryColorDark,
                  ),

                if (isPaused)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onReset,
                    tooltip: 'Reset',
                    color: Colors.orange.shade800,
                  ),

                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                  color: Colors.red.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
