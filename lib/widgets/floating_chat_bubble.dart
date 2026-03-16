import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/services/chat_bubble_notifier.dart';
import 'package:frontend/features/chat_assistant/chat_assistant_page.dart';

/// A floating, draggable chat bubble that opens the AI Assistant overlay.
/// Works like the Messenger chat head — tap to open, drag to reposition.
class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({super.key});

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  // Position of the bubble (bottom-right by default)
  double _xPos = -1; // sentinel: -1 means "not initialized"
	  double _yPos = -1;
	  bool _isDragging = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const double _bubbleSize = 56.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initPositionIfNeeded(BuildContext context) {
    if (_xPos < 0 || _yPos < 0) {
      final size = MediaQuery.of(context).size;
      _xPos = size.width - _bubbleSize - 16;
      _yPos = size.height - _bubbleSize - 120; // above bottom nav
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<ChatBubbleNotifier>(context);
    if (!notifier.isVisible) return const SizedBox.shrink();

    _initPositionIfNeeded(context);
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Chat Overlay ──
        if (notifier.isChatOpen) _buildChatOverlay(context, notifier),

        // ── Draggable Bubble ──
	        if (!notifier.isChatOpen)
	          AnimatedPositioned(
	            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400),
	            curve: Curves.elasticOut,
	            left: _xPos,
	            top: _yPos,
	            child: GestureDetector(
	              onPanStart: (_) {
	                setState(() {
	                  _isDragging = true;
	                });
	              },
	              onPanUpdate: (details) {
	                setState(() {
	                  _xPos = (_xPos + details.delta.dx)
	                      .clamp(0.0, screenSize.width - _bubbleSize);
	                  _yPos = (_yPos + details.delta.dy)
	                      .clamp(0.0, screenSize.height - _bubbleSize - 100);
	                });
	              },
	              onPanEnd: (_) {
	                // Snap to nearest edge
	                setState(() {
	                  _isDragging = false;
	                  final midX = screenSize.width / 2;
	                  // Snap to left or right edge with 16px margin
	                  _xPos = _xPos < midX ? 16.0 : screenSize.width - _bubbleSize - 16;
	                });
	              },
	              onTap: () => notifier.openChat(),
	              child: ScaleTransition(
	                scale: _pulseAnimation,
	                child: Container(
	                  width: _bubbleSize,
	                  height: _bubbleSize,
	                  decoration: BoxDecoration(
	                    shape: BoxShape.circle,
	                    gradient: const LinearGradient(
	                      begin: Alignment.topLeft,
	                      end: Alignment.bottomRight,
	                      colors: [
	                        AppColors.primary,
	                        AppColors.primaryDark,
	                      ],
	                    ),
	                    boxShadow: [
	                      BoxShadow(
	                        color: AppColors.primary.withOpacity(0.4),
	                        blurRadius: 12,
	                        spreadRadius: 2,
	                        offset: const Offset(0, 4),
	                      ),
	                    ],
	                  ),
	                  child: const Icon(
	                    Icons.smart_toy_rounded,
	                    color: Colors.white,
	                    size: 28,
	                  ),
	                ),
	              ),
	            ),
	          ),
      ],
    );
  }

  Widget _buildChatOverlay(BuildContext context, ChatBubbleNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 50,
            bottom: 70,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── Custom header bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Minimize button
                    InkWell(
                      onTap: () => notifier.closeChat(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Chat content ──
              const Expanded(
                child: ChatAssistantPage(embedded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
