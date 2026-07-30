import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'profiles';

  /// Memuat profile user lengkap ter-join dengan roles & jabatan
  static Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from(_tableName)
          .select('*, roles(*), jabatan(*)')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat profile ($userId): $e');
      return null;
    }
  }

  /// Memperbarui informasi profil pengguna
  static Future<void> updateProfile({
    required String userId,
    String? nama,
    String? nip,
    String? roleId,
    String? jabatanId,
    String? ttdPng,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nama != null) updateData['nama'] = nama;
      if (nip != null) updateData['nip'] = nip;
      if (roleId != null) updateData['role_id'] = roleId;
      if (jabatanId != null) updateData['jabatan_id'] = jabatanId;
      if (ttdPng != null) updateData['ttd_png'] = ttdPng;

      await _client.from(_tableName).update(updateData).eq('id', userId);
      debugPrint('[LOG SUCCESS] Profile user ($userId) diperbarui.');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal update profile ($userId): $e');
      throw Exception('Gagal memperbarui profile: $e');
    }
  }

  /// Mengunggah gambar tanda tangan (TTD PNG) ke Supabase Storage
  static Future<String> uploadTtdPng({
    required String userId,
    required Uint8List bytes,
  }) async {
    try {
      final storagePath =
          'signatures/$userId/ttd_${DateTime.now().millisecondsSinceEpoch}.png';

      await _client.storage.from('signatures').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      await updateProfile(userId: userId, ttdPng: storagePath);
      return storagePath;
    } catch (e) {
      debugPrint('[LOG ERR] Upload TTD PNG gagal: $e');
      throw Exception('Gagal mengunggah TTD PNG: $e');
    }
  }
}
