import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/messaging_service.dart';

/// Provider pour la messagerie
class MessagingProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService.instance;

  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _errorMessage;

  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les conversations de l'utilisateur
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messagingService.getConversationsStream(userId).listen((conversations) {
        _conversations = conversations;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des conversations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les messages d'une conversation
  Future<void> loadMessages(String conversationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messagingService.getMessagesStream(conversationId).listen((messages) {
        _currentMessages = messages;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des messages: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ouvre ou crée une conversation avec un autre utilisateur
  Future<String> openConversation(String currentUserId, String otherUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversationId = await _messagingService.getOrCreateConversation(
        currentUserId,
        otherUserId,
      );
      
      // Charger les messages
      await loadMessages(conversationId);
      
      _isLoading = false;
      notifyListeners();
      
      return conversationId;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ouverture de la conversation: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Envoie un message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
      );
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'envoi du message: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Marque les messages comme lus
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _messagingService.markMessagesAsRead(conversationId, userId);
    } catch (e) {
      _errorMessage = 'Erreur lors du marquage des messages: $e';
      notifyListeners();
    }
  }

  /// Définit la conversation courante
  void setCurrentConversation(Conversation? conversation) {
    _currentConversation = conversation;
    notifyListeners();
  }

  /// Réinitialise les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Supprime une conversation
  Future<void> deleteConversation(String conversationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _messagingService.deleteConversation(conversationId);
      
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _currentMessages = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
}
