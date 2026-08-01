import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/usage_event.dart';

/// Local usage/analytics log. Every real interaction in the app (a chat
/// message sent, a voice turn, an automation run) calls [logEvent] once;
/// the analytics dashboard aggregates this same log rather than showing
/// synthetic numbers.
class AnalyticsRepository {
  AnalyticsRepository(this._box);

  final Box _box;
  static const _uuid = Uuid();
  static const _key = 'events';
  static const _maxEvents = 5000;

  List<UsageEvent> getEvents() {
    final raw = _box.get(_key) as List?;
    if (raw == null) return [];
    return raw.map((e) => UsageEvent.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> logEvent(UsageEventType type, {int estimatedTokens = 0}) async {
    final events = getEvents()
      ..add(UsageEvent(
        id: _uuid.v4(),
        type: type,
        timestamp: DateTime.now(),
        estimatedTokens: estimatedTokens,
      ));
    final trimmed = events.length > _maxEvents
        ? events.sublist(events.length - _maxEvents)
        : events;
    await _box.put(_key, trimmed.map((e) => e.toJson()).toList());
  }

  int countByType(UsageEventType type, {DateTime? since}) {
    return getEvents()
        .where((e) => e.type == type && (since == null || e.timestamp.isAfter(since)))
        .length;
  }

  int get totalTokens => getEvents().fold(0, (sum, e) => sum + e.estimatedTokens);

  /// Daily message counts for the last [days] days, oldest first — feeds
  /// the dashboard's productivity/usage line chart.
  List<int> dailyCounts(UsageEventType type, {int days = 7}) {
    final now = DateTime.now();
    final buckets = List.filled(days, 0);
    for (final event in getEvents().where((e) => e.type == type)) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day))
          .inDays;
      if (diff >= 0 && diff < days) {
        buckets[days - 1 - diff]++;
      }
    }
    return buckets;
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(hiveServiceProvider).analyticsBox);
});
