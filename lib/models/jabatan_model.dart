class JabatanModel {
  final String id;
  final String namaJabatan;
  final String? kategoriEselon;
  final DateTime? createdAt;

  JabatanModel({
    required this.id,
    required this.namaJabatan,
    this.kategoriEselon,
    this.createdAt,
  });

  factory JabatanModel.fromJson(Map<String, dynamic> json) {
    return JabatanModel(
      id: json['id'] ?? '',
      namaJabatan: json['nama_jabatan'] ?? json['nama'] ?? '',
      kategoriEselon: json['kategori_eselon']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_jabatan': namaJabatan,
      'kategori_eselon': kategoriEselon,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
