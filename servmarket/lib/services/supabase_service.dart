import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

/// Service centralisant la messagerie temps réel via Supabase.
/// Fonctionnalité bonus — couvre les issues #29 (ouverture/reprise de
/// conversation), #30 (persistance Postgres), #31 (synchronisation temps
/// réel), #33 (sécurité RLS), #34 (nettoyage et limitation du contenu).
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const int _maxMessageLength = 1000; // issue #34

  /// Issue #29 : Ouverture/reprise de conversation — récupère l'historique
  /// existant entre deux utilisateurs (ou liste vide si première prise de contact).
  Future<List<MessageModel>> loadConversation(
    String userIdA,
    String userIdB,
  ) async {
    final conversationId = MessageModel.conversationIdFor(userIdA, userIdB);

    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => MessageModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Issue #30 : Persistance des messages (Postgres) — envoi et stockage
  /// durable d'un nouveau message.
  /// Issue #34 : Nettoyage et limitation du contenu avant envoi.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final cleaned = _sanitize(content);
    if (cleaned.isEmpty) return;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': cleaned,
    });
  }

  /// Issue #31 : Synchronisation temps réel — flux des nouveaux messages
  /// d'une conversation, mis à jour instantanément sans rechargement manuel.
  Stream<List<MessageModel>> watchConversation(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((row) => MessageModel.fromMap(row)).toList());
  }

  /// Issue #34 : Nettoyage et limitation du contenu (trim + longueur maximale).
  /// La sécurité de fond (accès aux conversations) reste garantie côté serveur
  /// par les politiques RLS (issue #33), déployées sur le projet Supabase.
  String _sanitize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length <= _maxMessageLength) return trimmed;
    return trimmed.substring(0, _maxMessageLength);
  }
}