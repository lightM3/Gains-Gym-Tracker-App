import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/services/database_service.dart';
import 'package:gains/models/tracker_models.dart';

final databaseServiceProviderAnalytics = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final analyticsProvider =
    StateNotifierProvider.autoDispose<
      AnalyticsNotifier,
      AsyncValue<Map<DateTime, double>>
    >((ref) {
      return AnalyticsNotifier(ref.watch(databaseServiceProviderAnalytics));
    });

final weeklyVolumeProvider = FutureProvider.autoDispose<Map<DateTime, double>>((
  ref,
) async {
  final database = ref.watch(databaseServiceProviderAnalytics);
  return await database.getWeeklyVolume();
});

final bestLiftsProvider = FutureProvider.autoDispose<List<SetRecord>>((
  ref,
) async {
  final database = ref.watch(databaseServiceProviderAnalytics);
  return await database.getBestLifts();
});

final averageDurationProvider = FutureProvider.autoDispose<Duration>((
  ref,
) async {
  final database = ref.watch(databaseServiceProviderAnalytics);
  return await database.getAverageWorkoutDuration();
});

class AnalyticsNotifier
    extends StateNotifier<AsyncValue<Map<DateTime, double>>> {
  final DatabaseService _database;

  AnalyticsNotifier(this._database) : super(const AsyncValue.loading()) {
    loadWorkoutDates();
  }

  Future<void> loadWorkoutDates() async {
    try {
      final sessions = await _database.getAllCompletedSessions();
      final dateMap = <DateTime, double>{};

      for (var s in sessions) {
        if (s.completedAt == null) continue;
        final date = DateTime(
          s.completedAt!.year,
          s.completedAt!.month,
          s.completedAt!.day,
        );

        double ratio = 1.0;
        if (s.totalExercises > 0) {
          ratio = s.completedExercises / s.totalExercises;
          if (ratio > 1.0) ratio = 1.0;
        }

        if (dateMap.containsKey(date)) {
          if (ratio > dateMap[date]!) {
            dateMap[date] = ratio;
          }
        } else {
          dateMap[date] = ratio;
        }
      }

      state = AsyncValue.data(dateMap);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final heatMapDataProvider = FutureProvider.autoDispose<Map<DateTime, double>>((
  ref,
) async {
  final database = ref.watch(databaseServiceProviderAnalytics);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59); // Ay sonu

  // Hafif model yerine session detaylarını alma
  final sessions = await database.getAllCompletedSessions();

  final Map<DateTime, double> heatMap = {};

  // Bu ayın oturumlarını filtreleme
  final monthlySessions = sessions.where((s) {
    if (s.completedAt == null) return false;
    return s.completedAt!.isAfter(
          startDate.subtract(const Duration(seconds: 1)),
        ) &&
        s.completedAt!.isBefore(endDate.add(const Duration(seconds: 1)));
  });

  // Günlük en yüksek başarı oranını kaydetme
  for (var session in monthlySessions) {
    if (session.completedAt == null) continue;

    final date = DateTime(
      session.completedAt!.year,
      session.completedAt!.month,
      session.completedAt!.day,
    );

    double ratio = 0.0;
    if (session.totalExercises > 0) {
      ratio = session.completedExercises / session.totalExercises;
      if (ratio > 1.0) ratio = 1.0;
    } else {
      // Eski verilerde totalExercises 0 olabilir, setlere bakarak yedek işlem yapma
      // Ancak şu an için 1.0 kabul etme (tamamlandıysa tamamdır)
      // Veya 0.0 kabul etme.
      // Varsayılan olarak tamamlanan oturum ise %100 varsayma, motive edici olsun.
      ratio = 1.0;
    }

    // O gün için daha yüksek bir oran varsa onu tutma (günde birden fazla antrenman)
    if (!heatMap.containsKey(date) || ratio > heatMap[date]!) {
      heatMap[date] = ratio;
    }
  }

  return heatMap;
});
