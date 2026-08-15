import 'dart:convert';
import 'disposisi_model.dart';

class ArsipSurat {
  final String id;
  final String judul;
  final String kategori;
  final Map<String, dynamic> deskripsi;
  final String fileUrl;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final String? extension;
  final String? checksum;
  final String? uploadedBy;
  final String? createdBy;
  final String statusGlobal; // 'menunggu_karo', 'dalam_proses', 'selesai', 'dibatalkan'
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  // Metadata Fields
  final String nomorSurat;
  final DateTime? tanggalSurat;
  final DateTime? tanggalDiterima;
  final String dari;
  final String kepada;
  final String noAgenda;
  final String tingkatUrgensi;

  // Relational Disposisi History (populated when joined)
  final List<DisposisiModel> listDisposisi;

  String get statusLabel {
    switch (statusGlobal.toLowerCase()) {
      case 'menunggu_karo':
        return 'Menunggu Disposisi Kepala Biro';
      case 'menunggu_kabag':
        if (listKabagTarget.isNotEmpty) {
          return 'Menunggu Disposisi ${listKabagTarget.join(", ")}';
        }
        return 'Menunggu Disposisi Kabag';
      case 'menunggu_katim':
        if (listKatimTarget.isNotEmpty) {
          return 'Menunggu ${listKatimTarget.join(", ")}';
        }
        return 'Menunggu Katim';
      case 'dalam_proses':
        if (listDisposisi.isNotEmpty) {
          final pendingDisposisi = listDisposisi.where((d) => d.statusDisposisi == 'pending' || d.statusDisposisi == 'dibaca');
          if (pendingDisposisi.isNotEmpty) {
            return 'Menunggu ${pendingDisposisi.first.kepadaJabatan}';
          }
        }
        return 'Sedang Diproses';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Menunggu Disposisi Kepala Biro';
    }
  }

  /// Record Disposisi yang dibuat oleh Karo
  List<DisposisiModel> get listKaroDisposisi {
    return listDisposisi.where((d) {
      final dari = d.dariJabatan.toLowerCase().trim();
      final role = d.dariRole.toLowerCase().trim();
      final isExplicitKaro = dari.contains('biro') ||
          dari.contains('karo') ||
          role.contains('karo') ||
          role.contains('biro') ||
          role.contains('kepala_biro') ||
          dari == 'karo';
      if (isExplicitKaro) return true;

      final isKabag = dari.contains('kabag') || dari.contains('bagian') || role.contains('kabag');
      final isKatim = dari.contains('katim') || dari.contains('tim kerja') || role.contains('katim');
      if (!isKabag && !isKatim && (d.parentDisposisiId == null || d.parentDisposisiId!.isEmpty)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Record Disposisi yang dibuat oleh Kabag
  List<DisposisiModel> get listKabagDisposisi {
    final karoIds = listKaroDisposisi.map((d) => d.id).toSet();
    return listDisposisi.where((d) {
      if (karoIds.contains(d.id)) return false;
      final dari = d.dariJabatan.toLowerCase().trim();
      final role = d.dariRole.toLowerCase().trim();
      final isKaro = dari.contains('biro') ||
          dari.contains('karo') ||
          role.contains('karo') ||
          role.contains('biro') ||
          role.contains('kepala_biro') ||
          dari == 'karo';
      if (isKaro) return false;

      final isKabag = dari.contains('kabag') || dari.contains('bagian') || role.contains('kabag');
      if (isKabag) return true;

      if (d.parentDisposisiId != null && d.parentDisposisiId!.isNotEmpty) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Targeted Kabags from Karo Disposisi
  List<String> get listKabagTarget {
    return listKaroDisposisi
        .where((d) => d.statusDisposisi != 'ditarik')
        .map((d) => d.kepadaJabatan)
        .toSet()
        .toList();
  }

  /// Targeted Katims from Kabag Disposisi
  List<String> get listKatimTarget {
    return listKabagDisposisi
        .where((d) => d.statusDisposisi != 'ditarik')
        .map((d) => d.kepadaJabatan)
        .toSet()
        .toList();
  }


  // Backward compatibility getters for UI screens
  String get penerimaLevel {
    if (listDisposisi.isNotEmpty) {
      return listDisposisi.last.kepadaJabatan;
    }
    return deskripsi['penerima_level']?.toString() ?? 'Bapak Kepala Biro Umum';
  }

  List<Map<String, dynamic>> get riwayatDisposisi {
    if (listDisposisi.isNotEmpty) {
      return listDisposisi.map((d) => d.toJson()).toList();
    }
    final raw = deskripsi['riwayat_disposisi'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  String get instruksiDisposisi {
    if (listDisposisi.isNotEmpty) {
      return listDisposisi.last.instruksi ?? deskripsi['instruksi_disposisi']?.toString() ?? '';
    }
    return '';
  }

  String get statusPengiriman => statusGlobal;

  List<String> get diteruskanKepada {
    if (listDisposisi.isNotEmpty) {
      return listDisposisi.map((d) => d.kepadaJabatan).toSet().toList();
    }
    return [];
  }

  ArsipSurat({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.fileUrl,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.extension,
    this.checksum,
    this.uploadedBy,
    this.createdBy,
    this.statusGlobal = 'menunggu_karo',
    required this.createdAt,
    this.deletedAt,
    this.deletedBy,
    required this.nomorSurat,
    this.tanggalSurat,
    this.tanggalDiterima,
    required this.dari,
    required this.kepada,
    this.noAgenda = '-',
    required this.tingkatUrgensi,
    this.listDisposisi = const [],
    String? instruksiDisposisi,
    String? statusPengiriman,
  });

  factory ArsipSurat.fromJson(Map<String, dynamic> json) {
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

    final tglSuratRaw = json['tanggal_surat'] ?? rawDeskripsi['tanggal_surat'];
    DateTime? parsedTglSurat;
    if (tglSuratRaw != null && tglSuratRaw.toString().isNotEmpty) {
      parsedTglSurat = DateTime.tryParse(tglSuratRaw.toString());
    }

    final tglDiterimaRaw = json['tanggal_diterima'] ?? rawDeskripsi['tanggal_diterima'];
    DateTime? parsedTglDiterima;
    if (tglDiterimaRaw != null && tglDiterimaRaw.toString().isNotEmpty) {
      parsedTglDiterima = DateTime.tryParse(tglDiterimaRaw.toString());
    }

    final List<Map<String, dynamic>> rawCombined = [];
    final Set<String> existingIds = {};

    if (json['disposisi'] is List) {
      for (final item in (json['disposisi'] as List)) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          rawCombined.add(map);
          if (id.isNotEmpty) existingIds.add(id);
        }
      }
    }

    if (rawDeskripsi['list_disposisi'] is List) {
      for (final item in (rawDeskripsi['list_disposisi'] as List)) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty || !existingIds.contains(id)) {
            rawCombined.add(map);
            if (id.isNotEmpty) existingIds.add(id);
          }
        }
      }
    }

    List<DisposisiModel> disposisiList = rawCombined
        .map((e) => DisposisiModel.fromJson(e))
        .toList();

    return ArsipSurat(
      id: json['id'] ?? '',
      judul: json['judul'] ?? json['perihal'] ?? rawDeskripsi['judul'] ?? '',
      kategori: json['kategori'] ?? 'Keuangan',
      deskripsi: rawDeskripsi,
      fileUrl: json['file_url'] ?? '',
      filePath: json['file_path'] ?? '',
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      mimeType: json['mime_type']?.toString(),
      extension: json['extension']?.toString(),
      checksum: json['checksum']?.toString(),
      uploadedBy: json['uploaded_by']?.toString(),
      createdBy: json['created_by']?.toString(),
      statusGlobal: json['status_global'] ?? rawDeskripsi['status_pengiriman'] ?? 'menunggu_karo',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      deletedBy: json['deleted_by']?.toString(),
      nomorSurat: json['nomor_surat'] ?? rawDeskripsi['nomor_surat'] ?? '',
      tanggalSurat: parsedTglSurat,
      tanggalDiterima: parsedTglDiterima,
      dari: json['dari'] ?? rawDeskripsi['dari'] ?? '',
      kepada: json['kepada'] ?? rawDeskripsi['kepada'] ?? '',
      noAgenda: json['no_agenda'] ?? rawDeskripsi['no_agenda'] ?? '-',
      tingkatUrgensi: json['tingkat_urgensi'] ?? rawDeskripsi['tingkat_urgensi'] ?? 'Biasa',
      listDisposisi: disposisiList,
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
      'mime_type': mimeType,
      'extension': extension,
      'checksum': checksum,
      'uploaded_by': uploadedBy,
      'status_global': statusGlobal,
      'nomor_surat': nomorSurat,
      'tanggal_surat': tanggalSurat?.toIso8601String(),
      'tanggal_diterima': tanggalDiterima?.toIso8601String(),
      'dari': dari,
      'kepada': kepada,
      'no_agenda': noAgenda,
      'tingkat_urgensi': tingkatUrgensi,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
