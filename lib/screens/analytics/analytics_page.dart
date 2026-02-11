import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/utils/app_colors.dart';
import 'package:gains/providers/analytics_provider.dart';
import 'package:gains/screens/analytics/personal_records_page.dart';
import 'package:gains/screens/analytics/body_stats_section.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Analytics verilerini sağlayan provider'ları izleme
    final bestLiftsAsync = ref.watch(bestLiftsProvider);
    final weeklyVolumeAsync = ref.watch(weeklyVolumeProvider);
    final averageDurationAsync = ref.watch(averageDurationProvider);
    final heatMapAsync = ref.watch(heatMapDataProvider);

    // Verilerin yüklenme durumunu kontrol etme
    final isLoading =
        bestLiftsAsync.isLoading ||
        weeklyVolumeAsync.isLoading ||
        averageDurationAsync.isLoading ||
        heatMapAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vücut istatistikleri bölümünü (Ağırlık & Yağ Oranı) gösterme
                  const BodyStatsSection(),
                  const SizedBox(height: 32),
                  const Text(
                    'Activity',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Aktivite ısı haritasını yükleme ve gösterme
                  heatMapAsync.when(
                    data: (heatMap) => _ActivityHeatMap(heatMap: heatMap),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) =>
                        _buildEmptyState('Error loading activity data'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Weekly Volume',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Haftalık hacim verilerini işleme ve grafiğe dökme
                  weeklyVolumeAsync.when(
                    data: (volumeMap) {
                      if (volumeMap.isEmpty) {
                        return _buildEmptyState('No volume data yet');
                      }

                      final maxVolume = volumeMap.values.reduce(
                        (a, b) => a > b ? a : b,
                      );

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LAST 7 DAYS',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF6B6B,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${maxVolume.toInt()} kg peak',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 80, 80),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ...volumeMap.entries.map((entry) {
                              final dateStr = DateFormat(
                                'EEE, MMM d',
                              ).format(entry.key);
                              final percentage = maxVolume > 0
                                  ? (entry.value / maxVolume)
                                  : 0.0;
                              final isToday =
                                  entry.key.day == DateTime.now().day &&
                                  entry.key.month == DateTime.now().month;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: isToday
                                                ? const Color.fromARGB(
                                                    255,
                                                    255,
                                                    80,
                                                    80,
                                                  )
                                                : const Color.fromARGB(
                                                    255,
                                                    255,
                                                    80,
                                                    80,
                                                  ).withValues(alpha: 0.7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${entry.value.toInt()} kg',
                                          style: TextStyle(
                                            color: isToday
                                                ? const Color.fromARGB(
                                                    255,
                                                    255,
                                                    80,
                                                    80,
                                                  )
                                                : const Color.fromARGB(
                                                    255,
                                                    255,
                                                    80,
                                                    80,
                                                  ).withValues(alpha: 0.7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceDark,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: percentage,
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isToday
                                                    ? [
                                                        const Color.fromARGB(
                                                          255,
                                                          255,
                                                          80,
                                                          80,
                                                        ),
                                                        const Color(
                                                          0xFFFF6B6B,
                                                        ).withValues(
                                                          alpha: 0.7,
                                                        ),
                                                      ]
                                                    : [
                                                        const Color.fromARGB(
                                                          255,
                                                          255,
                                                          80,
                                                          80,
                                                        ),
                                                        const Color(
                                                          0xFFFF6B6B,
                                                        ).withValues(
                                                          alpha: 0.7,
                                                        ),
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              boxShadow: isToday
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            const Color(
                                                              0xFFFF6B6B,
                                                            ).withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) =>
                        _buildEmptyState('Error loading volume data'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personal Records',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalRecordsPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // PR listeleme
                  bestLiftsAsync.when(
                    data: (lifts) {
                      if (lifts.isEmpty) {
                        return _buildEmptyState('No PRs yet');
                      }
                      final topLifts = lifts.take(3).toList();
                      return SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: topLifts.length,
                          itemBuilder: (context, index) {
                            final lift = topLifts[index];
                            final isFirst = index == 0;

                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isFirst
                                      ? [
                                          const Color.fromARGB(
                                            255,
                                            219,
                                            59,
                                            59,
                                          ).withValues(alpha: 0.7),
                                          const Color.fromARGB(
                                            255,
                                            177,
                                            67,
                                            67,
                                          ).withValues(alpha: 0.7),
                                        ]
                                      : [
                                          AppColors.surfaceDarkBlue,
                                          AppColors.surfaceDark,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isFirst
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF6B6B,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                border: isFirst
                                    ? null
                                    : Border.all(
                                        color: const Color(
                                          0xFFFF6B6B,
                                        ).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isFirst) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'TOP PR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Icon(
                                    Icons.emoji_events,
                                    color: isFirst
                                        ? Colors.white
                                        : const Color(0xFFFF6B6B),
                                    size: isFirst ? 40 : 36,
                                  ),

                                  Text(
                                    lift.exerciseName,
                                    style: TextStyle(
                                      color: isFirst
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${lift.weight} kg',
                                    style: TextStyle(
                                      color: isFirst
                                          ? Colors.white
                                          : const Color(0xFFFF6B6B),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => _buildEmptyState('Error loading records'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Workout Efficiency',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Antrenman verimliliğini hesaplama ve gösterme
                  averageDurationAsync.when(
                    data: (duration) {
                      final minutes = (duration.inSeconds / 60).ceil();
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDarkBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFFFF6B6B,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFFFF8E8E,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFFFF6B6B),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AVG DURATION',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$minutes',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        'min',
                                        style: TextStyle(
                                          color: Color(0xFFFF6B6B),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) =>
                        _buildEmptyState('Error loading efficiency data'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ActivityHeatMap extends StatelessWidget {
  final Map<DateTime, double> heatMap;

  const _ActivityHeatMap({required this.heatMap});

  Color _getColorForRatio(double ratio) {
    if (ratio <= 0) return AppColors.surfaceDarkBlue;
    if (ratio < 0.3) return const Color(0xFFFF6B6B).withValues(alpha: 0.3);
    if (ratio < 0.7) return const Color(0xFFFF6B6B).withValues(alpha: 0.6);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    // Şimdiki zamanı alma
    final now = DateTime.now();

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Ayın günlerini oluşturma
    final days = List.generate(daysInMonth, (index) {
      return DateTime(now.year, now.month, index + 1);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now).toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = days[index];
              final ratio = heatMap[date] ?? 0.0;

              return _HeatMapCell(
                date: date,
                ratio: ratio,
                color: _getColorForRatio(ratio),
                size: 24,
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Low',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 8),
              _HeatMapCell(
                date: DateTime.now(),
                ratio: 0.0,
                color: AppColors.surfaceDarkBlue,
                size: 12,
              ),
              const SizedBox(width: 4),
              _HeatMapCell(
                date: DateTime.now(),
                ratio: 0.25,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                size: 12,
              ),
              const SizedBox(width: 4),
              _HeatMapCell(
                date: DateTime.now(),
                ratio: 0.5,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                size: 12,
              ),
              const SizedBox(width: 4),
              _HeatMapCell(
                date: DateTime.now(),
                ratio: 1.0,
                color: const Color(0xFFFF6B6B),
                size: 12,
              ),
              const SizedBox(width: 8),
              const Text(
                'High',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatMapCell extends StatelessWidget {
  final DateTime date;
  final double ratio;
  final Color color;
  final double size;

  const _HeatMapCell({
    required this.date,
    required this.ratio,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${DateFormat('MMM d').format(date)}: ${(ratio * 100).toInt()}% completed',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
