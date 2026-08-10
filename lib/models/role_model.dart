class RoleModel {
  final String id;
  final String namaRole;
  final String? deskripsi;
  final DateTime? createdAt;

  RoleModel({
    required this.id,
    required this.namaRole,
    this.deskripsi,
    this.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? '',
      namaRole: json['nama_role'] ?? json['nama'] ?? '',
      deskripsi: json['deskripsi']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_role': namaRole,
      'deskripsi': deskripsi,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
