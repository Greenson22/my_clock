import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import '../service/alarm_model.dart';
import '../service/alarm_service.dart';
import '../widgets/add_alarm_sheet.dart';
import '../widgets/alarm_card.dart';
import '../widgets/edit_alarm_dialog.dart'; // Impor dialog edit

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

  // Fungsi untuk update nama alarm
  void _updateAlarmLabel(Alarm alarm, String newLabel) {
    alarm.label = newLabel;
    setState(() {
      _alarmService.updateAlarm(alarm);
    });
  }

  void _showAddAlarmSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddAlarmSheet(onAddAlarm: _addAlarm),
    );
  }

  // Fungsi untuk menampilkan dialog edit
  Future<void> _showEditAlarmDialog(Alarm alarm) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EditAlarmDialog(
          alarm: alarm,
          onSave: (newLabel) {
            _updateAlarmLabel(alarm, newLabel);
          },
        );
      },
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
                  // Panggil dialog edit saat card diklik
                  onEdit: () => _showEditAlarmDialog(alarm),
                );
              },
            ),
    );
  }
}
