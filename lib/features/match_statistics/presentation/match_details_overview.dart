import 'package:flutter/material.dart';
import 'package:frontend/models/match.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/widgets/custom_card.dart';

class MatchDetailsOverview extends StatelessWidget {
  final Match match;

  const MatchDetailsOverview({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '${DateFormat.yMMMMd().format(match.date)} | ${match.eventName ?? 'N/A'} | ${match.status.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Venue: ${match.venue ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}