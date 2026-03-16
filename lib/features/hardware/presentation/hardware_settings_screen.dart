import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/hardware_repository_impl.dart';

class HardwareSettingsScreen extends ConsumerStatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  ConsumerState<HardwareSettingsScreen> createState() =>
      _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState
    extends ConsumerState<HardwareSettingsScreen> {
  final _brokerController =
      TextEditingController(text: 'broker.emqx.io');
  final _portController = TextEditingController(text: '8083');
  final _topicController =
      TextEditingController(text: 'kuet/attendance');

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(hardwareConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status
          Card(
            child: ListTile(
              leading: Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: isConnected ? AppColors.success : Colors.grey,
              ),
              title: Text(
                isConnected ? 'Connected' : 'Not Connected',
                style: TextStyle(
                  color: isConnected ? AppColors.success : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('MQTT WebSocket Connection'),
            ),
          ),

          const SizedBox(height: 24),

          // MQTT settings
          Text(
            'MQTT Connection',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _brokerController,
            decoration: const InputDecoration(
              labelText: 'Broker Address',
              hintText: 'e.g., broker.emqx.io',
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8083',
              prefixIcon: Icon(Icons.settings_ethernet),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic Prefix',
              hintText: 'kuet/attendance',
              prefixIcon: Icon(Icons.topic),
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              // Scaffold: show coming soon
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Hardware integration coming soon. This is a scaffold.'),
                ),
              );
            },
            icon: Icon(isConnected ? Icons.link_off : Icons.link),
            label: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),

          const SizedBox(height: 32),

          // Info card
          Card(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Hardware Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When connected to a KUET attendance hardware device, '
                    'attendance will be automatically captured via MQTT. '
                    'Students are identified by their roll numbers through '
                    'the connected scanner/reader.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
