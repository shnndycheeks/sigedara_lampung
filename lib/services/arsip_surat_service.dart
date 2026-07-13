import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/arsip_surat_model.dart';

class ArsipSuratService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'arsip_surat';
  static const String _bucketName = 'arsip-surat';

  static Future<List<ArsipSurat>> getSemuaArsip() async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => ArsipSurat.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat arsip surat: $e');
    }
  }

  static Future<ArsipSurat> getArsipById(String id) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return ArsipSurat.fromJson(data);
    } catch (e) {
      throw Exception('Gagal memuat detail arsip surat: $e');
    }
  }

  static Future<void> tambahArsip({
    required String judul,
    required String kategori,
    required Map<String, dynamic> deskripsi,
    required String fileUrl,
    required String filePath,
    required int fileSize,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final userId = user?.id;

      await _client.from(_tableName).insert({
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'file_url': fileUrl,
        'file_path': filePath,
        'file_size': fileSize,
        'uploaded_by': userId,
        'created_by': userId,
      });
    } catch (e) {
      throw Exception('Gagal menyimpan arsip surat: $e');
    }
  }

  static Future<void> updateArsip({
    required String id,
    required String judul,
    required String kategori,
    required Map<String, dynamic> deskripsi,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    String? oldFilePathToDelete,
  }) async {
    try {
      final updateData = {
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
      };

      if (fileUrl != null) {
        updateData['file_url'] = fileUrl;
      }
      if (filePath != null) {
        updateData['file_path'] = filePath;
      }
      if (fileSize != null) {
        updateData['file_size'] = fileSize;
      }

      debugPrint('[LOG 6] Query UPDATE ke tabel arsip_surat akan dieksekusi:');
      debugPrint('  - id: $id');
      debugPrint('  - payload updateData: $updateData');

      await _client.from(_tableName).update(updateData).eq('id', id);

      // Delete old file from storage if updated and requested
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
      debugPrint('[LOG 6] Query UPDATE GAGAL: $e');
      throw Exception('Gagal memperbarui arsip surat: $e');
    }
  }

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
      }).eq('id', id);
    } catch (e) {
      throw Exception('Gagal memperbarui status pengiriman: $e');
    }
  }

  static Future<void> hapusArsip({
    required String id,
    required String filePath,
  }) async {
    try {
      // 1. Delete from database
      await _client.from(_tableName).delete().eq('id', id);

      // 2. Remove file from storage
      if (filePath.isNotEmpty) {
        try {
          await _client.storage.from(_bucketName).remove([filePath]);
        } catch (storageError) {
          debugPrint('Gagal menghapus berkas fisik dari storage: $storageError');
        }
      }
    } catch (e) {
      throw Exception('Gagal menghapus arsip surat: $e');
    }
  }

  static Future<Map<String, String>> uploadBerkasAsli({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    try {
      debugPrint('[LOG 3] Method upload berkas asli dipanggil: filename=$fileName, bytesLength=${fileBytes.length}, mimeType=$mimeType');
      // Create clean and unique file path
      final cleanExt = fileName.split('.').last.toLowerCase();
      final storagePath = 'surat_masuk_${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

      debugPrint('[LOG 4] Upload ke Supabase Storage dimulai: path=$storagePath');
      await _client.storage.from(_bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final fileUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);
      debugPrint('[LOG 4] Upload ke Supabase Storage berhasil: publicUrl=$fileUrl');

      return {
        'file_url': fileUrl,
        'file_path': storagePath,
      };
    } catch (e) {
      debugPrint('[LOG 4] Upload ke Supabase Storage GAGAL: $e');
      throw Exception('Gagal mengunggah berkas ke storage: $e');
    }
  }
}
