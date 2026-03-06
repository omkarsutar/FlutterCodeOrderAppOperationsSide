import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that monitors internet connectivity status.
/// Uses connectivity_plus to detect network changes in real-time.
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// One-shot async check: returns true if device has any network connection.
  /// Used inside service layer methods to guard API calls.
  static Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}

/// Streams the current connectivity status as a boolean (true = online).
/// Emits immediately with the current state, then on every change.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});
