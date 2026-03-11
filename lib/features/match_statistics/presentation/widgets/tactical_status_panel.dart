import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/services/tactical_alert_service.dart';
import 'package:provider/provider.dart';

class TacticalStatusPanel extends StatelessWidget {
  final bool isConnected;
  final TacticalAlert? lastAlert;

  const TacticalStatusPanel({
    super.key,
    required this.isConnected,
    this.lastAlert,
  });

  @override
  Widget build(BuildContext context) {
    if (lastAlert == null) {
      return CustomCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Tactical Status', style: TextStyle(fontWeight: FontWeight.bold)),
                _ConnectionIndicator(isConnected: isConnected),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            const Center(child: Text('Waiting for tactical data...', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Tactical Status', style: TextStyle(fontWeight: FontWeight.bold)),
              _ConnectionIndicator(isConnected: isConnected),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              _StatusItem(
                label: 'Time',
                value: lastAlert!.timestamp,
                icon: Icons.timer_outlined,
              ),
              const Spacer(),
              _SeverityIndicator(
                score: lastAlert!.severityScore,
                label: lastAlert!.severityLabel,
                color: lastAlert!.severityColor,
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          const Text('Active Decision', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            lastAlert!.decisionType,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.s),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    lastAlert!.action,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (lastAlert!.reviewCountdown > 0) ...[
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                const Icon(Icons.update, size: 14, color: Colors.grey),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Review in ${lastAlert!.reviewCountdown} windows',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
          const Divider(height: AppSpacing.xl),
          if (lastAlert!.feedback != 'none') ...[
            Row(
              children: [
                Icon(
                  lastAlert!.isAccepted ? Icons.check_circle : Icons.cancel,
                  size: 20,
                  color: lastAlert!.isAccepted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  lastAlert!.isAccepted ? 'RECOMMANDATION ACCEPTED' : 'RECOMMANDATION DISMISSED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: lastAlert!.isAccepted ? Colors.green : Colors.red,
                  ),
                ),
                if (lastAlert!.isEvaluated) ...[
                  const SizedBox(width: AppSpacing.s),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (lastAlert!.decisionEffective == true ? Colors.green : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lastAlert!.decisionEffective == true ? 'EFFECTIVE' : 'FAILED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: lastAlert!.decisionEffective == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleFeedback(context, 'accepted'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      foregroundColor: Colors.green,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleFeedback(context, 'dismissed'),
                    icon: const Icon(Icons.close),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleFeedback(BuildContext context, String feedback) {
    if (lastAlert != null) {
      context.read<TacticalAlertService>().submitFeedback(
        lastAlert!.matchId,
        lastAlert!.decisionId,
        feedback,
      );
    }
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatusItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  final double score;
  final String label;
  final Color color;

  const _SeverityIndicator({required this.score, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.m),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Score: ${(score).toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final bool isConnected;

  const _ConnectionIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected ? 'LIVE' : 'OFFLINE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
