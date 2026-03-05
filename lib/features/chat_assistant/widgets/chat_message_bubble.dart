import 'package:flutter/material.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'package:intl/intl.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? AppColors.primary
        : isDark
            ? AppColors.surfaceDark.withOpacity(0.85)
            : AppColors.greyLight.withOpacity(0.55);

    final textColor = isUser
        ? Colors.white
        : isDark
            ? AppColors.onSurfaceDark
            : AppColors.onSurfaceLight;

    final timeColor = isUser
        ? Colors.white70
        : isDark
            ? AppColors.textGreyDark
            : AppColors.textGreyLight;

    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAlignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(AppSpacing.borderRadiusL),
      topRight: const Radius.circular(AppSpacing.borderRadiusL),
      bottomLeft: isUser
          ? const Radius.circular(AppSpacing.borderRadiusL)
          : Radius.zero,
      bottomRight: isUser
          ? Radius.zero
          : const Radius.circular(AppSpacing.borderRadiusL),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: mainAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s + 2,
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                      strong: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: TextStyle(color: textColor),
                      h1: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      h2: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      h3: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                      code: TextStyle(
                        backgroundColor: isDark ? Colors.black26 : Colors.black12,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(fontSize: 11, color: timeColor),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.s),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
