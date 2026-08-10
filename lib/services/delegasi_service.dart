import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delegasi_jabatan_model.dart';

class DelegasiService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'delegasi_jabatan';

  /// Memuat daftar delegasi jabatan aktif
  static Future<List<DelegasiJabatanModel>> getDelegasiAktif() async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('status', 'aktif')
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap
          .map((json) => DelegasiJabatanModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat delegasi aktif: $e');
      return [];
    }
  }

  /// Membuat penugasan delegasi baru
  static Future<void> tambahDelegasi({
    required String pejabatAsliId,
    required String pejabatPenggantiId,
    required String alasan,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
  }) async {
    try {
      await _client.from(_tableName).insert({
        'pejabat_asli_id': pejabatAsliId,
        'pejabat_pengganti_id': pejabatPenggantiId,
        'alasan': alasan,
        'tanggal_mulai': tanggalMulai.toIso8601String(),
        'tanggal_selesai': tanggalSelesai.toIso8601String(),
        'status': 'aktif',
      });
      debugPrint('[LOG SUCCESS] Delegasi jabatan berhasil ditambahkan.');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal membuat delegasi: $e');
      throw Exception('Gagal membuat delegasi: $e');
    }
  }

  /// Nonaktifkan status delegasi
  static Future<void> nonaktifkanDelegasi(String id) async {
    try {
      await _client.from(_tableName).update({
        'status': 'nonaktif',
      }).eq('id', id);
    } catch (e) {
      debugPrint('[LOG ERR] Gagal menonaktifkan delegasi ($id): $e');
    }
  }
}
