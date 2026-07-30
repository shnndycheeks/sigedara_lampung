import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_model.dart';
import '../models/jabatan_model.dart';
import '../models/profile_model.dart';

class ReferenceService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Memuat semua referensi roles
  static Future<List<RoleModel>> getSemuaRoles() async {
    try {
      final data = await _client
          .from('roles')
          .select()
          .order('nama_role', ascending: true);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => RoleModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat roles: $e');
      return [];
    }
  }

  /// Memuat semua referensi jabatan
  static Future<List<JabatanModel>> getSemuaJabatan() async {
    try {
      final data = await _client
          .from('jabatan')
          .select()
          .order('nama_jabatan', ascending: true);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => JabatanModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat jabatan: $e');
      return [];
    }
  }

  /// Memuat daftar pegawai aktif ter-join dengan roles & jabatan
  static Future<List<ProfileModel>> getPegawaiAktif() async {
    try {
      final data = await _client
          .from('profiles')
          .select('*, roles(*), jabatan(*)')
          .eq('status', 'aktif')
          .order('nama', ascending: true);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat pegawai aktif: $e');
      return [];
    }
  }

  /// Memuat daftar pejabat tujuan disposisi berdasarkan role_id
  static Future<List<ProfileModel>> getTargetDisposisiByRole(
    String roleId,
  ) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*, roles(*), jabatan(*)')
          .eq('role_id', roleId)
          .eq('status', 'aktif')
          .order('nama', ascending: true);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat target disposisi role ($roleId): $e');
      return [];
    }
  }
}
