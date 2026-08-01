import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../automation/presentation/automation_providers.dart';
import '../../memory/presentation/memory_providers.dart';
import '../../tasks/presentation/tasks_providers.dart';
import '../data/analytics_repository.dart';
import '../domain/usage_event.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsRepositoryProvider);
    final chatDaily = analytics.dailyCounts(UsageEventType.chatMessage);
    final voiceDaily = analytics.dailyCounts(UsageEventType.voiceInteraction);
    final workflows = ref.watch(workflowsProvider);
    final tasks = ref.watch(tasksProvider);
    final memories = ref.watch(memoriesProvider);

    final automationRuns = workflows.length;
    final successfulRuns = workflows.where((w) => w.lastStatus?.name == 'success').length;
    final successRate = automationRuns == 0 ? 0.0 : successfulRuns / automationRuns;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              StatTile(icon: Icons.chat_bubble_outline, label: 'Chat messages (7d)', value: '${chatDaily.fold(0, (a, b) => a + b)}', color: AppColors.primaryGlow),
              StatTile(icon: Icons.graphic_eq_rounded, label: 'Voice turns (7d)', value: '${voiceDaily.fold(0, (a, b) => a + b)}', color: AppColors.secondaryGlow),
              StatTile(icon: Icons.checklist_rounded, label: 'Tasks completed', value: '${tasks.where((t) => t.completed).length}', color: AppColors.success),
              StatTile(icon: Icons.psychology_rounded, label: 'Memories stored', value: '${memories.length}', color: AppColors.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Usage trend', icon: Icons.show_chart),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _line(chatDaily, AppColors.primaryGlow),
                    _line(voiceDaily, AppColors.secondaryGlow),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Automation success rate', icon: Icons.bolt_outlined),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        PieChartSectionData(value: successRate * 100, color: AppColors.success, showTitle: false, radius: 14),
                        PieChartSectionData(value: (1 - successRate) * 100, color: AppColors.glassFillStrong, showTitle: false, radius: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(successRate * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('$successfulRuns of $automationRuns workflows last ran successfully', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Estimated token consumption', icon: Icons.token_outlined),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '${analytics.totalTokens} tokens logged across all conversations',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<int> values, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i].toDouble())],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
    );
  }
}
