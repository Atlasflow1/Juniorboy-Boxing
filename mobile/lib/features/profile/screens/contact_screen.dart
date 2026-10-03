import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../providers/profile_provider.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? {};
    Future<void> open(Uri uri) async {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
            context.mounted) {
          showMessage(context, 'Could not open this link.');
}
      } catch (e) {
        if (context.mounted) showMessage(context, friendlyError(e));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            settings['coachName'] ?? 'Coach Sharif',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.mail, color: Colors.red),
            title: Text(
              (settings['email'] ?? '').isNotEmpty
                  ? settings['email']
                  : AppStrings.contactEmail,
            ),
            onTap: () => open(
              Uri(
                scheme: 'mailto',
                path: (settings['email'] ?? '').isNotEmpty
                    ? settings['email']
                    : AppStrings.contactEmail,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Operating Hours',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final entry
              in (settings['operatingHours'] as Map? ?? {}).entries)
            ListTile(
              title: Text(entry.key.toString()),
              trailing: Text(entry.value.toString()),
            ),
          if ((settings['operatingHours'] as Map? ?? {}).isEmpty)
            const Text('Contact the gym to confirm training hours.'),
        ],
      ),
    );
  }
}
