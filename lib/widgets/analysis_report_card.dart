import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_report.dart';

class AnalysisReportCard extends StatelessWidget {
  final AnalysisReport report;

  const AnalysisReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: const Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
        title: Text(report.reportType ?? 'Analysis Report', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(
          'Analyzed on: ${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Text('Completed', style: TextStyle(color: Colors.green)),
      ),
    );
  }
}
