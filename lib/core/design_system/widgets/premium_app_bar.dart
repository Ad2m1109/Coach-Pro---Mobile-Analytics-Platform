import 'package:flutter/material.dart';
import 'package:frontend/core/design_system/app_colors.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title; // Can be String or Widget
  final List<Widget>? actions;
  final bool showLogo;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.centerTitle = false,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use white text for both modes if we use a dark/primary gradient
    const titleColor = Colors.white;
    final gradientColor = isDark ? Colors.black : AppColors.primary;

    Widget titleWidget;
    if (title is String) {
      titleWidget = Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title as String,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: titleColor,
                ),
          ),
          if (!centerTitle)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    !isDark ? Colors.white : AppColors.primary,
                    (!isDark ? Colors.white : AppColors.primary)
                        .withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      );
    } else {
      titleWidget = title as Widget;
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: centerTitle,
      bottom: bottom,
      iconTheme: IconThemeData(color: titleColor),
      leading: leading ??
          (showLogo
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      // Apply brightness-aware color filter if needed, 
                      // but usually logos should be original or white.
                    ),
                  ),
                )
              : null),
      title: titleWidget,
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientColor.withOpacity(isDark ? 0.8 : 0.95),
              gradientColor.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + 10 + (bottom?.preferredSize.height ?? 0.0));
}
