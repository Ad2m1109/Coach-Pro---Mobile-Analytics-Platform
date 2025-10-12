
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/analysis_report.dart';
import 'package:frontend/services/analysis_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/widgets/analysis_report_card.dart'; // Import the new widget

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger data fetch when the screen initializes
    Provider.of<AnalysisService>(context, listen: false).getAnalysisHistory();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Consumer<AnalysisService>(
      builder: (context, analysisService, child) {
        if (analysisService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (analysisService.errorMessage != null) {
          return Center(child: Text('${appLocalizations.errorWithMessage(analysisService.errorMessage!)}'));
        } else if (analysisService.reports.isEmpty) {
          return Center(child: Text(appLocalizations.noAnalysisHistoryFound));
        }

        final reports = analysisService.reports;
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return AnalysisReportCard(report: report); // Use the new widget
          },
        );
      },
    );
  }
}
