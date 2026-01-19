import 'package:flutter/material.dart';
import '../core/design_system/app_spacing.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.m),
          child: child,
        ),
      ),
    );
  }
}
