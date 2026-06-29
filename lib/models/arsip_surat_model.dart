import 'dart:convert';

class ArsipSurat {
  final String id;
  final String judul;
  final String kategori;
  final Map<String, dynamic> deskripsi;
  final String fileUrl;
  final String filePath;
  final int? fileSize;
  final String? uploadedBy;
  final String? createdBy;
  final DateTime createdAt;

  // Extracted metadata fields from deskripsi
  final String nomorSurat;
  final DateTime? tanggalSurat;
  final String dari;
  final String kepada;
  final String instruksiDisposisi;
  final String tingkatUrgensi;

  ArsipSurat({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.fileUrl,
    required this.filePath,
    this.fileSize,
    this.uploadedBy,
    this.createdBy,
    required this.createdAt,
    required this.nomorSurat,
    this.tanggalSurat,
    required this.dari,
    required this.kepada,
    required this.instruksiDisposisi,
    required this.tingkatUrgensi,
  });

  factory ArsipSurat.fromJson(Map<String, dynamic> json) {
    // Parse deskripsi JSON robustly (handles both Map and String formats)
    Map<String, dynamic> rawDeskripsi = {};
    final descRaw = json['deskripsi'];
    if (descRaw is Map) {
      rawDeskripsi = Map<String, dynamic>.from(descRaw);
    } else if (descRaw is String && descRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(descRaw);
        if (parsed is Map) {
          rawDeskripsi = Map<String, dynamic>.from(parsed);
        }
      } catch (_) {}
    }

    final tglRaw = rawDeskripsi['tanggal_surat'];
    DateTime? parsedTgl;
    if (tglRaw != null && tglRaw.toString().isNotEmpty) {
      parsedTgl = DateTime.tryParse(tglRaw.toString());
    }

    return ArsipSurat(
      id: json['id'] ?? '',
      judul: json['judul'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
      deskripsi: rawDeskripsi,
      fileUrl: json['file_url'] ?? '',
      filePath: json['file_path'] ?? '',
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      uploadedBy: json['uploaded_by']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      nomorSurat: rawDeskripsi['nomor_surat']?.toString() ?? '',
      tanggalSurat: parsedTgl,
      dari: rawDeskripsi['dari']?.toString() ?? '',
      kepada: rawDeskripsi['kepada']?.toString() ?? '',
      instruksiDisposisi: rawDeskripsi['instruksi_disposisi']?.toString() ?? '',
      tingkatUrgensi: rawDeskripsi['tingkat_urgensi']?.toString() ?? 'Biasa',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'file_url': fileUrl,
      'file_path': filePath,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
