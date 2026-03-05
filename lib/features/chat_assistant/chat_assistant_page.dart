import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/assistant_service.dart';
import 'package:frontend/core/design_system/app_colors.dart';
import 'package:frontend/core/design_system/app_spacing.dart';
import 'widgets/chat_message_bubble.dart';

class ChatAssistantPage extends StatefulWidget {
  final bool embedded;
  const ChatAssistantPage({super.key, this.embedded = false});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final AssistantService _assistantService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Typing indicator animation
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Welcome message
    _messages.add(ChatMessage(
      text:
          'Hello! I\'m your AI football analytics assistant. Ask me anything about your team\'s performance, tactics, or match analysis.',
      isUser: false,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _assistantService = AssistantService(apiClient: apiClient);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    _focusNode.requestFocus();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _assistantService.query(text);

      setState(() {
        _messages.add(ChatMessage(text: response.answer, isUser: false));
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: ${e.message}',
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Something went wrong. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    // When embedded in the floating overlay, skip Scaffold/AppBar
    if (widget.embedded) {
      return Container(
        color: bgColor,
        child: Column(
          children: [
            Expanded(child: _buildMessageList(isDark)),
            _buildInputArea(isDark),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusS),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 20),
            ),
            const SizedBox(width: AppSpacing.s),
            const Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList(isDark)),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: 'Chat cleared. How can I help you?',
        isUser: false,
      ));
    });
  }

  Widget _buildMessageList(bool isDark) {
    if (_messages.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpacing.m,
        bottom: AppSpacing.s,
      ),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator(isDark);
        }
        return ChatMessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Start a conversation',
            style: TextStyle(
                fontSize: 16, color: AppColors.primary.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.smart_toy_rounded,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.s),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: AppSpacing.s + 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withOpacity(0.85)
                  : AppColors.greyLight.withOpacity(0.55),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.borderRadiusL),
                topRight: Radius.circular(AppSpacing.borderRadiusL),
                bottomRight: Radius.circular(AppSpacing.borderRadiusL),
              ),
            ),
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final value = _dotsController.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final opacity =
                        ((value + delay) % 1.0 < 0.5) ? 1.0 : 0.35;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Text(
            'AI is thinking...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.textGreyDark : AppColors.textGreyLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask about tactics, formations...',
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: AppSpacing.s),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusXL),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusXL),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusXL),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Material(
            color: _isLoading
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXL),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXL),
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
