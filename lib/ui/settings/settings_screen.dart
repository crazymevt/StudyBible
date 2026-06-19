import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_drawer.dart';

import '../../app/app_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDashboardOnStart = ref.watch(showDashboardOnStartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Show Dashboard on Startup'),
            subtitle: const Text('Launch directly to the dashboard instead of the reader'),
            value: showDashboardOnStart,
            onChanged: (value) {
              ref.read(showDashboardOnStartProvider.notifier).set(value);
            },
          ),
        ],
      ),
    );
  }
}
