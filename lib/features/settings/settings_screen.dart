import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream/core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text(localeState.locale.languageCode == 'tr' ? 'Türkçe' : 'English'),
            trailing: DropdownButton<String>(
              value: localeState.locale.languageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  localeNotifier.setLocale(Locale(newValue, newValue == 'tr' ? 'TR' : 'US'));
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Content Region'),
            subtitle: Text(localeState.region),
            trailing: DropdownButton<String>(
              value: localeState.region,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  localeNotifier.setRegion(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 'TR', child: Text('Turkey')),
                DropdownMenuItem(value: 'US', child: Text('USA')),
                DropdownMenuItem(value: 'DE', child: Text('Germany')),
                DropdownMenuItem(value: 'FR', child: Text('France')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Clear Cache', style: TextStyle(color: Colors.red)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared (Simulation)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
