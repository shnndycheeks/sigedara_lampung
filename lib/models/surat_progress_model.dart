class SuratProgressModel {
  final String suratId;
  final String nomorSurat;
  final String judul;
  final String statusGlobal;
  final int totalDisposisi;
  final int totalSelesai;
  final double progressPercent;

  SuratProgressModel({
    required this.suratId,
    required this.nomorSurat,
    required this.judul,
    required this.statusGlobal,
    required this.totalDisposisi,
    required this.totalSelesai,
    required this.progressPercent,
  });

  factory SuratProgressModel.fromJson(Map<String, dynamic> json) {
    return SuratProgressModel(
      suratId: json['surat_id'] ?? '',
      nomorSurat: json['nomor_surat'] ?? '',
      judul: json['judul'] ?? '',
      statusGlobal: json['status_global'] ?? 'menunggu_karo',
      totalDisposisi: json['total_disposisi'] != null
          ? int.parse(json['total_disposisi'].toString())
          : 0,
      totalSelesai: json['total_selesai'] != null
          ? int.parse(json['total_selesai'].toString())
          : 0,
      progressPercent: json['progress_percent'] != null
          ? double.parse(json['progress_percent'].toString())
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surat_id': suratId,
      'nomor_surat': nomorSurat,
      'judul': judul,
      'status_global': statusGlobal,
      'total_disposisi': totalDisposisi,
      'total_selesai': totalSelesai,
      'progress_percent': progressPercent,
    };
  }
}
