import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/services/database_service.dart';
import 'package:gains/models/tracker_models.dart';
import 'package:gains/models/workout_models.dart';

final databaseServiceProviderTracker = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final activeSessionProvider = FutureProvider<WorkoutSession?>((ref) async {
  // Aktif antrenman oturumunu getirme
  final database = ref.watch(databaseServiceProviderTracker);
  return await database.getActiveSession();
});

final currentExerciseIndexProvider = StateProvider<int>((ref) => 0);
final currentSetNumberProvider = StateProvider<int>((ref) => 1);
final weightProvider = StateProvider<int>((ref) => 0);
final repsProvider = StateProvider<int>((ref) => 0);

final workoutTimerProvider = StreamProvider.family<Duration, DateTime>((
  ref,
  startTime,
) {
  // Antrenman süresini takip etme
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateTime.now().difference(startTime);
  });
});

final restTimerProvider = StreamProvider.family<int, int>((
  ref,
  initialSeconds,
) {
  // Dinlenme süresini takip etme
  return Stream.periodic(const Duration(seconds: 1), (count) {
    final remaining = initialSeconds - count;
    return remaining >= 0 ? remaining : 0;
  }).take(initialSeconds + 1);
});

final restTimerActiveProvider = StateProvider<bool>((ref) => false);
final restTimerPausedProvider = StateProvider<bool>((ref) => false);

final previousPerformanceProvider = FutureProvider.family<SetRecord?, String>((
  ref,
  exerciseId,
) async {
  // Önceki performansı getirme
  final database = ref.watch(databaseServiceProviderTracker);
  return await database.getPreviousPerformance(exerciseId, '');
});

final sessionExercisesProvider = StateProvider<List<Exercise>>((ref) => []);

final completeSetProvider =
    Provider<
      Future<void> Function(
        String sessionId,
        Exercise exercise,
        int setNumber,
        int weight,
        int reps,
      )
    >((ref) {
      // Seti tamamlama ve kaydetme
      return (sessionId, exercise, setNumber, weight, reps) async {
        final database = ref.read(databaseServiceProviderTracker);
        final setRecord = SetRecord()
          ..sessionId = sessionId
          ..exerciseId = exercise.id ?? ''
          ..exerciseName = exercise.name
          ..setNumber = setNumber
          ..weight = weight
          ..reps = reps
          ..completedAt = DateTime.now();

        await database.saveSet(setRecord);
        ref.read(restTimerActiveProvider.notifier).state = true;
      };
    });
