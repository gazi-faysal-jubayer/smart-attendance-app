import 'package:flutter/material.dart';

class ExportOptionsSheet extends StatelessWidget {
  final VoidCallback onExport;

  const ExportOptionsSheet({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Export Options',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Download Excel report'),
              subtitle: const Text('Generates an XLSX file to device storage'),
              onTap: () {
                Navigator.pop(context);
                onExport();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
