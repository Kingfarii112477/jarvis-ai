import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/system_stats_service.dart';
import '../../../../shared/widgets/stat_tile.dart';
import '../dashboard_providers.dart';

class SystemStatsRow extends ConsumerWidget {
  const SystemStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dashboardTickerProvider);
    final stats = ref.watch(systemStatsServiceProvider);
    final network = ref.watch(networkStatusProvider);

    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SizedBox(
            width: 150,
            child: FutureBuilder<int>(
              future: stats.batteryLevel(),
              builder: (context, snapshot) => StatTile(
                icon: Icons.battery_charging_full_rounded,
                label: 'Battery',
                value: snapshot.hasData ? '${snapshot.data}%' : '—',
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 150,
            child: StatTile(
              icon: Icons.wifi_rounded,
              label: 'Network',
              value: network.value == NetworkStatus.online ? 'Online' : 'Offline',
              color: network.value == NetworkStatus.online ? AppColors.primaryGlow : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 150,
            child: StatTile(
              icon: Icons.memory_rounded,
              label: 'App memory',
              value: '${stats.appMemoryUsageMb().toStringAsFixed(0)} MB',
              color: AppColors.secondaryGlow,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 150,
            child: StatTile(
              icon: Icons.schedule_rounded,
              label: 'Session',
              value: _formatDuration(stats.sessionUptime),
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
