import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/models/user_models.dart';
import 'package:gains/models/workout_models.dart';
import 'package:gains/services/database_service.dart';
import 'package:gains/services/notification_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  return await database.getUserProfile();
});

final isDayCompletedProvider = FutureProvider<bool>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  final completions = await database.getTodayCompletions();
  return completions.isNotEmpty;
});

final streakProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  final profile = await database.getUserProfile();
  final now = DateTime.now();
  final lastLogin = profile.lastLoginDate;

  if (lastLogin == null) {
    await database.updateStreak(1, now);
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleStreakReminder();
    return 1;
  }

  final lastLoginDate = DateTime(
    lastLogin.year,
    lastLogin.month,
    lastLogin.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  final daysDifference = today.difference(lastLoginDate).inDays;

  if (daysDifference == 0) {
    return profile.currentStreak;
  } else if (daysDifference == 1) {
    final newStreak = profile.currentStreak + 1;
    await database.updateStreak(newStreak, now);
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleStreakReminder();
    return newStreak;
  } else {
    await database.updateStreak(1, now);
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleStreakReminder();
    return 1;
  }
});

final nextWorkoutProvider = FutureProvider<WorkoutRoutine?>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  final allRoutines = await database.getAllRoutines();
  if (allRoutines.isEmpty) {
    return null;
  }

  final profile = await database.getUserProfile();
  final currentIndex = profile.currentRoutineIndex;

  if (currentIndex >= allRoutines.length) {
    await database.updateCurrentRoutineIndex(0);
    return allRoutines[0];
  }

  return allRoutines[currentIndex];
});

final completeWorkoutProvider =
    Provider<Future<void> Function(String routineId)>((ref) {
      return (String routineId) async {
        final database = ref.read(databaseServiceProvider);
        final allRoutines = await database.getAllRoutines();
        if (allRoutines.isNotEmpty) {
          await database.finishWorkoutAndAdvance(routineId, allRoutines.length);
        } else {
          await database.completeWorkout(routineId);
        }
      };
    });

final bodyMeasurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return database.getBodyMeasurementsStream();
});
