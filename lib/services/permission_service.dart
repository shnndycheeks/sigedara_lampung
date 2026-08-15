import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PermissionService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? _roleId;
  static String? _jabatanId;

  // ============================================================
  // DATA LOGIN
  // ============================================================

  /// Role akun yang sedang login.
  static String? get roleId => _roleId;

  /// Jabatan akun yang sedang login.
  static String? get jabatanId => _jabatanId;

  // ============================================================
  // LOAD ROLE & JABATAN
  // ============================================================

  /// Mengambil role_id dan jabatan_id dari profiles
  /// berdasarkan user yang sedang login.
  static Future<void> loadPermissions() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      clear();
      return;
    }

    final profile = await _client
        .from('profiles')
        .select('role_id, jabatan_id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      clear();
      return;
    }

    _roleId = profile['role_id']?.toString();
    _jabatanId = profile['jabatan_id']?.toString();

    // Debug sementara.
    debugPrint('=== PERMISSION SERVICE ===');
    debugPrint('role_id: $_roleId');
    debugPrint('jabatan_id: $_jabatanId');
    debugPrint('isAdmin: $isAdmin');
    debugPrint('isPegawai: $isPegawai');
    debugPrint('isAdminKendaraan: $isAdminKendaraan');
    debugPrint('isAdminGedung: $isAdminGedung');
  }

  // ============================================================
  // ROLE
  // ============================================================

  /// Apakah akun memiliki role admin?
  static bool get isAdmin => _roleId == 'admin';

  /// Apakah akun memiliki role pegawai?
  static bool get isPegawai => _roleId == 'pegawai';

  /// Apakah akun sudah memiliki role yang valid?
  static bool get hasValidRole => isAdmin || isPegawai;

  // ============================================================
  // WORKFLOW ROLE & JABATAN DISPOSISI
  // ============================================================

  /// General TU Staff check
  static bool get isTu =>
      _roleId == 'tu' || _jabatanId == 'tu_staff';

  /// Kepala Biro (Karo)
  static bool get isKaro =>
      _roleId == 'kepala_biro' || _jabatanId == 'karo';

  /// Kepala Bagian (Kabag)
  static bool get isKabag =>
      _roleId == 'kabag_tu' ||
      _roleId == 'kabag_rt' ||
      _roleId == 'kabag_aset' ||
      _roleId == 'kabag' ||
      _jabatanId == 'kabag_tu_jab' ||
      _jabatanId == 'kabag_rt_jab' ||
      _jabatanId == 'kabag_asset_jab';

  /// Ketua Tim Kerja (Katim)
  static bool get isKatim =>
      _roleId == 'katim' ||
      _jabatanId == 'katim_gd_jab' ||
      _jabatanId == 'katim_kd_jab' ||
      _jabatanId == 'katim_ud_jab';


  // ============================================================
  // JABATAN ADMIN
  // ============================================================

  /// Admin Bagian Kendaraan Dinas.
  static bool get isAdminKendaraan =>
      isAdmin && _jabatanId == 'admin_kendaraan';

  /// Admin Bagian Gedung.
  static bool get isAdminGedung =>
      isAdmin && _jabatanId == 'admin_gedung';

  // ============================================================
  // DASHBOARD
  // ============================================================

  /// Semua akun yang sudah memiliki role boleh membuka dashboard.
  static bool get canAccessDashboard => hasValidRole;

  // ============================================================
  // KENDARAAN
  // ============================================================

  /// Boleh melihat data kendaraan.
  static bool get canViewKendaraan => isAdminKendaraan;

  /// Boleh mengelola data kendaraan.
  static bool get canManageKendaraan => isAdminKendaraan;

  /// Boleh membuka menu kendaraan.
  static bool get canAccessKendaraan => isAdminKendaraan;

  // ============================================================
  // LAPORAN KERUSAKAN KENDARAAN
  // ============================================================

  /// Boleh membuka laporan kerusakan kendaraan.
  /// Hanya Admin Kendaraan.
  static bool get canAccessLaporanKendaraan => isAdminKendaraan;

  // ============================================================
  // GEDUNG / ASET
  // ============================================================

  /// Boleh melihat data gedung.
  static bool get canViewGedung => isAdminGedung;

  /// Boleh mengelola data gedung.
  static bool get canManageGedung => isAdminGedung;

  /// Boleh membuka menu aset/gedung.
  static bool get canAccessAset => isAdminGedung;

  // ============================================================
  // PEMINJAMAN
  // ============================================================

  /// Boleh melihat peminjaman kendaraan.
  static bool get canViewPeminjamanKendaraan => isAdmin;

  /// Boleh melihat peminjaman gedung.
  static bool get canViewPeminjamanGedung => isAdmin;

  /// Boleh membuka menu peminjaman.
  static bool get canAccessPeminjaman => isAdmin;

  // ============================================================
  // PERSETUJUAN
  // ============================================================

  /// Boleh menyetujui peminjaman kendaraan.
  static bool get canApprovePeminjamanKendaraan => isAdmin;

  /// Boleh menyetujui peminjaman gedung.
  static bool get canApprovePeminjamanGedung => isAdmin;

  // ============================================================
  // ARSIP SURAT
  // ============================================================

  /// Boleh membuka arsip surat.
  static bool get canAccessSurat => hasValidRole;

  // ============================================================
  // PROFIL
  // ============================================================

  /// Semua akun yang sudah login boleh membuka profil.
  static bool get canAccessProfile => hasValidRole;

  // ============================================================
  // CLEAR
  // ============================================================

  /// Menghapus permission ketika logout.
  static void clear() {
    _roleId = null;
    _jabatanId = null;

    debugPrint('=== PERMISSION SERVICE CLEARED ===');
  }
}