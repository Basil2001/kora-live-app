import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Monitors network connectivity status in real-time.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _controller;
  StreamSubscription? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onStatusChange {
    _controller ??= StreamController<bool>.broadcast();
    return _controller!.stream;
  }

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller?.add(_isOnline);
      }
    });
  }

  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _controller?.close();
  }
}

/// Global connectivity service instance
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for real-time connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange;
});

/// Simple boolean provider: is device online?
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (isOnline) => isOnline,
    loading: () => true,
    error: (_, __) => true,
  );
});
