import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gains/models/tracker_models.dart';
import 'package:gains/models/user_models.dart';
import 'package:gains/models/workout_models.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // O anki kullanıcının ID'sini alma
  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to access data');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  CollectionReference<Map<String, dynamic>> get _completionsCollection =>
      _userDoc.collection('completions');

  CollectionReference<Map<String, dynamic>> get _routinesCollection =>
      _userDoc.collection('routines');

  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _userDoc.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _setsCollection =>
      _userDoc.collection('sets');

  // Kullanıcı profilini getirme, yoksa oluşturma
  Future<UserProfile> getUserProfile() async {
    try {
      final doc = await _userDoc.get().timeout(const Duration(seconds: 10));
      if (!doc.exists) {
        final profile = UserProfile();
        profile.firebaseUid = _userId;
        profile.email = _auth.currentUser?.email;
        profile.name = _auth.currentUser?.displayName ?? 'User';
        await _userDoc
            .set(profile.toMap())
            .timeout(const Duration(seconds: 10));
        return profile;
      }
      return UserProfile.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Tüm profil nesnesini güncelleme
  Future<void> updateUserProfile(UserProfile profile) async {
    profile.updatedAt = DateTime.now();
    await _userDoc.update(profile.toMap());
  }

  // Sadece belirli profil alanlarını güncelleme
  Future<void> updateUserProfileFields({
    String? name,
    String? username,
    String? profileImageUrl,
    double? weight,
    double? height,
    double? bodyFat,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (username != null) updates['username'] = username;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (weight != null) updates['weight'] = weight;
      if (height != null) updates['height'] = height;
      if (bodyFat != null) updates['bodyFat'] = bodyFat;

      if (updates.isNotEmpty) {
        updates['updatedAt'] = Timestamp.now();
        await _userDoc.update(updates);
      }
    }
  }

  // Streak (seri) bilgisini güncelleme
  Future<void> updateStreak(int newStreak, DateTime lastLogin) async {
    await _userDoc.update({
      'currentStreak': newStreak,
      'lastLoginDate': Timestamp.fromDate(lastLogin),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateCurrentRoutineIndex(int index) async {
    await _userDoc.update({
      'currentRoutineIndex': index,
      'updatedAt': Timestamp.now(),
    });
  }

  // Antrenmanı tamamlama ve kaydetme
  Future<void> completeWorkout(String routineId) async {
    final completion = WorkoutCompletion()
      ..routineId = routineId
      ..completedAt = DateTime.now();
    await _completionsCollection.add(completion.toMap());
  }

  Future<List<WorkoutCompletion>> getCompletionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _completionsCollection
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => WorkoutCompletion.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<WorkoutRoutine>> getRoutines() async {
    final snapshot = await _routinesCollection.orderBy('orderIndex').get();
    return snapshot.docs
        .map((doc) => WorkoutRoutine.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<WorkoutCompletion>> getTodayCompletions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _completionsCollection
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'completedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => WorkoutCompletion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting today completions: $e');
      return [];
    }
  }

  Future<void> saveRoutine(WorkoutRoutine routine) async {
    if (routine.id == null) {
      final docRef = await _routinesCollection.add(routine.toMap());
      routine.id = docRef.id;
    } else {
      await _routinesCollection.doc(routine.id).update(routine.toMap());
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    await _routinesCollection.doc(routineId).delete();
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    if (session.id == null) {
      final docRef = await _sessionsCollection.add(session.toMap());
      session.id = docRef.id;
    } else {
      await _sessionsCollection.doc(session.id).update(session.toMap());
    }
  }

  Future<WorkoutSession?> getActiveSession() async {
    final snapshot = await _sessionsCollection
        .where('completedAt', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final session = WorkoutSession.fromMap(doc.data(), doc.id);

      // Bu antrenman oturumu için setleri getirme
      final setsSnapshot = await _setsCollection
          .where('sessionId', isEqualTo: session.id)
          .orderBy('completedAt')
          .get();

      session.sets = setsSnapshot.docs
          .map((d) => SetRecord.fromMap(d.data(), d.id))
          .toList();

      return session;
    }
    return null;
  }

  Future<void> saveSetRecord(SetRecord set) async {
    if (set.id == null) {
      final docRef = await _setsCollection.add(set.toMap());
      set.id = docRef.id;
    } else {
      await _setsCollection.doc(set.id).update(set.toMap());
    }
  }

  Future<void> deleteSetRecord(String setId) async {
    await _setsCollection.doc(setId).delete();
  }

  Future<List<WorkoutSession>> getWorkoutHistory() async {
    final snapshot = await _sessionsCollection
        .where('completedAt', isNull: false)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((d) => WorkoutSession.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<WorkoutSession>> getWorkoutHistoryStream() {
    return _sessionsCollection
        .where('completedAt', isNull: false)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((d) => WorkoutSession.fromMap(d.data(), d.id))
              .toList();
        });
  }

  Future<List<WorkoutRoutine>> getAllRoutines() async {
    return await getRoutines();
  }

  Future<List<Exercise>> getAllExercises() async {
    final exercises = <Exercise>[];
    for (final exerciseData in defaultExercises) {
      final exercise = Exercise()
        ..name = exerciseData['name'] as String
        ..muscleGroup = MuscleGroup.values.firstWhere(
          (e) => e.name == exerciseData['muscleGroup'],
          orElse: () => MuscleGroup.chest,
        )
        ..targetSets = exerciseData['targetSets'] as int
        ..targetReps = exerciseData['targetReps'] as int;
      exercises.add(exercise);
    }
    return exercises;
  }

  Future<void> addRoutine(WorkoutRoutine routine) async {
    await saveRoutine(routine);
  }

  Future<void> updateRoutine(WorkoutRoutine routine) async {
    await saveRoutine(routine);
  }

  Future<void> reorderRoutines(List<String> routineIds) async {
    for (int i = 0; i < routineIds.length; i++) {
      await _routinesCollection.doc(routineIds[i]).update({'orderIndex': i});
    }
  }

  Future<WorkoutRoutine?> getRoutineById(String routineId) async {
    final doc = await _routinesCollection.doc(routineId).get();
    if (!doc.exists) return null;
    return WorkoutRoutine.fromMap(doc.data()!, doc.id);
  }

  // Yeni bir antrenman oturumu başlatma
  Future<String> startSession(String routineId, String routineName) async {
    final session = WorkoutSession()
      ..routineId = routineId
      ..routineName = routineName
      ..startedAt = DateTime.now();

    final docRef = await _sessionsCollection.add(session.toMap());
    return docRef.id;
  }

  // Antrenman oturumunu bitirme ve özet bilgileri kaydetme
  Future<void> completeSession(
    String sessionId,
    int duration, {
    int totalTargetSets = 0,
  }) async {
    // Tamamlanan setleri veritabanından hesaplama
    final setsSnapshot = await _setsCollection
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final completedSetsCount = setsSnapshot.docs.length;

    await _sessionsCollection.doc(sessionId).update({
      'completedAt': Timestamp.now(),
      'totalDuration': duration,
      'totalExercises': totalTargetSets,
      'completedExercises': completedSetsCount,
    });
  }

  Future<void> saveSetAndCompleteSession({
    required SetRecord lastSet,
    required int totalDuration,
    int totalTargetSets = 0,
  }) async {
    await saveSetRecord(lastSet);
    if (lastSet.sessionId != null) {
      await completeSession(
        lastSet.sessionId!,
        totalDuration,
        totalTargetSets: totalTargetSets,
      );
    }
  }

  Future<SetRecord?> getPreviousPerformance(
    String exerciseId,
    String exerciseName,
  ) async {
    final snapshot = await _setsCollection
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SetRecord.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Future<void> saveSet(SetRecord setRecord) async {
    await saveSetRecord(setRecord);
  }

  // Son bir haftalık hacim (volume) verilerini hesaplama
  Future<Map<DateTime, double>> getWeeklyVolume() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final snapshot = await _setsCollection
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
        )
        .get();

    final volumeMap = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final set = SetRecord.fromMap(doc.data(), doc.id);
      final date = DateTime(
        set.completedAt!.year,
        set.completedAt!.month,
        set.completedAt!.day,
      );
      volumeMap[date] = (volumeMap[date] ?? 0) + (set.weight * set.reps);
    }
    return volumeMap;
  }

  // En iyi ağırlıkları (PR) getirme
  Future<List<SetRecord>> getBestLifts() async {
    final snapshot = await _setsCollection
        .orderBy('weight', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => SetRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Ortalama antrenman süresini hesaplama
  Future<Duration> getAverageWorkoutDuration() async {
    final snapshot = await _sessionsCollection
        .where('completedAt', isNull: false)
        .orderBy('completedAt', descending: true)
        .limit(10)
        .get();

    if (snapshot.docs.isEmpty) return Duration.zero;

    int totalDuration = 0;
    for (final doc in snapshot.docs) {
      final session = WorkoutSession.fromMap(doc.data(), doc.id);
      if (session.totalDuration > 0) {
        totalDuration += session.totalDuration;
      } else if (session.completedAt != null && session.startedAt != null) {
        // Eski kayıtlar için yedek hesaplama yöntemi
        totalDuration += session.completedAt!
            .difference(session.startedAt!)
            .inSeconds;
      }
    }

    return Duration(seconds: totalDuration ~/ snapshot.docs.length);
  }

  Future<List<WorkoutSession>> getAllCompletedSessions() async {
    final snapshot = await _sessionsCollection
        .where('completedAt', isNull: false)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WorkoutSession.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> finishWorkoutAndAdvance(String routineId, int nextIndex) async {
    await completeWorkout(routineId);
    await updateCurrentRoutineIndex(nextIndex);
  }

  // Vücut ölçümlerini yönetme
  CollectionReference<Map<String, dynamic>> get _measurementsCollection =>
      _userDoc.collection('measurements');

  Future<void> addBodyMeasurement(double weight, double? bodyFat) async {
    final measurement = BodyMeasurement()
      ..weight = weight
      ..bodyFat = bodyFat
      ..date = DateTime.now();

    await _measurementsCollection.add(measurement.toMap());
  }

  Future<List<BodyMeasurement>> getBodyMeasurements({int limit = 30}) async {
    final snapshot = await _measurementsCollection
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BodyMeasurement.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<BodyMeasurement>> getBodyMeasurementsStream({int limit = 30}) {
    return _measurementsCollection
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BodyMeasurement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
