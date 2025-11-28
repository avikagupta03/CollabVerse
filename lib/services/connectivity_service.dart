import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Periodically check connectivity
    Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      // Try to access Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to read a document to verify connectivity
        await FirebaseFirestore.instance
            .collection('_connectivity_test')
            .doc('test')
            .get()
            .timeout(const Duration(seconds: 5));

        final newStatus = true;
        if (_isConnected != newStatus) {
          _isConnected = newStatus;
          _connectionStatusController.add(_isConnected);
        }
      }
    } catch (e) {
      final newStatus = false;
      if (_isConnected != newStatus) {
        _isConnected = newStatus;
        _connectionStatusController.add(_isConnected);
      }
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
