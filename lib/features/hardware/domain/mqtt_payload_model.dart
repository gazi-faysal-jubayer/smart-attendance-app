// MQTT hardware integration scaffold.
// This is a placeholder for future hardware integration.
// The actual MQTT connection will be implemented when hardware
// devices are available for testing.

class MqttPayload {
  final String deviceId;
  final String topic;
  final Map<String, dynamic> data;
  final double? confidence;
  final DateTime timestamp;

  const MqttPayload({
    required this.deviceId,
    required this.topic,
    required this.data,
    this.confidence,
    required this.timestamp,
  });

  factory MqttPayload.fromJson(Map<String, dynamic> json) {
    return MqttPayload(
      deviceId: json['device_id'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
