import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Live network status, used by the dashboard's "Network Status" tile and
/// by the outbox flusher (which drains queued requests the moment the
/// device comes back online).
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged.map(_toStatus);
});

NetworkStatus _toStatus(List<ConnectivityResult> results) {
  final hasConnection = results.any((r) => r != ConnectivityResult.none);
  return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
}

Future<NetworkStatus> currentNetworkStatus(Connectivity connectivity) async {
  return _toStatus(await connectivity.checkConnectivity());
}
