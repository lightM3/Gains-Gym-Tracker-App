import 'package:cloud_firestore/cloud_firestore.dart';

// Set kaydı modeli
class SetRecord {
  String? id;
  late String exerciseId;
  late String exerciseName;
  late int setNumber;
  late int weight;
  late int reps;
  late DateTime completedAt;
  int restDuration = 90;
  late String sessionId;

  SetRecord();

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'completedAt': Timestamp.fromDate(completedAt),
      'restDuration': restDuration,
      'sessionId': sessionId,
    };
  }

  factory SetRecord.fromMap(Map<String, dynamic> map, String id) {
    return SetRecord()
      ..id = id
      ..exerciseId = map['exerciseId'] ?? ''
      ..exerciseName = map['exerciseName'] ?? ''
      ..setNumber = map['setNumber'] ?? 0
      ..weight = map['weight'] ?? 0
      ..reps = map['reps'] ?? 0
      ..completedAt =
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..restDuration = map['restDuration'] ?? 90
      ..sessionId = map['sessionId'] ?? '';
  }
}

// Antrenman oturumu modeli
class WorkoutSession {
  String? id;
  late String routineId;
  late String routineName;
  late DateTime startedAt;
  DateTime? completedAt;
  int totalDuration = 0;
  int totalExercises = 0;
  int completedExercises = 0;
  List<SetRecord> sets = [];

  WorkoutSession();

  bool get isActive => completedAt == null;
  int get totalSets => sets.length;

  Map<String, dynamic> toMap() {
    return {
      'routineId': routineId,
      'routineName': routineName,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'totalDuration': totalDuration,
      'totalExercises': totalExercises,
      'completedExercises': completedExercises,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutSession()
      ..id = id
      ..routineId = map['routineId'] ?? ''
      ..routineName = map['routineName'] ?? ''
      ..startedAt = (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..completedAt = (map['completedAt'] as Timestamp?)?.toDate()
      ..totalDuration = map['totalDuration'] ?? map['duration'] ?? 0
      ..totalExercises = map['totalExercises'] ?? 0
      ..completedExercises = map['completedExercises'] ?? 0;
  }
}
