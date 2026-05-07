import 'package:flutter/material.dart';
import 'package:frontend/features/analyze/presentation/new_analysis_screen.dart';
import 'package:frontend/features/analyze/presentation/history_screen.dart';
import 'package:frontend/core/design_system/widgets/premium_app_bar.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AnalyzeScreen extends StatelessWidget {
  const AnalyzeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PremiumAppBar(
          title: appLocalizations.analyze,
          bottom: TabBar(
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: appLocalizations.newAnalysis),
              Tab(text: appLocalizations.history),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NewAnalysisScreen(),
            HistoryScreen(),
          ],
        ),
      ),
    );
  }
}
