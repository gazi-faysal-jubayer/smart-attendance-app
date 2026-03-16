import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HardwareModeBanner extends StatelessWidget {
  final bool isConnected;
  final String? deviceInfo;
  final VoidCallback? onTap;

  const HardwareModeBanner({
    super.key,
    this.isConnected = false,
    this.deviceInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth_connected,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                deviceInfo ?? 'Hardware Mode Active',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
