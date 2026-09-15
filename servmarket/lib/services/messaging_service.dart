import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/conversation.dart';

/// Service de messagerie
/// Gère les conversations et messages via Firestore
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _maxMessageLength = 1000;

  /// Collection conversations
  CollectionReference get _conversationsCollection =>
      _firestore.collection('conversations');

  /// Collection messages
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  /// Nettoie et valide le contenu d'un message
  String _cleanContent(String content) {
    // Trim et suppression des espaces multiples
    String cleaned = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Limitation de longueur
    if (cleaned.length > _maxMessageLength) {
      cleaned = cleaned.substring(0, _maxMessageLength);
    }
    
    return cleaned;
  }

  /// Obtient ou crée une conversation entre deux utilisateurs
  /// Retourne l'ID de la conversation
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    // Trier les IDs pour avoir une clé unique
    final sortedIds = [userId1, userId2]..sort();
    final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

    final docRef = _conversationsCollection.doc(conversationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Créer la conversation
      await docRef.set({
        'participantIds': sortedIds,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageContent': null,
        'unreadCount': 0,
      });
    }

    return conversationId;
  }

  /// Envoie un message dans une conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    // Nettoyer le contenu
    final cleanedContent = _cleanContent(content);
    
    if (cleanedContent.isEmpty) {
      throw Exception('Le message ne peut pas être vide');
    }

    // Créer le message
    final messageRef = _messagesCollection.doc();
    final message = Message(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      content: cleanedContent,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await messageRef.set(message.toMap());

    // Mettre à jour la conversation
    await _conversationsCollection.doc(conversationId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageContent': cleanedContent,
    });
  }

  /// Marque les messages comme lus pour un utilisateur
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final messagesQuery = _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false);

    final snapshot = await messagesQuery.get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  /// Stream des messages d'une conversation (temps réel)
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// Stream des conversations d'un utilisateur (temps réel)
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _conversationsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Conversation.fromFirestore(doc)).toList();
    });
  }

  /// Compte les messages non lus pour un utilisateur
  Stream<int> getUnreadCountStream(String userId) {
    return _conversationsCollection
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += data['unreadCount'] as int? ?? 0;
      }
      return total;
    });
  }

  /// Supprime une conversation et tous ses messages
  Future<void> deleteConversation(String conversationId) async {
    // Supprimer tous les messages de la conversation
    final messagesSnapshot = await _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Supprimer la conversation
    await _conversationsCollection.doc(conversationId).delete();
  }
}
