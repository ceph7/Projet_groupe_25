import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation.dart';
import '../../models/user_profile.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'conversation_screen.dart';

/// Écran liste des conversations
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    final messagingProvider = context.read<MessagingProvider>();
    
    if (authProvider.currentUser != null) {
      await messagingProvider.loadConversations(authProvider.currentUser!.uid);
    }
  }

  Future<UserProfile?> _getUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId];
    }
    
    final profile = await FirestoreService.instance.getUserProfile(userId);
    if (profile != null) {
      setState(() {
        _userProfiles[userId] = profile;
      });
    }
    return profile;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isProvider = authProvider.user?.role == UserRole.provider;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Rediriger vers l'écran approprié pour trouver des utilisateurs
          if (isProvider) {
            // Pour les prestataires, aller vers la liste des demandes de service
            Navigator.pushReplacementNamed(context, '/provider_requests');
          } else {
            // Pour les clients, aller vers la liste des prestataires
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        child: const Icon(Icons.add_comment),
        tooltip: isProvider ? 'Voir les demandes' : 'Trouver un prestataire',
      ),
      body: Consumer<MessagingProvider>(
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
                    onPressed: _loadConversations,
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }

          if (messagingProvider.conversations.isEmpty) {
            final authProvider = context.read<AuthProvider>();
            final isProvider = authProvider.user?.role == UserRole.provider;
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isProvider 
                        ? 'Contactez un client pour démarrer'
                        : 'Contactez un prestataire pour démarrer',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: messagingProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = messagingProvider.conversations[index];
              final authProvider = context.read<AuthProvider>();
              final otherUserId = conversation.getOtherParticipant(authProvider.currentUser?.uid ?? '');
              
              return FutureBuilder<UserProfile?>(
                future: _getUserProfile(otherUserId ?? ''),
                builder: (context, snapshot) {
                  final otherUser = snapshot.data;
                  return _ConversationTile(
                    conversation: conversation,
                    otherUserName: otherUser?.displayName ?? otherUser?.email ?? 'Utilisateur inconnu',
                    onTap: () {
                      messagingProvider.setCurrentConversation(conversation);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConversationScreen(
                            conversation: conversation,
                            otherUserName: otherUser?.displayName ?? otherUser?.email ?? 'Utilisateur',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String otherUserName;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(Icons.person, color: Colors.grey[600]),
      ),
      title: Text(
        otherUserName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation.lastMessageContent ?? 'Nouvelle conversation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _formatDate(conversation.lastMessageAt),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'A l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
