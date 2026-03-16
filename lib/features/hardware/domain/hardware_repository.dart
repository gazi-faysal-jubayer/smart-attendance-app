// Abstract hardware repository for MQTT-based attendance devices.
// Scaffold only — to be implemented when hardware is available.

abstract class HardwareRepository {
  Future<void> connect(String broker, int port);
  Future<void> disconnect();
  Future<void> subscribeTopic(String topic);
  Stream<Map<String, dynamic>> get messageStream;
  bool get isConnected;
}
