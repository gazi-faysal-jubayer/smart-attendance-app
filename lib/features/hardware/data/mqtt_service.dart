import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// MQTT service scaffold for future hardware integration.
class MqttService {
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  late MqttServerClient _client;
  bool _connected = false;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _connected;

  Future<void> connect({
    required String broker,
    required int port,
    String clientId = 'kuet_attendance_app',
  }) async {
    _client = MqttServerClient(broker, clientId);
    _client.port = port;
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.secure = port == 8883;
    _client.useWebSocket = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
      _connected = true;
    } catch (_) {
      _connected = false;
      _client.disconnect();
      rethrow;
    }
  }

  Future<void> subscribe(String topic) async {
    if (!_connected) return;
    _client.subscribe(topic, MqttQos.atMostOnce);
    _client.updates?.listen((messages) {
      for (final m in messages) {
        final recMess = m.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _messageController.add({'topic': m.topic, 'payload': payload});
      }
    });
  }

  Future<void> publish(String topic, String message) async {
    if (!_connected) return;
    final builder = MqttClientPayloadBuilder()..addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  Future<void> disconnect() async {
    if (_connected) {
      _client.disconnect();
    }
    _connected = false;
    await _messageController.close();
  }

  void _onDisconnected() {
    _connected = false;
  }

  void _onConnected() {
    _connected = true;
  }
}
