class CountdownTimer {
  final String id;
  String name;
  final int initialDurationSeconds;
  int remainingSeconds;
  bool isPaused;
  bool isDone;
  final String? alarmSound;
  final int? iconCodePoint; // <-- [BARU] Kode untuk ikon

  CountdownTimer({
    required this.id,
    required this.name,
    required this.initialDurationSeconds,
    required this.remainingSeconds,
    this.isPaused = false,
    this.isDone = false,
    this.alarmSound,
    this.iconCodePoint, // <-- [BARU] Tambahkan di konstruktor
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initialDurationSeconds': initialDurationSeconds,
    'remainingSeconds': remainingSeconds,
    'isPaused': isPaused,
    'isDone': isDone,
    'alarmSound': alarmSound,
    'iconCodePoint': iconCodePoint, // <-- [BARU] Simpan ke JSON
  };

  factory CountdownTimer.fromJson(Map<String, dynamic> json) => CountdownTimer(
    id: json['id'] as String,
    name: json['name'] as String,
    initialDurationSeconds: json['initialDurationSeconds'] as int,
    remainingSeconds: json['remainingSeconds'] as int,
    isPaused: json['isPaused'] as bool? ?? false,
    isDone: json['isDone'] as bool? ?? false,
    alarmSound: json['alarmSound'] as String?,
    iconCodePoint: json['iconCodePoint'] as int?, // <-- [BARU] Muat dari JSON
  );
}
