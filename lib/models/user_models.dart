import 'package:cloud_firestore/cloud_firestore.dart';

// Kullanıcı profili modeli
class UserProfile {
  String? id;
  late String username;
  String? email;
  String? firebaseUid;
  late String passwordHash;
  late String name;
  String? profileImageUrl;
  late int currentStreak;
  DateTime? lastLoginDate;
  late int currentRoutineIndex;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  double? weight;
  double? height;
  double? bodyFat;

  UserProfile() {
    username = '';
    passwordHash = '';
    name = 'User';
    currentStreak = 0;
    currentRoutineIndex = 0;
    isActive = false;
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'firebaseUid': firebaseUid,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'currentStreak': currentStreak,
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null,
      'currentRoutineIndex': currentRoutineIndex,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'weight': weight,
      'height': height,
      'bodyFat': bodyFat,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile()
      ..id = id
      ..username = map['username'] ?? ''
      ..email = map['email']
      ..firebaseUid = map['firebaseUid']
      ..name = map['name'] ?? 'User'
      ..profileImageUrl = map['profileImageUrl']
      ..currentStreak = map['currentStreak'] ?? 0
      ..lastLoginDate = (map['lastLoginDate'] as Timestamp?)?.toDate()
      ..currentRoutineIndex = map['currentRoutineIndex'] ?? 0
      ..isActive = map['isActive'] ?? false
      ..createdAt = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..updatedAt = (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..weight = (map['weight'] as num?)?.toDouble()
      ..height = (map['height'] as num?)?.toDouble()
      ..bodyFat = (map['bodyFat'] as num?)?.toDouble();
  }
}

// Tamamlanan antrenman kaydı
class WorkoutCompletion {
  String? id;
  late String routineId;
  late DateTime completedAt;

  WorkoutCompletion();

  Map<String, dynamic> toMap() {
    return {
      'routineId': routineId,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  factory WorkoutCompletion.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutCompletion()
      ..id = id
      ..routineId = map['routineId'] ?? ''
      ..completedAt =
          (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
  }
}

// Vücut ölçüm kaydı
class BodyMeasurement {
  String? id;
  late double weight;
  double? bodyFat;
  late DateTime date;

  BodyMeasurement();

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'bodyFat': bodyFat,
      'date': Timestamp.fromDate(date),
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map, String id) {
    return BodyMeasurement()
      ..id = id
      ..weight = (map['weight'] as num).toDouble()
      ..bodyFat = (map['bodyFat'] as num?)?.toDouble()
      ..date = (map['date'] as Timestamp).toDate();
  }
}
