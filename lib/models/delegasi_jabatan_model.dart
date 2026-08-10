class DelegasiJabatanModel {
  final String id;
  final String pejabatAsliId;
  final String pejabatPenggantiId;
  final String alasan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String status;
  final DateTime createdAt;

  DelegasiJabatanModel({
    required this.id,
    required this.pejabatAsliId,
    required this.pejabatPenggantiId,
    required this.alasan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.status = 'aktif',
    required this.createdAt,
  });

  factory DelegasiJabatanModel.fromJson(Map<String, dynamic> json) {
    return DelegasiJabatanModel(
      id: json['id'] ?? '',
      pejabatAsliId: json['pejabat_asli_id'] ?? '',
      pejabatPenggantiId: json['pejabat_pengganti_id'] ?? '',
      alasan: json['alasan'] ?? '',
      tanggalMulai: DateTime.parse(
        json['tanggal_mulai'] ?? DateTime.now().toIso8601String(),
      ),
      tanggalSelesai: DateTime.parse(
        json['tanggal_selesai'] ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'aktif',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pejabat_asli_id': pejabatAsliId,
      'pejabat_pengganti_id': pejabatPenggantiId,
      'alasan': alasan,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
