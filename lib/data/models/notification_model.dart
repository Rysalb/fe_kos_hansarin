import 'dart:convert';

class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? targetRole;
  final String? targetUserId; // Add this field for user-specific notifications

  const NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.targetRole,
    this.targetUserId, // Add this parameter
  });

  // Update fromJson to include the new field
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id_notification'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      isRead: json['status'] == 'read',
      data: json['data'] != null 
          ? (json['data'] is String ? jsonDecode(json['data']) : json['data'])
          : null,
      targetRole: json['target_role'],
      targetUserId: json['target_user_id'],
    );
  }

  // Update toJson to include the new field
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'data': data != null ? jsonEncode(data) : null,
      'target_role': targetRole,
      'target_user_id': targetUserId,
    };
  }
}