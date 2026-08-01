import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../assistant/presentation/dashboard_providers.dart';
import '../domain/chat_message.dart';
import 'chat_providers.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _activeChatId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final sessions = ref.read(chatSessionsProvider);
    if (sessions.isNotEmpty) {
      setState(() => _activeChatId = sessions.first.id);
      return;
    }
    final session = await ref.read(chatSessionsProvider.notifier).createSession();
    if (mounted) setState(() => _activeChatId = session.id);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = _activeChatId;
    if (chatId == null) {
      return const Scaffold(backgroundColor: Colors.transparent, body: SizedBox.shrink());
    }

    final chatState = ref.watch(chatControllerProvider(chatId));
    ref.listen(chatControllerProvider(chatId), (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0) || next.streamingText != null) {
        _scrollToBottom();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final sessions = ref.watch(chatSessionsProvider);
    final activeSession = sessions.where((s) => s.id == chatId).firstOrNull;

    final draft = ref.watch(chatDraftProvider);
    if (draft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatDraftProvider.notifier).state = null;
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(activeSession?.title ?? 'JARVIS Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New chat',
            onPressed: () async {
              final session = await ref.read(chatSessionsProvider.notifier).createSession();
              setState(() => _activeChatId = session.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Sessions',
            onPressed: () => _openSessions(context, chatId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty && chatState.streamingText == null
                ? const _EmptyChatState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: chatState.messages.length + (chatState.streamingText != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return _StreamingBubble(text: chatState.streamingText!);
                      }
                      final message = chatState.messages[index];
                      return MessageBubble(
                        message: message,
                        onRegenerate: (!message.isUser && index == chatState.messages.length - 1)
                            ? () => ref.read(chatControllerProvider(chatId).notifier).regenerateLast()
                            : null,
                      );
                    },
                  ),
          ),
          if (chatState.isSending && chatState.streamingText == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Align(alignment: Alignment.centerLeft, child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TypingIndicator(),
              )),
            ),
          ChatComposer(
            key: ValueKey('composer-$chatId-${draft ?? ""}'),
            isSending: chatState.isSending,
            initialText: draft,
            onSend: (text) => ref.read(chatControllerProvider(chatId).notifier).sendText(text),
          ),
        ],
      ),
    );
  }

  void _openSessions(BuildContext context, String currentChatId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SessionsSheet(
        currentChatId: currentChatId,
        onSelect: (id) {
          setState(() => _activeChatId = id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return MessageBubble(
      message: ChatMessage(id: 'streaming', chatId: '', text: text, isUser: false, timestamp: DateTime.now()),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: AppColors.auroraGradient),
                boxShadow: [BoxShadow(color: AppColors.primaryGlow.withValues(alpha: 0.3), blurRadius: 30)],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Ask JARVIS anything', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Chat, generate code, analyze documents, or hand off a task —\nyour conversation stays on-device and syncs through your n8n backend.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsSheet extends ConsumerWidget {
  const _SessionsSheet({required this.currentChatId, required this.onSelect});
  final String currentChatId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(chatSessionsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversations', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          s.pinned ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded,
                          color: s.id == currentChatId ? AppColors.primaryGlow : AppColors.textSecondary,
                          size: 18,
                        ),
                        title: Text(s.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: s.lastMessagePreview.isEmpty
                            ? null
                            : Text(s.lastMessagePreview, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
                          onSelected: (action) {
                            final notifier = ref.read(chatSessionsProvider.notifier);
                            if (action == 'pin') notifier.togglePinned(s.id);
                            if (action == 'delete') notifier.delete(s.id);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'pin', child: Text(s.pinned ? 'Unpin' : 'Pin')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onTap: () => onSelect(s.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
