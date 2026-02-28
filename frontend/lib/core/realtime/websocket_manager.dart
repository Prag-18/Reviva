import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../utils/token_storage.dart';

class WebSocketManager with WidgetsBindingObserver {
  WebSocketManager._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final WebSocketManager instance = WebSocketManager._();

  WebSocketChannel? _channel;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> _offlineQueue = [];

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  String? _connectedUserId;
  bool _isConnecting = false;
  bool _manuallyClosed = false;
  int _reconnectAttempt = 0;

  bool get isConnected => _channel != null;

  Future<void> connect(String userId) async {
    if (_isConnecting) return;
    if (isConnected && _connectedUserId == userId) return;

    _isConnecting = true;
    _manuallyClosed = false;
    _connectedUserId = userId;

    try {
      final token = await TokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      await _closeSocket();

      final wsUrl =
          '${AppConfig.baseUrl.replaceFirst('http', 'ws')}/chat/ws/$userId?token=$token';
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;
      _reconnectAttempt = 0;

      channel.stream.listen(
        (event) {
          if (event is String) {
            try {
              final decoded = jsonDecode(event);
              if (decoded is Map<String, dynamic>) {
                _streamController.add(decoded);
              } else if (decoded is String) {
                _streamController.add({'type': 'system', 'message': decoded});
              }
            } catch (_) {
              _streamController.add({'type': 'system', 'message': event});
            }
          }
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: false,
      );

      _flushQueue();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleDisconnect() {
    _channel = null;
    if (_manuallyClosed || _connectedUserId == null) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final userId = _connectedUserId;
    if (userId == null) return;
    _reconnectAttempt += 1;
    final delaySeconds = _reconnectAttempt > 5 ? 5 : _reconnectAttempt;
    Future<void>.delayed(Duration(seconds: delaySeconds), () {
      if (_manuallyClosed || _connectedUserId != userId) return;
      connect(userId);
    });
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _connectedUserId = null;
    _reconnectAttempt = 0;
    await _closeSocket();
  }

  Future<void> _closeSocket() async {
    if (_channel == null) return;
    try {
      await _channel!.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> send(Map<String, dynamic> payload) async {
    if (!isConnected) {
      _offlineQueue.add(payload);
      final userId = _connectedUserId;
      if (userId != null) {
        await connect(userId);
      }
      return;
    }
    _channel!.sink.add(jsonEncode(payload));
  }

  void _flushQueue() {
    if (!isConnected || _offlineQueue.isEmpty) return;
    final pending = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();
    for (final payload in pending) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = _connectedUserId;
    if (state == AppLifecycleState.resumed && userId != null) {
      connect(userId);
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _closeSocket();
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await disconnect();
    await _streamController.close();
  }
}
