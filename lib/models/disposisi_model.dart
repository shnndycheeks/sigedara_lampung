class DisposisiModel {
  final String id;
  final String suratId;
  final String? parentDisposisiId;
  final String dariUserId;
  final String dariRole;
  final String dariJabatan;
  final String kepadaUserId;
  final String kepadaRole;
  final String kepadaJabatan;
  final String? instruksi;
  final String? catatan;
  final String statusDisposisi; // 'pending', 'dibaca', 'diproses', 'selesai', 'ditarik', 'dibatalkan'
  final String ttdPng;
  final DateTime assignedAt;
  final DateTime? openedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  DisposisiModel({
    required this.id,
    required this.suratId,
    this.parentDisposisiId,
    required this.dariUserId,
    required this.dariRole,
    required this.dariJabatan,
    required this.kepadaUserId,
    required this.kepadaRole,
    required this.kepadaJabatan,
    this.instruksi,
    this.catatan,
    required this.statusDisposisi,
    required this.ttdPng,
    required this.assignedAt,
    this.openedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory DisposisiModel.fromJson(Map<String, dynamic> json) {
    return DisposisiModel(
      id: json['id'] ?? '',
      suratId: json['surat_id'] ?? '',
      parentDisposisiId: json['parent_disposisi_id']?.toString(),
      dariUserId: json['dari_user_id'] ?? '',
      dariRole: json['dari_role'] ?? '',
      dariJabatan: json['dari_jabatan'] ?? '',
      kepadaUserId: json['kepada_user_id'] ?? '',
      kepadaRole: json['kepada_role'] ?? '',
      kepadaJabatan: json['kepada_jabatan'] ?? '',
      instruksi: json['instruksi']?.toString(),
      catatan: json['catatan']?.toString(),
      statusDisposisi: json['status_disposisi'] ?? 'pending',
      ttdPng: json['ttd_png'] ?? '',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'].toString())
          : DateTime.now(),
      openedAt: json['opened_at'] != null
          ? DateTime.tryParse(json['opened_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surat_id': suratId,
      'parent_disposisi_id': parentDisposisiId,
      'dari_user_id': dariUserId,
      'dari_role': dariRole,
      'dari_jabatan': dariJabatan,
      'kepada_user_id': kepadaUserId,
      'kepada_role': kepadaRole,
      'kepada_jabatan': kepadaJabatan,
      'instruksi': instruksi,
      'catatan': catatan,
      'status_disposisi': statusDisposisi,
      'ttd_png': ttdPng,
      'assigned_at': assignedAt.toIso8601String(),
      'opened_at': openedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
