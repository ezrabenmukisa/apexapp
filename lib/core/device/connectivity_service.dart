import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

class NetworkState extends Equatable {
  const NetworkState({required this.online, required this.onWifi});

  final bool online;
  final bool onWifi;

  @override
  List<Object?> get props => [online, onWifi];
}

/// Network reachability from the OS. "Online" means a network interface
/// is up; a request may still fail, so senders must handle errors.
@lazySingleton
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  Future<NetworkState> current() async =>
      _map(await _connectivity.checkConnectivity());

  Stream<NetworkState> watch() =>
      _connectivity.onConnectivityChanged.map(_map).distinct();

  static NetworkState _map(List<ConnectivityResult> results) => NetworkState(
    online: results.any((r) => r != ConnectivityResult.none),
    onWifi:
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet),
  );
}
