class ActivityLogModel {
  final String id;
  final String? userId;
  final String? suratId;
  final String action;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    this.userId,
    this.suratId,
    required this.action,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? '',
      userId: json['user_id']?.toString(),
      suratId: json['surat_id']?.toString(),
      action: json['action'] ?? '',
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'])
          : null,
      ipAddress: json['ip_address']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'surat_id': suratId,
      'action': action,
      'details': details,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
