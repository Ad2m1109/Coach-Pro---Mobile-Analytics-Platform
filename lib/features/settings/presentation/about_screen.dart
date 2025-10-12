import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.about),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.sports_soccer,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations.version,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.appDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.gavel, color: Colors.white70),
                    title: Text(appLocalizations.termsOfService, style: Theme.of(context).textTheme.bodyLarge),
                    trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                    onTap: () {
                      // TODO: Navigate to Terms of Service
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Colors.white70),
                    title: Text(appLocalizations.privacyPolicy, style: Theme.of(context).textTheme.bodyLarge),
                    trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                    onTap: () {
                      // TODO: Navigate to Privacy Policy
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.copyright,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}