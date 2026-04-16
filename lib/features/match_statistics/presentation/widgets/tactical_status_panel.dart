import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/services/tactical_alert_service.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/design_system/app_colors.dart';

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
                const Text('COMMAND CENTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                _ConnectionIndicator(isConnected: isConnected),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            const Center(child: Text('Waiting for live tactical feed...', style: TextStyle(color: Colors.white10, fontSize: 12))),
          ],
        ),
      );
    }

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE COMMAND HUD',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live Match Intelligence',
                      style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 0.5),
                    ),
                  ],
                ),
                _ConnectionIndicator(isConnected: isConnected),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Alert Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusItem(
                      label: 'LAST UPDATE',
                      value: lastAlert!.timestamp,
                      icon: Icons.timer_outlined,
                    ),
                    _SeverityIndicator(
                      score: lastAlert!.severityScore,
                      label: lastAlert!.severityLabel,
                      color: lastAlert!.severityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'PRIMARY TACTICAL EVENT',
                  style: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  lastAlert!.decisionType.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lastAlert!.action,
                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Feedback Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastAlert!.feedback != 'none')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (lastAlert!.isAccepted ? Colors.green : Colors.red).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lastAlert!.isAccepted ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: lastAlert!.isAccepted ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          lastAlert!.isAccepted ? 'STRATEGY ADOPTED' : 'STRATEGY IGNORED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: lastAlert!.isAccepted ? Colors.green : Colors.red,
                          ),
                        ),
                        if (lastAlert!.isEvaluated) ...[
                          const Spacer(),
                          Text(
                            lastAlert!.decisionEffective == true ? 'EFFECTIVE' : 'FAILED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lastAlert!.decisionEffective == true ? Colors.green : Colors.red),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _CommandButton(
                          label: 'ACCEPT',
                          icon: Icons.check,
                          color: Colors.green,
                          onPressed: () => _handleFeedback(context, 'accepted'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CommandButton(
                          label: 'DISMISS',
                          icon: Icons.close,
                          color: Colors.red,
                          onPressed: () => _handleFeedback(context, 'dismissed'),
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 32, color: Colors.white10),

          // Team HUD Feed
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEAM LIVE DYNAMICS',
                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamStatusColumn(
                        teamName: 'TEAM A',
                        tags: lastAlert!.teamATags ?? [],
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TeamStatusColumn(
                        teamName: 'TEAM B',
                        tags: lastAlert!.teamBTags ?? [],
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (lastAlert!.tacticalOutlier != null) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _OutlierInsight(outlier: lastAlert!.tacticalOutlier!),
            ),
          ],
          
          const SizedBox(height: 8),
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
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.bold),
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
class _TeamStatusColumn extends StatelessWidget {
  final String teamName;
  final List<TacticalTag> tags;
  final Color color;

  const _TeamStatusColumn({
    required this.teamName,
    required this.tags,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 2, color: color),
            const SizedBox(width: 6),
            Text(teamName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.1)),
          ],
        ),
        const SizedBox(height: 16),
        _buildChannelReadout(context, 'DEF LINE', 'DEFENSIVE_LINE'),
        const Divider(height: 12, color: Colors.white10),
        _buildChannelReadout(context, 'WIDTH', 'WIDTH'),
        const Divider(height: 12, color: Colors.white10),
        _buildChannelReadout(context, 'COMPACT', 'COMPACTNESS'),
        const Divider(height: 12, color: Colors.white10),
        _buildChannelReadout(context, 'SPEED', 'SPEED'),
        const Divider(height: 12, color: Colors.white10),
        _buildChannelReadout(context, 'PRESSING', 'PRESSING'),
      ],
    );
  }

  Widget _buildChannelReadout(BuildContext context, String label, String category) {
    final tag = _getTagForCategory(category);
    final bool hasComment = tag != null;
    final String tagText = (tag?.tag ?? 'OPERATIONAL').toUpperCase();
    final String description = tag?.description ?? 'Monitoring...';

    Color statusColor = hasComment ? color : Colors.white10;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 45,
          child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tagText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              if (hasComment) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 9, height: 1.2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  TacticalTag? _getTagForCategory(String category) {
    final patterns = {
      'DEFENSIVE_LINE': ['LINE', 'DEPTH', 'OFFSIDE'],
      'WIDTH': ['WIDTH', 'WIDE', 'STRETCHED'],
      'COMPACTNESS': ['COMPACT', 'GAPS', 'DISCONNECTED'],
      'SPEED': ['SPEED', 'TRANSITION', 'FAST', 'SLOW'],
      'PRESSING': ['PRESS', 'CLOSE', 'INTENSITY'],
    };
    
    final categoryPatterns = patterns[category] ?? [];
    try {
      return tags.firstWhere(
        (t) {
          final name = t.tag.toUpperCase();
          return categoryPatterns.any((p) => name.contains(p));
        },
      );
    } catch (_) {
      return null;
    }
  }
}

class _OutlierInsight extends StatelessWidget {
  final Map<String, dynamic> outlier;

  const _OutlierInsight({required this.outlier});

  @override
  Widget build(BuildContext context) {
    final String playerId = outlier['player_id']?.toString() ?? '?';
    final String reason = outlier['reason'] ?? 'Structural deviate';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TACTICAL OUTLIER REPORT',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  'Player #$playerId behavior: $reason',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _CommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }
}
