import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/utils/app_colors.dart';
import 'package:gains/models/workout_models.dart';
import 'package:gains/providers/workout_provider.dart';

// Antrenman düzenleme ve oluşturma sayfası
class WorkoutEditPage extends ConsumerStatefulWidget {
  final String? routineName;
  final String? routineId;

  const WorkoutEditPage({super.key, this.routineName, this.routineId});

  @override
  ConsumerState<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends ConsumerState<WorkoutEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.routineName != null) {
      _nameController.text = widget.routineName!;
    }

    if (widget.routineId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final database = ref.read(databaseServiceProviderWorkout);
        final routine = await database.getRoutineById(widget.routineId!);
        if (routine != null) {
          ref.read(routineExercisesProvider.notifier).state = routine.exercises;
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(routineExercisesProvider.notifier).state = [];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(routineExercisesProvider);
    final allExercises = ref.watch(filteredExercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.routineId == null ? 'New Routine' : 'Edit Routine',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a routine name'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final database = ref.read(databaseServiceProviderWorkout);
              final routine = WorkoutRoutine()
                ..name = _nameController.text
                ..exercises.addAll(exercises);

              if (widget.routineId != null) {
                routine.id = widget.routineId;
                await database.updateRoutine(routine);
              } else {
                await database.addRoutine(routine);
              }

              if (context.mounted) {
                ref.read(routineExercisesProvider.notifier).state = [];

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.routineId == null
                          ? 'Routine created!'
                          : 'Routine updated!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Routine Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceDarkBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Exercises (${exercises.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showExerciseSelector(allExercises);
                  },
                  icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises added yet',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _showExerciseSelector(allExercises);
                          },
                          child: const Text(
                            'Add your first exercise',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: 1.05,
                            child: Material(
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.transparent,
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final items = List<Exercise>.from(exercises);
                      final item = items.removeAt(oldIndex);
                      items.insert(newIndex, item);
                      ref.read(routineExercisesProvider.notifier).state = items;
                    },
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Container(
                        key: ValueKey('${exercise.name}_$index'),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          title: Text(
                            exercise.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${exercise.targetSets} sets × ${exercise.targetReps} reps',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () => _editExercise(index, exercise),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () {
                                  final items = List<Exercise>.from(exercises);
                                  items.removeAt(index);
                                  ref
                                          .read(
                                            routineExercisesProvider.notifier,
                                          )
                                          .state =
                                      items;
                                },
                              ),
                            ],
                          ),
                          onTap: () => _editExercise(index, exercise),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Egzersiz düzenleme dialogu
  void _editExercise(int index, Exercise exercise) {
    final setsController = TextEditingController(
      text: exercise.targetSets.toString(),
    );
    final repsController = TextEditingController(
      text: exercise.targetReps.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDarkBlue,
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Sets',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDarkBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Reps',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDarkBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final newSets =
                  int.tryParse(setsController.text) ?? exercise.targetSets;
              final newReps =
                  int.tryParse(repsController.text) ?? exercise.targetReps;

              final items = List<Exercise>.from(
                ref.read(routineExercisesProvider),
              );
              items[index].targetSets = newSets;
              items[index].targetReps = newReps;
              ref.read(routineExercisesProvider.notifier).state = items;

              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Egzersiz seçici (BottomSheet) gösterme
  void _showExerciseSelector(List<Exercise> allExercises) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDarkBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final filteredList = ref.watch(filteredExercisesProvider);

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Exercise',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search exercises...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceDarkBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MuscleGroup.values.map((group) {
                          final isSelected =
                              ref.watch(selectedCategoryProvider) == group;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(group.displayName),
                              selected: isSelected,
                              onSelected: (selected) {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = selected
                                    ? group
                                    : null;
                              },
                              selectedColor: AppColors.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textSecondary,
                              ),
                              backgroundColor: AppColors.surfaceDarkBlue,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDarkBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              exercise.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              exercise.muscleGroup.displayName,
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.add,
                              color: AppColors.primaryBlue,
                            ),
                            onTap: () {
                              final current = ref
                                  .read(routineExercisesProvider.notifier)
                                  .state;

                              final newExercise = Exercise()
                                ..id =
                                    '${exercise.name}_${DateTime.now().millisecondsSinceEpoch}'
                                ..name = exercise.name
                                ..muscleGroup = exercise.muscleGroup
                                ..targetSets = exercise.targetSets
                                ..targetReps = exercise.targetReps;

                              ref
                                  .read(routineExercisesProvider.notifier)
                                  .state = [
                                ...current,
                                newExercise,
                              ];
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
