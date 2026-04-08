import 'package:flutter/material.dart';
import 'package:frontend/models/analysis_segment.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

class AnalysisTimeline extends StatelessWidget {
  final List<AnalysisSegment> segments;
  final String? activeSegmentId;
  final Function(AnalysisSegment) onSegmentTap;
  final bool isAnalyzing;

  const AnalysisTimeline({
    super.key,
    required this.segments,
    this.activeSegmentId,
    required this.onSegmentTap,
    this.isAnalyzing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty && !isAnalyzing) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Row(
            children: [
              Icon(Icons.auto_graph, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Analysis Timeline',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              if (isAnalyzing)
                _PulseIndicator(),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            itemCount: segments.length + (isAnalyzing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == segments.length) {
                return _LoadingTimelineItem();
              }

              final segment = segments[index];
              final isActive = segment.id == activeSegmentId;
              
              return _TimelineItem(
                segment: segment,
                isActive: isActive,
                onTap: () => onSegmentTap(segment),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final AnalysisSegment segment;
  final bool isActive;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.segment,
    required this.isActive,
    required this.onTap,
  });

  Color _getSeverityColor(BuildContext context, String label) {
    switch (label.toUpperCase()) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.amber;
      case 'LOW': return Colors.blue;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor(BuildContext context) {
    if (segment.status.toUpperCase() == 'PROCESSING') return Colors.orange;
    if (segment.status.toUpperCase() == 'FAILED') return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final colorA = _getSeverityColor(context, segment.teamASeverityLabel);
    final colorB = _getSeverityColor(context, segment.teamBSeverityLabel);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        margin: const EdgeInsets.all(AppSpacing.xs),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isActive ? statusColor.withOpacity(0.08) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          border: Border.all(
            color: isActive ? statusColor : Theme.of(context).dividerColor.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Dual Team Indicators (Left side bars)
            Positioned(
              left: 4,
              top: 10,
              bottom: 10,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: colorA,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: colorB,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PART ${segment.segmentIndex + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isActive ? statusColor : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'A',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorA),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _getIconForStatus(segment.status),
                        size: 14,
                        color: statusColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'B',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorB),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(segment.startSec / 60).floor()}:${(segment.startSec % 60).toInt().toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'PROCESSING':
        return Icons.sync;
      case 'FAILED':
        return Icons.error_outline;
      default:
        return Icons.hourglass_empty;
    }
  }
}

class _LoadingTimelineItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Text(
          'LIVE',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
