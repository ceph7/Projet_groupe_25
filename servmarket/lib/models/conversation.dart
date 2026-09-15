import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de conversation
class Conversation {
  final String id;
  final List<String> participantIds;
  final DateTime lastMessageAt;
  final String? lastMessageContent;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.lastMessageAt,
    this.lastMessageContent,
    this.unreadCount = 0,
  });

  /// Crée une Conversation depuis un document Firestore
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] as List),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      lastMessageContent: data['lastMessageContent'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageContent': lastMessageContent,
      'unreadCount': unreadCount,
    };
  }

  /// Crée une copie avec certains champs modifiés
  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Vérifie si un utilisateur est participant
  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }

  /// Retourne l'autre participant (pour les conversations 1-1)
  String? getOtherParticipant(String currentUserId) {
    if (participantIds.length != 2) return null;
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
