import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'connectivity_service.dart';

class WebSocketService {
  final Ref _ref;
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  StreamController<Map<String, dynamic>>? _eventController;

  WebSocketService(this._ref) {
    _eventController = StreamController<Map<String, dynamic>>.broadcast();
    
    // Listen to network status to reconnect when back online
    _ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (next && _channel == null) {
        _connect();
      }
    });
  }

  Stream<Map<String, dynamic>> get eventStream => _eventController!.stream;

  void init() {
    _shouldReconnect = true;
    _connect();
  }

  void _connect() {
    if (_isConnecting || _channel != null) return;
    
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) return;

    _isConnecting = true;
    final wsUrl = _getUrl();
    debugPrint('🔌 WebSockets: Connecting to $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) => _onMessageReceived(message),
        onError: (error) => _onConnectionError(error),
        onDone: () => _onConnectionClosed(),
      );
    } catch (e) {
      _onConnectionError(e);
    }
  }

  String _getUrl() {
    const String appKey = 'kora_app_key';
    if (kReleaseMode) {
      return 'wss://api.kora.app/app/$appKey?protocol=7&client=js&version=7.0.3&flash=false';
    }
    if (kIsWeb) {
      return 'ws://localhost:8000/app/$appKey?protocol=7&client=js&version=7.0.3&flash=false';
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ws://10.0.2.2:8000/app/$appKey?protocol=7&client=js&version=7.0.3&flash=false';
      }
    } catch (_) {}
    return 'ws://localhost:8000/app/$appKey?protocol=7&client=js&version=7.0.3&flash=false';
  }

  void _onMessageReceived(dynamic message) {
    _isConnecting = false;
    try {
      final payload = jsonDecode(message.toString());
      final String? event = payload['event'];
      
      if (event == 'pusher:connection_established') {
        debugPrint('✅ WebSockets: Connection established!');
        _subscribeToChannel('matches');
      } else if (event != null && !event.startsWith('pusher:')) {
        final dataField = payload['data'];
        if (dataField is String) {
          final decodedData = jsonDecode(dataField);
          _eventController?.add({
            'event': event,
            'channel': payload['channel'],
            'data': decodedData,
          });
        } else if (dataField is Map<String, dynamic>) {
          _eventController?.add({
            'event': event,
            'channel': payload['channel'],
            'data': dataField,
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ WebSockets: Error decoding message: $e');
    }
  }

  void _subscribeToChannel(String channelName) {
    if (_channel == null) return;
    debugPrint('📤 WebSockets: Subscribing to $channelName');
    final frame = {
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
      }
    };
    _channel!.sink.add(jsonEncode(frame));
  }

  void _onConnectionError(dynamic error) {
    debugPrint('❌ WebSockets: Connection error: $error');
    _cleanupChannel();
    _scheduleReconnect();
  }

  void _onConnectionClosed() {
    debugPrint('🔌 WebSockets: Connection closed.');
    _cleanupChannel();
    _scheduleReconnect();
  }

  void _cleanupChannel() {
    _isConnecting = false;
    _channel = null;
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('🔄 WebSockets: Attempting reconnection...');
      _connect();
    });
  }

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _eventController?.close();
  }
}

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
