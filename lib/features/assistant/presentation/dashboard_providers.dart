import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pre-filled draft the dashboard's quick-action chips hand off to the
/// Chat screen (e.g. tapping "Generate image" opens Chat with a starter
/// prompt already typed in, ready for the n8n backend's tool router to
/// pick up via `tool_used`).
final chatDraftProvider = StateProvider<String?>((ref) => null);

/// Cheap 5-second tick used to keep the dashboard's live stat tiles
/// (battery, network, memory) fresh without a full rebuild timer per
/// widget.
final dashboardTickerProvider = StreamProvider<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 5), (i) => i);
});
