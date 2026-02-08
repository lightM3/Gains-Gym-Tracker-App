import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/providers/tracker_provider.dart';
import 'package:gains/models/tracker_models.dart';
import 'package:gains/models/workout_models.dart';
import 'package:gains/providers/user_provider.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late DateTime _workoutStartTime;
  String? _sessionId;

  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;

  Timer? _workoutTimer;
  Duration _currentDuration = Duration.zero;

  Timer? _restTimer;
  int _restTimerSeconds = 90;
  bool _isRestTimerActive = false;
  int _remainingRestSeconds = 90;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _startWorkoutTimer();
    _initializeSession();
    _loadExercises();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // Antrenman süresini başlatma
  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDuration = DateTime.now().difference(_workoutStartTime);
        });
      }
    });
  }

  // Dinlenme süresini başlatma
  void _startRestTimer() {
    _remainingRestSeconds = _restTimerSeconds;
    _isRestTimerActive = true;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingRestSeconds > 0) {
          _remainingRestSeconds--;
        } else {
          _isRestTimerActive = false;
          _restTimer?.cancel();
        }
      });
    });
  }

  // Oturumu başlatma ve veritabanına kaydetme
  Future<void> _initializeSession() async {
    if (widget.routine.id == null) return;
    try {
      final database = ref.read(databaseServiceProviderTracker);
      final sessionId = await database.startSession(
        widget.routine.id!,
        widget.routine.name,
      );
      if (mounted) {
        setState(() {
          _sessionId = sessionId;
        });
      }
    } catch (e) {
      print('Error initializing session: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting session: $e')));
      }
    }
  }

  // Egzersizleri yükleme ve sayaçları hazırlama
  Future<void> _loadExercises() async {
    final exercises = widget.routine.exercises;
    if (exercises.isNotEmpty) {
      final firstExercise = exercises.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(weightProvider.notifier).state = firstExercise.targetSets;
        ref.read(repsProvider.notifier).state = firstExercise.targetReps;
      });
    }
  }

  bool _isProcessing = false;

  // Seti tamamlama ve kaydetme
  void _completeSet() async {
    if (_isProcessing) return;
    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session not initialized yet. Please wait.'),
        ),
      );
      return;
    }

    final exercises = widget.routine.exercises;
    if (exercises.isEmpty) return;

    final currentExercise = exercises[_currentExerciseIndex];
    final weight = ref.read(weightProvider);
    final reps = ref.read(repsProvider);

    setState(() {
      _isProcessing = true;
    });

    try {
      final isLastExercise = _currentExerciseIndex == exercises.length - 1;
      final isLastSet = _currentSetNumber >= currentExercise.targetSets;

      final setRecord = SetRecord()
        ..sessionId = _sessionId!
        ..exerciseId = currentExercise.id!
        ..exerciseName = currentExercise.name
        ..setNumber = _currentSetNumber
        ..weight = weight
        ..reps = reps
        ..completedAt = DateTime.now();

      if (isLastExercise && isLastSet) {
        await _completeWorkout(lastSet: setRecord);
        return;
      }

      final completeSet = ref.read(completeSetProvider);
      await completeSet(
        _sessionId!,
        currentExercise,
        _currentSetNumber,
        weight,
        reps,
      );

      if (mounted) {
        setState(() {
          _restTimerSeconds = 90;
          _startRestTimer();

          if (_currentSetNumber < currentExercise.targetSets) {
            _currentSetNumber++;
          } else {
            _currentExerciseIndex++;
            _currentSetNumber = 1;
            final nextExercise = exercises[_currentExerciseIndex];
            ref.read(weightProvider.notifier).state = nextExercise.targetSets;
            ref.read(repsProvider.notifier).state = nextExercise.targetReps;
          }
        });
      }
    } catch (e) {
      print('Error completing set: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving set: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Antrenmanı bitirme ve özet ekranına dönme
  Future<void> _completeWorkout({SetRecord? lastSet}) async {
    if (_sessionId == null) return;
    final database = ref.read(databaseServiceProviderTracker);
    final duration = DateTime.now().difference(_workoutStartTime).inSeconds;

    final totalTargetSets = widget.routine.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.targetSets,
    );

    try {
      if (lastSet != null) {
        await database.saveSetAndCompleteSession(
          lastSet: lastSet,
          totalDuration: duration,
          totalTargetSets: totalTargetSets,
        );
      } else {
        await database.completeSession(
          _sessionId!,
          duration,
          totalTargetSets: totalTargetSets,
        );
      }

      if (widget.routine.id != null) {
        final completeWorkout = ref.read(completeWorkoutProvider);
        await completeWorkout(widget.routine.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Workout Completed! Great job!'),
            backgroundColor: Color(0xFF00ff88),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error completing workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing workout: $e')));
      }
    }
  }

  // Egzersizi atlama ve bir sonrakine geçme
  void _skipExercise() async {
    final exercises = widget.routine.exercises.toList();
    if (exercises.isEmpty) return;

    final isLastExercise = _currentExerciseIndex == exercises.length - 1;

    if (isLastExercise) {
      final shouldFinish = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish Workout?'),
          content: const Text(
            'This is the last exercise. Do you want to finish the workout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finish'),
            ),
          ],
        ),
      );

      if (shouldFinish == true) {
        await _completeWorkout();
      }
    } else {
      setState(() {
        _currentExerciseIndex++;
        _currentSetNumber = 1;
        final nextExercise = exercises[_currentExerciseIndex];
        ref.read(weightProvider.notifier).state = nextExercise.targetSets;
        ref.read(repsProvider.notifier).state = nextExercise.targetReps;

        _isRestTimerActive = false;
        _restTimer?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routine.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f2419),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a3a2e),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.routine.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'No exercises in this routine',
            style: TextStyle(color: Color(0xFF808080), fontSize: 16),
          ),
        ),
      );
    }

    final currentExercise = widget.routine.exercises
        .toList()[_currentExerciseIndex];

    final weight = ref.watch(weightProvider);
    final reps = ref.watch(repsProvider);

    final previousPerformanceAsync = ref.watch(
      previousPerformanceProvider(currentExercise.id!),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0f2419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a2e),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.routine.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a3a2e), Color(0xFF0f2419)],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                _WorkoutTimer(duration: _currentDuration),

                const SizedBox(height: 24),
                _ExerciseInfoCard(
                  exerciseName: currentExercise.name,
                  currentSet: _currentSetNumber,
                  totalSets: currentExercise.targetSets,
                  previousPerformance: previousPerformanceAsync.when(
                    data: (record) => record != null
                        ? '${record.weight}kg x ${record.reps}'
                        : null,
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _WeightRepsInput(
                    label: 'WEIGHT (KG)',
                    value: weight,
                    onIncrement: () =>
                        ref.read(weightProvider.notifier).state++,
                    onDecrement: () {
                      if (weight > 0) ref.read(weightProvider.notifier).state--;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _WeightRepsInput(
                    label: 'REPS',
                    value: reps,
                    onIncrement: () => ref.read(repsProvider.notifier).state++,
                    onDecrement: () {
                      if (reps > 0) ref.read(repsProvider.notifier).state--;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CompleteSetButton(
                    onPressed: _completeSet,
                    enabled: weight > 0 && reps > 0 && !_isProcessing,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: _skipExercise,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.skip_next, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Skip Exercise',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isRestTimerActive ? 140 : 24,
                ),
              ],
            ),
          ),

          if (_isRestTimerActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _RestTimer(
                  remainingSeconds: _remainingRestSeconds,
                  isActive: _isRestTimerActive,
                  isPaused: false,
                  onPlayPause: () {},
                  onAdd30: () {
                    setState(() {
                      _remainingRestSeconds += 30;
                    });
                  },
                  onSkip: () {
                    setState(() {
                      _isRestTimerActive = false;
                      _restTimer?.cancel();
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutTimer extends StatelessWidget {
  final Duration duration;
  const _WorkoutTimer({required this.duration});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'WORKOUT TIME',
          style: TextStyle(
            color: Color(0xFF00ff88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(duration),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _ExerciseInfoCard extends StatelessWidget {
  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final String? previousPerformance;

  const _ExerciseInfoCard({
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    this.previousPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a3a2e).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff88),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SET $currentSet OF $totalSets',
                  style: const TextStyle(
                    color: Color(0xFF0f2419),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (previousPerformance != null) ...[
            const SizedBox(height: 12),
            Text(
              'Previous: $previousPerformance',
              style: const TextStyle(
                color: Color(0xFF808080),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: const Row(
              children: [
                Icon(Icons.history, color: Color(0xFF00ff88), size: 16),
                SizedBox(width: 6),
                Text(
                  'View History',
                  style: TextStyle(
                    color: Color(0xFF00ff88),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightRepsInput extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _WeightRepsInput({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF808080),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CircleButton(icon: Icons.remove, onTap: onDecrement),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 24),
            _CircleButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1a3a2e),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _CompleteSetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _CompleteSetButton({required this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00ff88),
          disabledBackgroundColor: const Color(0xFF1a3a2e),
          foregroundColor: const Color(0xFF0f2419),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 20),
            SizedBox(width: 8),
            Text(
              'COMPLETE SET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestTimer extends StatelessWidget {
  final int remainingSeconds;
  final bool isActive;
  final bool isPaused;
  final VoidCallback onPlayPause;
  final VoidCallback onAdd30;
  final VoidCallback onSkip;

  const _RestTimer({
    required this.remainingSeconds,
    required this.isActive,
    required this.isPaused,
    required this.onPlayPause,
    required this.onAdd30,
    required this.onSkip,
  });

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a3a2e).withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFF00ff88),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlayPause,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  color: const Color(0xFF0f2419),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REST TIMER',
                  style: TextStyle(
                    color: Color(0xFF808080),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAdd30,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a2e),
              foregroundColor: const Color(0xFF00ff88),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '+30s',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1a3a2e),
              foregroundColor: const Color(0xFF808080),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
