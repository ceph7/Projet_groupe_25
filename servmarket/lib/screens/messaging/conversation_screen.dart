import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';

/// Écran de conversation détaillée
class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  final String? otherUserName;

  const ConversationScreen({
    super.key,
    required this.conversation,
    this.otherUserName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    final messagingProvider = context.read<MessagingProvider>();
    await messagingProvider.loadMessages(widget.conversation.id);
    
    // Marquer comme lus
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null && mounted) {
      await messagingProvider.markAsRead(
        widget.conversation.id,
        authProvider.currentUser!.uid,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (!mounted) return;

    final messagingProvider = context.read<MessagingProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser == null) return;

    try {
      await messagingProvider.sendMessage(
        conversationId: widget.conversation.id,
        senderId: authProvider.currentUser!.uid,
        content: content,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName ?? 'Conversation'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, messagingProvider, child) {
                if (messagingProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messagingProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(messagingProvider.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Reessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (messagingProvider.currentMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez votre premier message!',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messagingProvider.currentMessages.length,
                  itemBuilder: (context, index) {
                    final message = messagingProvider.currentMessages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ecrivez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isMyMessage = authProvider.currentUser?.uid == message.senderId;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMyMessage ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
