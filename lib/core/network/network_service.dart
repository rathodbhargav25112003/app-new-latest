import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectionStatus { online, offline }

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<ConnectionStatus> _connectionStatusController =
  StreamController<ConnectionStatus>.broadcast();

  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  ConnectionStatus _currentStatus = ConnectionStatus.offline;
  ConnectionStatus get currentStatus => _currentStatus;

  Future<void> initialize() async {
    await updateConnectionStatus();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((_) => updateConnectionStatus());
  }

  Future<void> updateConnectionStatus() async {
    final connectivityResults = await _connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectionStatus.offline);
      return;
    }

    final hasInternet = await _connectionChecker.hasConnection;
    _updateStatus(hasInternet ? ConnectionStatus.online : ConnectionStatus.offline);
  }

  void _updateStatus(ConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _connectionStatusController.add(status);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}
