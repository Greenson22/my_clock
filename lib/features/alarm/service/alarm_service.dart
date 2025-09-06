import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'alarm_model.dart';

const String kAlarmsStorageKey = "activeAlarmsList";
const Uuid uuid = Uuid();

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  List<Alarm> _alarms = [];
  List<Alarm> get alarms => _alarms;

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(kAlarmsStorageKey);
    if (data != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(data) as List;
        _alarms = decodedList
            .map((item) => Alarm.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _alarms = [];
      }
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> alarmJsonList = _alarms
        .map((a) => a.toJson())
        .toList();
    final String jsonString = jsonEncode(alarmJsonList);
    await prefs.setString(kAlarmsStorageKey, jsonString);
  }

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    _saveAlarms();
  }

  void updateAlarm(Alarm alarm) {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      _saveAlarms();
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
    _saveAlarms();
  }

  void toggleAlarm(String id) {
    final alarm = _alarms.firstWhere((a) => a.id == id);
    alarm.isActive = !alarm.isActive;
    _saveAlarms();
  }
}
