import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Real, on-device system telemetry for the dashboard's stat tiles.
///
/// Deliberately does *not* fabricate a "CPU load" number — Flutter has no
/// cross-platform API for that without a native plugin, and a made-up
/// percentage would violate the same "don't fake it" rule the orb
/// animations follow. Every value here is genuinely measured.
class SystemStatsService {
  SystemStatsService(this._battery) : _startedAt = DateTime.now();

  final Battery _battery;
  final DateTime _startedAt;

  Future<int> batteryLevel() => _battery.batteryLevel;

  Future<BatteryState> batteryState() => _battery.batteryState;

  Duration get sessionUptime => DateTime.now().difference(_startedAt);

  /// Resident set size of the running app process, in MB — a real (if
  /// partial) view into memory pressure, not a system-wide figure.
  double appMemoryUsageMb() => ProcessInfo.currentRss / (1024 * 1024);

  /// Total on-disk size of the app's local database/cache directory.
  Future<double> localStorageUsageMb() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) return 0;
    var totalBytes = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }
}

final batteryProvider = Provider<Battery>((ref) => Battery());

final systemStatsServiceProvider = Provider<SystemStatsService>((ref) {
  return SystemStatsService(ref.watch(batteryProvider));
});
