import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  final String id;
  final String clientId;
  final String clientName;
  final String providerId;
  final String providerName;
  final String message;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? clientPhone;
  final String? clientEmail;

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.clientPhone,
    this.clientEmail,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      message: data['message'] ?? '',
      status: RequestStatus.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      clientPhone: data['clientPhone'],
      clientEmail: data['clientEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'providerId': providerId,
      'providerName': providerName,
      'message': message,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
    };
  }
}

enum RequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.rejected:
        return 'rejected';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.cancelled:
        return 'cancelled';
    }
  }

  static RequestStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RequestStatus.pending;
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'En attente';
      case RequestStatus.accepted:
        return 'Acceptée';
      case RequestStatus.rejected:
        return 'Refusée';
      case RequestStatus.completed:
        return 'Terminée';
      case RequestStatus.cancelled:
        return 'Annulée';
    }
  }

  String get displayColor {
    switch (this) {
      case RequestStatus.pending:
        return '#F59E0B'; // Orange
      case RequestStatus.accepted:
        return '#10B981'; // Vert
      case RequestStatus.rejected:
        return '#EF4444'; // Rouge
      case RequestStatus.completed:
        return '#6366F1'; // Indigo
      case RequestStatus.cancelled:
        return '#64748B'; // Gris
    }
  }
}
