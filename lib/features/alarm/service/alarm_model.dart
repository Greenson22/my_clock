import 'package:flutter/material.dart';

class Alarm {
  final String id;
  String label;
  TimeOfDay time;
  bool isActive;
  List<bool> days; // [Sen, Sel, Rab, Kam, Jum, Sab, Min]

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    this.isActive = true,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'hour': time.hour,
    'minute': time.minute,
    'isActive': isActive,
    'days': days,
  };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
    id: json['id'] as String,
    label: json['label'] as String,
    time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
    isActive: json['isActive'] as bool? ?? true,
    days: List<bool>.from(json['days'] as List),
  );
}
