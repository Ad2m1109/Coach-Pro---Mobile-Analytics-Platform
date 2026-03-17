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

  Color _getStatusColor(BuildContext context) {
    switch (segment.status.toUpperCase()) {
      case 'COMPLETED':
        return Theme.of(context).colorScheme.primary;
      case 'PROCESSING':
        return Colors.orange;
      case 'FAILED':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).disabledColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        margin: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isActive ? statusColor.withOpacity(0.1) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
          border: Border.all(
            color: isActive ? statusColor : Theme.of(context).dividerColor.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive 
            ? [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 4, spreadRadius: 1)]
            : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PART ${segment.segmentIndex + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? statusColor : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              _getIconForStatus(segment.status),
              size: 20,
              color: statusColor,
            ),
            const SizedBox(height: 4),
            Text(
              '${(segment.startSec / 60).floor()}:${(segment.startSec % 60).toInt().toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
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
