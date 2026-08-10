import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/surat_progress_model.dart';

class ProgressService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _viewName = 'v_surat_progress';

  /// Memuat status progress realtime untuk 1 surat
  static Future<SuratProgressModel?> getProgressSurat(String suratId) async {
    try {
      final data = await _client
          .from(_viewName)
          .select()
          .eq('surat_id', suratId)
          .maybeSingle();

      if (data == null) return null;
      return SuratProgressModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat progress surat ($suratId): $e');
      return null;
    }
  }

  /// Memuat status progress seluruh surat aktif
  static Future<List<SuratProgressModel>> getSemuaProgress() async {
    try {
      final data = await _client.from(_viewName).select();
      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => SuratProgressModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat semua progress surat: $e');
      throw Exception('Gagal memuat semua progress surat: $e');
    }
  }
}
