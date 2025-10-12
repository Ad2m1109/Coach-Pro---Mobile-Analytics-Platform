import 'package:flutter/material.dart';
import 'package:frontend/models/match.dart';
import 'package:intl/intl.dart';

class MatchDetailsOverview extends StatelessWidget {
  final Match match;

  const MatchDetailsOverview({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${match.homeTeam} ${match.homeScore} - ${match.awayScore} ${match.awayTeam}',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${DateFormat.yMMMMd().format(match.date)} | ${match.eventName ?? 'N/A'} | ${match.status.toUpperCase()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'Venue: ${match.venue ?? 'N/A'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}