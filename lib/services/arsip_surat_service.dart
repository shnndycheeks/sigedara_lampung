import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/arsip_surat_model.dart';

class ArsipSuratService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'arsip_surat';
  static const String _bucketName = 'arsip-surat';

  /// Memuat seluruh arsip surat aktif (yang belum di-soft-delete)
  static Future<List<ArsipSurat>> getSemuaArsip() async {
    try {
      final data = await _client
          .from(_tableName)
          .select('*, disposisi(*)')
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) {
        final rawDeskripsi = json['deskripsi'] is Map ? Map<String, dynamic>.from(json['deskripsi']) : <String, dynamic>{};
        final List<Map<String, dynamic>> combinedDisposisi = [];

        if (json['disposisi'] is List) {
          combinedDisposisi.addAll(List<Map<String, dynamic>>.from(json['disposisi']));
        }

        if (rawDeskripsi['list_disposisi'] is List) {
          final deskripsiDisposisi = List<Map<String, dynamic>>.from(rawDeskripsi['list_disposisi']);
          final existingIds = combinedDisposisi.map((d) => d['id']?.toString()).toSet();
          for (final item in deskripsiDisposisi) {
            if (!existingIds.contains(item['id']?.toString())) {
              combinedDisposisi.add(item);
            }
          }
        }
        json['disposisi'] = combinedDisposisi;
        return ArsipSurat.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat arsip surat: $e');
      throw Exception('Gagal memuat arsip surat: $e');
    }
  }

  /// Memuat detail 1 surat beserta seluruh riwayat disposisinya
  static Future<ArsipSurat> getArsipById(String id) async {
    try {
      final data = await _client
          .from(_tableName)
          .select('*, disposisi(*)')
          .eq('id', id)
          .filter('deleted_at', 'is', null)
          .single();

      final json = Map<String, dynamic>.from(data);

      final rawDeskripsi = json['deskripsi'] is Map ? Map<String, dynamic>.from(json['deskripsi']) : <String, dynamic>{};
      final Map<String, Map<String, dynamic>> mergedMap = {};

      if (rawDeskripsi['list_disposisi'] is List) {
        for (final item in List<Map<String, dynamic>>.from(rawDeskripsi['list_disposisi'])) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            mergedMap[id] = Map<String, dynamic>.from(item);
          }
        }
      }

      if (json['disposisi'] is List) {
        for (final item in List<Map<String, dynamic>>.from(json['disposisi'])) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            if (mergedMap.containsKey(id)) {
              final existing = mergedMap[id]!;
              item.forEach((key, val) {
                if (val != null && val.toString().isNotEmpty) {
                  existing[key] = val;
                }
              });
            } else {
              mergedMap[id] = Map<String, dynamic>.from(item);
            }
          }
        }
      }

      final List<Map<String, dynamic>> combinedDisposisi = mergedMap.values.toList();
      combinedDisposisi.sort((a, b) {
        final t1 = DateTime.tryParse(a['assigned_at']?.toString() ?? '') ?? DateTime.now();
        final t2 = DateTime.tryParse(b['assigned_at']?.toString() ?? '') ?? DateTime.now();
        return t1.compareTo(t2);
      });

      json['disposisi'] = combinedDisposisi;
      return ArsipSurat.fromJson(json);
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat detail arsip surat ($id): $e');
      throw Exception('Gagal memuat detail arsip surat: $e');
    }
  }

  /// Menambah surat baru ke tabel arsip_surat (TU Upload)
  static Future<void> tambahArsip({
    required String judul,
    required String kategori,
    required Map<String, dynamic> deskripsi,
    required String fileUrl,
    required String filePath,
    required int fileSize,
    String? nomorSurat,
    DateTime? tanggalSurat,
    DateTime? tanggalDiterima,
    String? dari,
    String? kepada,
    String? noAgenda,
    String? tingkatUrgensi,
    String? mimeType,
    String? extension,
    String? checksum,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final userId = user?.id;

      final pNomorSurat = nomorSurat ?? deskripsi['nomor_surat']?.toString() ?? 'SRT-${DateTime.now().millisecondsSinceEpoch}';
      final pDari = dari ?? deskripsi['dari']?.toString() ?? 'Instansi Pengirim';
      final pKepada = kepada ?? deskripsi['kepada']?.toString() ?? 'Kepala Biro Umum';
      final pNoAgenda = noAgenda ?? deskripsi['no_agenda']?.toString() ?? '-';
      final pTingkatUrgensi = tingkatUrgensi ?? deskripsi['tingkat_urgensi']?.toString() ?? 'Biasa';
      
      DateTime? pTglSurat = tanggalSurat;
      if (pTglSurat == null && deskripsi['tanggal_surat'] != null) {
        try {
          pTglSurat = DateTime.parse(deskripsi['tanggal_surat'].toString());
        } catch (_) {}
      }
      pTglSurat ??= DateTime.now();

      DateTime? pTglDiterima = tanggalDiterima;
      if (pTglDiterima == null && deskripsi['tanggal_diterima'] != null) {
        try {
          pTglDiterima = DateTime.parse(deskripsi['tanggal_diterima'].toString());
        } catch (_) {}
      }
      pTglDiterima ??= DateTime.now();

      await _client.from(_tableName).insert({
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'file_url': fileUrl,
        'file_path': filePath,
        'file_size': fileSize,
        'mime_type': mimeType,
        'extension': extension,
        'checksum': checksum,
        'uploaded_by': userId,
        'nomor_surat': pNomorSurat,
        'tanggal_surat': pTglSurat.toIso8601String().split('T').first,
        'tanggal_diterima': pTglDiterima.toIso8601String().split('T').first,
        'dari': pDari,
        'kepada': pKepada,
        'no_agenda': pNoAgenda,
        'tingkat_urgensi': pTingkatUrgensi,
        'status_global': 'menunggu_karo',
      });
      debugPrint('[LOG SUCCESS] Surat berhasil disimpan: $pNomorSurat');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal menyimpan arsip surat: $e');
      throw Exception('Gagal menyimpan arsip surat: $e');
    }
  }

  /// Memperbarui metadata surat
  static Future<void> updateArsip({
    required String id,
    required String judul,
    required String kategori,
    required Map<String, dynamic> deskripsi,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    String? oldFilePathToDelete,
    String? nomorSurat,
    DateTime? tanggalSurat,
    DateTime? tanggalDiterima,
    String? dari,
    String? kepada,
    String? noAgenda,
    String? tingkatUrgensi,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
      };

      if (nomorSurat != null) updateData['nomor_surat'] = nomorSurat;
      if (dari != null) updateData['dari'] = dari;
      if (kepada != null) updateData['kepada'] = kepada;
      if (noAgenda != null) updateData['no_agenda'] = noAgenda;
      if (tingkatUrgensi != null) updateData['tingkat_urgensi'] = tingkatUrgensi;

      DateTime? pTglSurat = tanggalSurat;
      if (pTglSurat == null && deskripsi['tanggal_surat'] != null) {
        try {
          pTglSurat = DateTime.parse(deskripsi['tanggal_surat'].toString());
        } catch (_) {}
      }
      if (pTglSurat != null) {
        updateData['tanggal_surat'] = pTglSurat.toIso8601String().split('T').first;
      }

      DateTime? pTglDiterima = tanggalDiterima;
      if (pTglDiterima == null && deskripsi['tanggal_diterima'] != null) {
        try {
          pTglDiterima = DateTime.parse(deskripsi['tanggal_diterima'].toString());
        } catch (_) {}
      }
      if (pTglDiterima != null) {
        updateData['tanggal_diterima'] = pTglDiterima.toIso8601String().split('T').first;
      }

      if (fileUrl != null) updateData['file_url'] = fileUrl;
      if (filePath != null) updateData['file_path'] = filePath;
      if (fileSize != null) updateData['file_size'] = fileSize;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _client.from(_tableName).update(updateData).eq('id', id);

      if (oldFilePathToDelete != null &&
          oldFilePathToDelete.isNotEmpty &&
          filePath != null &&
          filePath != oldFilePathToDelete) {
        try {
          await _client.storage.from(_bucketName).remove([oldFilePathToDelete]);
        } catch (storageError) {
          debugPrint('Gagal menghapus berkas lama dari storage: $storageError');
        }
      }
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memperbarui arsip surat ($id): $e');
      throw Exception('Gagal memperbarui arsip surat: $e');
    }
  }

  /// Method backward compatibility untuk memperbarui status pengiriman/disposisi
  static Future<void> updateStatusPengiriman({
    required String id,
    required String status,
    required Map<String, dynamic> existingDeskripsi,
  }) async {
    try {
      final updatedDeskripsi = Map<String, dynamic>.from(existingDeskripsi);
      updatedDeskripsi['status_pengiriman'] = status;
      updatedDeskripsi['status_disposisi'] = status;

      await _client.from(_tableName).update({
        'deskripsi': updatedDeskripsi,
        'status_global': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memperbarui status pengiriman: $e');
      throw Exception('Gagal memperbarui status pengiriman: $e');
    }
  }

  /// Soft delete arsip surat
  static Future<void> hapusArsip({
    required String id,
    required String filePath,
  }) async {
    try {
      final user = _client.auth.currentUser;
      // Soft delete: update deleted_at and deleted_by
      await _client.from(_tableName).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': user?.id,
      }).eq('id', id);
      debugPrint('[LOG SUCCESS] Surat ($id) telah di-soft-delete');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal menghapus arsip surat: $e');
      throw Exception('Gagal menghapus arsip surat: $e');
    }
  }

  /// Mengunggah berkas fisik surat ke Supabase Storage
  static Future<Map<String, String>> uploadBerkasAsli({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    try {
      final cleanExt = fileName.split('.').last.toLowerCase();
      final storagePath = 'surat_masuk_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      await _client.storage.from(_bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final fileUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);
      return {
        'file_url': fileUrl,
        'file_path': storagePath,
      };
    } catch (e) {
      debugPrint('[LOG ERR] Upload berkas ke storage gagal: $e');
      throw Exception('Gagal mengunggah berkas ke storage: $e');
    }
  }
}
