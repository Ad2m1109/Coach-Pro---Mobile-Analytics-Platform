import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/services/tactical_alert_service.dart';
import 'package:provider/provider.dart';

class SeverityTimelineTable extends StatelessWidget {
  final List<TacticalAlert> alerts;
  final ValueChanged<TacticalAlert>? onAlertTap;
  final String? selectedDecisionId;

  const SeverityTimelineTable({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.selectedDecisionId,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text('No tactical events recorded yet.', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    // Sort alerts by timestamp descending (newest first)
    final sortedAlerts = alerts.toList().reversed.toList();

    return Column(
      children: sortedAlerts
          .map(
            (alert) => _TimelineItem(
              alert: alert,
              onTap: onAlertTap,
              isSelected: selectedDecisionId == alert.decisionId,
            ),
          )
          .toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TacticalAlert alert;
  final ValueChanged<TacticalAlert>? onTap;
  final bool isSelected;

  const _TimelineItem({required this.alert, this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(alert),
        child: CustomCard(
          color: isSelected ? alert.severityColor.withValues(alpha: 0.08) : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: IntrinsicHeight(
            child: Row(
            children: [
              Container(
                width: 45,
                alignment: Alignment.center,
                child: Text(
                  alert.timestamp,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              VerticalDivider(color: alert.severityColor, thickness: 3, width: 20),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            alert.decisionType,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: alert.severityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.status,
                            style: TextStyle(
                              color: alert.severityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.action,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (alert.feedback != 'none') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            alert.isAccepted ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: alert.isAccepted ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alert.isAccepted ? 'Accepted' : 'Dismissed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: alert.isAccepted ? Colors.green : Colors.red,
                            ),
                          ),
                          if (alert.isEvaluated) ...[
                            const SizedBox(width: AppSpacing.s),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (alert.decisionEffective == true ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.decisionEffective == true ? 'EFFECTIVE' : 'FAILED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: alert.decisionEffective == true ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _FeedbackButton(
                            label: 'Accept',
                            icon: Icons.check,
                            color: Colors.green,
                            onPressed: () => _handleFeedback(context, 'accepted'),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          _FeedbackButton(
                            label: 'Dismiss',
                            icon: Icons.close,
                            color: Colors.red,
                            onPressed: () => _handleFeedback(context, 'dismissed'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                alert.severityLabel,
                style: TextStyle(
                  color: alert.severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFeedback(BuildContext context, String feedback) {
    context.read<TacticalAlertService>().submitFeedback(
      alert.matchId,
      alert.decisionId,
      feedback,
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
