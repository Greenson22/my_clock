import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../service/countdown_model.dart';
import '../../service/countdown_utils.dart';

class TimerCard extends StatelessWidget {
  final CountdownTimer timer;
  final bool isReorderEnabled;
  final VoidCallback onStopAlarm;
  final VoidCallback onResume;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TimerCard({
    super.key,
    required this.timer,
    required this.isReorderEnabled,
    required this.onStopAlarm,
    required this.onResume,
    required this.onPause,
    required this.onReset,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaused = timer.isPaused;
    final bool isDone = timer.isDone;
    final Color stateColor;
    final theme = Theme.of(context);

    if (isDone) {
      stateColor = Colors.orange.shade700;
    } else if (isPaused) {
      stateColor = Colors.grey.shade500;
    } else {
      stateColor = theme.colorScheme.primary;
    }

    final double progress = timer.initialDurationSeconds > 0
        ? timer.remainingSeconds / timer.initialDurationSeconds
        : 0.0;

    return Card(
      elevation: isPaused ? 0.5 : 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior:
          Clip.antiAlias, // Penting agar Positioned tidak keluar dari Card
      child: Stack(
        children: [
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timer.iconChar ?? '⏱️',
                        style: const TextStyle(fontSize: 24),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'reset') {
                            onReset();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'reset',
                                child: ListTile(
                                  leading: Icon(Icons.refresh),
                                  title: Text('Reset'),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  CircularPercentIndicator(
                    radius: 41.0,
                    lineWidth: 8.0,
                    percent: progress,
                    center: isDone
                        ? Icon(Icons.alarm_on, size: 36, color: stateColor)
                        : Text(
                            formatDuration(timer.remainingSeconds),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                    progressColor: stateColor,
                    backgroundColor: stateColor.withOpacity(0.2),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  Column(
                    children: [
                      Text(
                        timer.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      // [MODIFIKASI FINAL] Spasi 1px ini dihapus
                      // const SizedBox(height: 1),
                      if (isDone)
                        FilledButton.icon(
                          icon: const Icon(Icons.alarm_off, size: 16),
                          label: const Text("Matikan"),
                          onPressed: onStopAlarm,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        )
                      else if (isPaused)
                        IconButton.filled(
                          iconSize: 22,
                          icon: const Icon(Icons.play_arrow),
                          onPressed: onResume,
                          tooltip: 'Lanjutkan',
                        )
                      else
                        IconButton.filled(
                          iconSize: 22,
                          icon: const Icon(Icons.pause),
                          onPressed: onPause,
                          tooltip: 'Jeda',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isReorderEnabled)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
