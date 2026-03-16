import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // MQTT
  static String get mqttBrokerUrl =>
      dotenv.env['MQTT_DEFAULT_BROKER'] ?? 'broker.emqx.io';
  static int get mqttPort =>
      int.tryParse(dotenv.env['MQTT_DEFAULT_PORT'] ?? '8083') ?? 8083;
  static String get mqttTopicPrefix =>
      dotenv.env['MQTT_TOPIC_PREFIX'] ?? 'kuet/attendance';
  static double get confidenceThreshold =>
      double.tryParse(dotenv.env['CONFIDENCE_THRESHOLD'] ?? '0.80') ?? 0.80;

  // Department → student count mapping
  static const Map<String, Map<String, int>> deptStudentCounts = {
    'CSE': {'theory': 120, 'lab': 60},
    'EEE': {'theory': 120, 'lab': 60},
    'ME': {'theory': 120, 'lab': 60},
    'CE': {'theory': 60, 'lab': 30},
    'IPE': {'theory': 60, 'lab': 30},
    'ECE': {'theory': 60, 'lab': 30},
    'BME': {'theory': 30, 'lab': 30},
    'MSE': {'theory': 30, 'lab': 30},
  };

  static const Map<String, int> defaultStudentCounts = {
    'theory': 60,
    'lab': 30,
  };

  static int getStudentCount(String department, String type) {
    return deptStudentCounts[department]?[type] ??
        defaultStudentCounts[type] ??
        60;
  }

  // Departments list
  static const List<String> departments = [
    'CSE', 'EEE', 'ME', 'CE', 'IPE', 'ECE', 'BME', 'MSE', 'Other',
  ];

  // Status labels
  static const Map<String, String> statusLabels = {
    'P': 'Present',
    'A': 'Absent',
    'LA': 'Late',
    'E': 'Excused',
  };
}
