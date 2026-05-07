import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.color,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color ?? AppColors.info),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: color ?? AppColors.info,
                ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: (iconColor ?? AppColors.textGreyLight).withOpacity(0.4),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textGreyLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.l),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final double? progress;

  const StatusChip({
    super.key,
    required this.status,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          label: Text(status),
          backgroundColor: statusColor.withOpacity(0.12),
          side: BorderSide(color: statusColor),
          labelStyle: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        if (progress != null && progress! > 0 && progress! < 1) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${(progress! * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class PlayerMarker extends StatelessWidget {
  final int? jerseyNumber;
  final bool isGoalkeeper;
  final bool isPlaceholder;
  final String? playerName;
  final VoidCallback? onTap;

  const PlayerMarker({
    super.key,
    this.jerseyNumber,
    this.isGoalkeeper = false,
    this.isPlaceholder = false,
    this.playerName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPlaceholder
                  ? (isGoalkeeper
                      ? AppColors.goalkeeperYellow
                      : Colors.black.withOpacity(0.3))
                  : (isGoalkeeper
                      ? AppColors.goalkeeperOrange
                      : Theme.of(context).colorScheme.primary),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: isPlaceholder
                  ? Icon(
                      isGoalkeeper ? Icons.pan_tool : Icons.add,
                      color: Colors.white54,
                      size: 24,
                    )
                  : Text(
                      jerseyNumber?.toString() ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          if (playerName != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                playerName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}