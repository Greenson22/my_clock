import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import '../service/alarm_model.dart';
import '../service/alarm_service.dart';
import '../widgets/add_alarm_sheet.dart';
import '../widgets/alarm_card.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  final AlarmService _alarmService = AlarmService();

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() async {
    await _alarmService.loadAlarms();
    setState(() {});
  }

  void _addAlarm(Alarm alarm) {
    setState(() {
      _alarmService.addAlarm(alarm);
    });
    // Setel alarm di sistem
    FlutterAlarmClock.createAlarm(
      hour: alarm.time.hour,
      minutes: alarm.time.minute,
      title: alarm.label,
    );
  }

  void _toggleAlarm(String id) {
    setState(() {
      _alarmService.toggleAlarm(id);
    });
  }

  void _deleteAlarm(String id) {
    setState(() {
      _alarmService.deleteAlarm(id);
    });
  }

  void _showAddAlarmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddAlarmSheet(onAddAlarm: _addAlarm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Alarm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlarmSheet,
        child: const Icon(Icons.add),
      ),
      body: _alarmService.alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Belum ada alarm",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _alarmService.alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarmService.alarms[index];
                return AlarmCard(
                  alarm: alarm,
                  onToggle: () => _toggleAlarm(alarm.id),
                  onDelete: () => _deleteAlarm(alarm.id),
                );
              },
            ),
    );
  }
}
