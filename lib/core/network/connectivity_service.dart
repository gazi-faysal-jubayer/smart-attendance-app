import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = false;

  ConnectivityService() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      _controller.add(_isOnline);
    });
    // Check initial state
    checkConnectivity();
  }

  Stream<bool> get isOnlineStream => _controller.stream;
  bool get isOnline => _isOnline;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _controller.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
