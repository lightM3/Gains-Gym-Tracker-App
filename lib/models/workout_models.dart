import 'package:cloud_firestore/cloud_firestore.dart';

enum MuscleGroup {
  chest,
  shoulders,
  back,
  biceps,
  triceps,
  legs,
  abs,
  cardio,
  other;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Göğüs';
      case MuscleGroup.shoulders:
        return 'Omuz';
      case MuscleGroup.back:
        return 'Sırt';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.legs:
        return 'Bacak';
      case MuscleGroup.abs:
        return 'Karın';
      case MuscleGroup.cardio:
        return 'Kardio';
      case MuscleGroup.other:
        return 'Diğer';
    }
  }
}

// Egzersiz modeli
class Exercise {
  String? id;
  late String name;
  late MuscleGroup muscleGroup;
  String? imageUrl;
  int targetSets = 3;
  int targetReps = 10;
  late DateTime createdAt;
  late DateTime updatedAt;

  Exercise() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroup': muscleGroup.name,
      'imageUrl': imageUrl,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    return Exercise()
      ..id = id
      ..name = map['name'] ?? ''
      ..muscleGroup = MuscleGroup.values.firstWhere(
        (e) => e.name == map['muscleGroup'],
        orElse: () => MuscleGroup.chest,
      )
      ..imageUrl = map['imageUrl']
      ..targetSets = map['targetSets'] ?? 3
      ..targetReps = map['targetReps'] ?? 10
      ..createdAt = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..updatedAt =
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
  }
}

// Antrenman rutini modeli
class WorkoutRoutine {
  String? id;
  late String name;
  bool isRestDay = false;
  int orderIndex = 0;
  List<Exercise> exercises = [];
  late DateTime createdAt;
  late DateTime updatedAt;

  WorkoutRoutine() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isRestDay': isRestDay,
      'orderIndex': orderIndex,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutRoutine.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutRoutine()
      ..id = id
      ..name = map['name'] ?? ''
      ..isRestDay = map['isRestDay'] ?? false
      ..orderIndex = map['orderIndex'] ?? 0
      ..exercises =
          (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e, ''))
              .toList() ??
          []
      ..createdAt = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..updatedAt =
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
  }
}
