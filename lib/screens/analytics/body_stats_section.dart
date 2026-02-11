import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/providers/user_provider.dart';
import 'package:gains/utils/app_colors.dart';
import 'package:intl/intl.dart';

class BodyStatsSection extends ConsumerWidget {
  const BodyStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final historyAsync = ref.watch(bodyMeasurementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body Stats',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        userProfileAsync.when(
          data: (profile) {
            return Row(
              children: [
                Expanded(
                  child: _buildCurrentStatCard(
                    'Weight',
                    profile.weight != null
                        ? '${profile.weight!.toStringAsFixed(1)}'
                        : '--',
                    'kg',
                    Icons.monitor_weight_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCurrentStatCard(
                    'Body Fat',
                    profile.bodyFat != null
                        ? '${profile.bodyFat!.toStringAsFixed(1)}'
                        : '--',
                    '%',
                    Icons.accessibility_new_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 32),
        const Text(
          'Measurement History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No history data available.\nUpdate your stats in Profile to track progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            final recentHistory = history.take(15).toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Colors.white.withValues(alpha: 0.05),
                  ),
                  dataRowColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.transparent;
                  }),
                  horizontalMargin: 16,
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Weight',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Body Fat',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows: List.generate(recentHistory.length, (index) {
                    final item = recentHistory[index];
                    final dateStr = DateFormat('MMM d').format(item.date);

                    // Bir sonraki kayıtla (listede daha eski olan) aradaki değişimi hesaplama
                    String changeText = '-';
                    Color changeColor = AppColors.textSecondary;

                    if (index < recentHistory.length - 1) {
                      final prevItem = recentHistory[index + 1];
                      final diff = item.weight - prevItem.weight;
                      if (diff > 0) {
                        changeText = '+${diff.toStringAsFixed(1)}';
                        changeColor =
                            AppColors.error; // Kilo artışı (genelde kırmızı)
                      } else if (diff < 0) {
                        changeText = diff.toStringAsFixed(1);
                        changeColor =
                            Colors.green; // Kilo kaybı (genelde yeşil)
                      } else {
                        changeText = '0.0';
                      }
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${item.weight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.bodyFat != null
                                ? '${item.bodyFat!.toStringAsFixed(1)}%'
                                : '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            changeText,
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildCurrentStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
