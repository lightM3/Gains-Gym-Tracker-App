import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/utils/app_colors.dart';
import 'package:gains/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

// Kişisel rekorlar sayfası
class PersonalRecordsPage extends ConsumerWidget {
  const PersonalRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestLiftsAsync = ref.watch(bestLiftsProvider);

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
          'Personal Records',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: bestLiftsAsync.when(
        data: (lifts) {
          if (lifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No records found yet',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: lifts.length,
            itemBuilder: (context, index) {
              final lift = lifts[index];
              final dateStr = DateFormat(
                'MMM d, yyyy',
              ).format(lift.completedAt);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.primaryRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lift.exerciseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${lift.weight} kg',
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading records',
                style: TextStyle(
                  color: AppColors.error.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
