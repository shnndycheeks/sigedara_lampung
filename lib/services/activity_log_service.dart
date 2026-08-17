import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';

class ActivityLogService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'activity_logs';

  /// Mencatat aktivitas user ke dalam tabel activity_logs
  static Future<void> logActivity({
    required String action, // 'LOGIN', 'UPLOAD_SURAT', 'EDIT_METADATA', 'PREVIEW_SURAT', 'DOWNLOAD_SURAT', 'PRINT_SURAT', 'RECALL_DISPOSISI', 'DELETE_SURAT'
    String? suratId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from(_tableName).insert({
        'user_id': user.id,
        'surat_id': suratId,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('[LOG AUDIT] Activity logged: $action');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal mencatat activity log: $e');
    }
  }

  /// Memuat daftar log aktivitas pengguna
  static Future<List<ActivityLogModel>> getLogs({
    String? userId,
    int limit = 50,
  }) async {
    try {
      var query = _client.from(_tableName).select();
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final data = await query.order('created_at', ascending: false).limit(limit);
      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => ActivityLogModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat activity logs: $e');
      throw Exception('Gagal memuat activity logs: $e');
    }
  }
}
