import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/models/workout_models.dart';
import 'package:gains/services/database_service.dart';

final databaseServiceProviderWorkout = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final selectedCategoryProvider = StateProvider<MuscleGroup?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final currentRoutineProvider = StateProvider<WorkoutRoutine?>((ref) => null);
final routineExercisesProvider = StateProvider<List<Exercise>>((ref) => []);

final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  // Tüm egzersizleri veritabanından getirme
  final database = ref.watch(databaseServiceProviderWorkout);
  return await database.getAllExercises();
});

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  // Seçilen kategori ve aramaya göre egzersizleri filtreleme
  final allExercisesAsync = ref.watch(allExercisesProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return allExercisesAsync.when(
    data: (exercises) {
      var filtered = exercises;
      if (selectedCategory != null) {
        filtered = filtered
            .where((e) => e.muscleGroup == selectedCategory)
            .toList();
      }
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where(
              (e) => e.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final routineSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredRoutinesProvider = Provider<AsyncValue<List<WorkoutRoutine>>>((
  ref,
) {
  // Arama sorgusuna göre rutinleri filtreleme
  final allRoutinesAsync = ref.watch(allRoutinesProvider);
  final searchQuery = ref.watch(routineSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return allRoutinesAsync;
  }

  return allRoutinesAsync.whenData((routines) {
    return routines
        .where((r) => r.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  });
});

class RoutinesNotifier extends StateNotifier<AsyncValue<List<WorkoutRoutine>>> {
  final DatabaseService _database;

  RoutinesNotifier(this._database) : super(const AsyncValue.loading()) {
    loadRoutines();
  }

  // Kayıtlı rutinleri yükleme
  Future<void> loadRoutines() async {
    try {
      final routines = await _database.getAllRoutines();
      if (mounted) state = AsyncValue.data(routines);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  // Rutinlerin sırasını değiştirme
  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentList = state.value;
    if (currentList == null) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final updatedList = List<WorkoutRoutine>.from(currentList);
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);

    for (int i = 0; i < updatedList.length; i++) {
      updatedList[i].orderIndex = i;
    }

    state = AsyncValue.data(updatedList);

    try {
      final routineIds = updatedList.map((r) => r.id!).toList();
      await _database.reorderRoutines(routineIds);
    } catch (_) {
      loadRoutines();
    }
  }

  Future<void> refresh() => loadRoutines();
}

final allRoutinesProvider =
    StateNotifierProvider<RoutinesNotifier, AsyncValue<List<WorkoutRoutine>>>((
      ref,
    ) {
      final database = ref.watch(databaseServiceProviderWorkout);
      return RoutinesNotifier(database);
    });
