import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/arsip_surat_model.dart';
import '../models/disposisi_model.dart';
import 'permission_service.dart';

class DisposisiService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'disposisi';
  // ============================================================
  // VALIDASI ALUR DISPOSISI
  // ============================================================

  static const Set<String> _kabagJabatanIds = {
    'kabag_asset_jab',
    'kabag_rt_jab',
    'kabag_tu_jab',
  };

  static const Set<String> _katimJabatanIds = {
    'katim_gd_jab',
    'katim_kd_jab',
    'katim_ud_jab',
  };

  /// Memastikan pengirim memang user yang sedang login
  /// dan memiliki jabatan yang sesuai dengan alur disposisi.
  static Future<void> _validasiPengirim({
    required String dariUserId,
    required String dariJabatan,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Anda belum login.');
    }

    if (user.id != dariUserId) {
      throw Exception('Pengirim disposisi tidak valid.');
    }

    final jabatanLogin = PermissionService.jabatanId?.toLowerCase();

    if (jabatanLogin == null || jabatanLogin.isEmpty) {
      await PermissionService.loadPermissions();
    }

    final jabatanAktual = PermissionService.jabatanId?.toLowerCase();

    if (jabatanAktual == null || jabatanAktual.isEmpty) {
      throw Exception('Jabatan pengguna tidak ditemukan.');
    }

    if (jabatanAktual != dariJabatan.toLowerCase()) {
      throw Exception(
        'Jabatan pengirim tidak sesuai dengan akun yang sedang login.',
      );
    }

    // TU tidak boleh membuat disposisi.
    if (jabatanAktual == 'tu_staff') {
      throw Exception(
        'TU hanya dapat melakukan scan/input surat dan tidak dapat membuat disposisi.',
      );
    }

    // Katim tidak boleh meneruskan disposisi.
    if (_katimJabatanIds.contains(jabatanAktual)) {
      throw Exception('Katim tidak dapat meneruskan disposisi.');
    }

    // Hanya Karo atau Kabag yang boleh membuat disposisi.
    final bolehDisposisi =
        jabatanAktual == 'karo' || _kabagJabatanIds.contains(jabatanAktual);

    if (!bolehDisposisi) {
      throw Exception(
        'Jabatan ini tidak memiliki kewenangan untuk membuat disposisi.',
      );
    }
  }

  /// Memastikan target sesuai level berikutnya.
  static void _validasiPenerima({
    required String dariJabatan,
    required List<Map<String, String>> penerimaList,
  }) {
    final pengirim = dariJabatan.toLowerCase();

    if (penerimaList.isEmpty) {
      throw Exception('Penerima disposisi tidak boleh kosong.');
    }

    final targetJabatan = penerimaList
        .map((p) => (p['jabatan'] ?? '').toLowerCase())
        .toList();

    if (targetJabatan.any((jabatan) => jabatan.isEmpty)) {
      throw Exception('Jabatan penerima disposisi tidak valid.');
    }

    // KARO → hanya boleh ke KABAG.
    if (pengirim == 'karo') {
      final semuaKabag = targetJabatan.every(_kabagJabatanIds.contains);

      if (!semuaKabag) {
        throw Exception('Karo hanya dapat mendisposisikan surat kepada Kabag.');
      }

      return;
    }

    // KABAG → hanya boleh ke KATIM.
    if (_kabagJabatanIds.contains(pengirim)) {
      final semuaKatim = targetJabatan.every(_katimJabatanIds.contains);

      if (!semuaKatim) {
        throw Exception(
          'Kabag hanya dapat mendisposisikan surat kepada Katim.',
        );
      }

      return;
    }

    throw Exception('Alur disposisi tidak valid.');
  }

  /// Memuat daftar surat Inbox untuk user aktif (Status pending / dibaca)
  static Future<List<ArsipSurat>> getInboxSurat({
    required String userId,
    String? userRole,
  }) async {
    try {
      // 1. Jika Karo / Admin, ambil surat ber-status 'menunggu_karo'
      if (userRole == 'kepala_biro' || userRole == 'admin') {
        final dataSurat = await _client
            .from('arsip_surat')
            .select('*, disposisi(*)')
            .eq('status_global', 'menunggu_karo')
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false);

        final listMap = List<Map<String, dynamic>>.from(dataSurat);
        return listMap.map((json) => ArsipSurat.fromJson(json)).toList();
      }

      // 2. Untuk Kabag / Katim, ambil disposisi yang ditugaskan ke userId dengan status pending / dibaca
      final dataDisposisi = await _client
          .from(_tableName)
          .select('surat_id')
          .eq('kepada_user_id', userId)
          .inFilter('status_disposisi', ['pending', 'dibaca']);

      if (dataDisposisi.isEmpty) return [];

      final List<String> suratIds = (dataDisposisi as List)
          .map((e) => e['surat_id'].toString())
          .toSet()
          .toList();

      final dataSurat = await _client
          .from('arsip_surat')
          .select('*, disposisi(*)')
          .inFilter('id', suratIds)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(dataSurat);
      return listMap.map((json) => ArsipSurat.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat Inbox surat ($userId): $e');
      throw Exception('Gagal memuat Inbox surat: $e');
    }
  }

  /// Memuat daftar surat Riwayat untuk user aktif (Read-Only)
  static Future<List<ArsipSurat>> getRiwayatSurat({
    required String userId,
    String? userRole,
  }) async {
    try {
      // 1. Untuk TU, riwayat adalah semua surat yang diunggah oleh TU
      if (userRole == 'tu') {
        final dataSurat = await _client
            .from('arsip_surat')
            .select('*, disposisi(*)')
            .eq('uploaded_by', userId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false);

        final listMap = List<Map<String, dynamic>>.from(dataSurat);
        return listMap.map((json) => ArsipSurat.fromJson(json)).toList();
      }

      // 2. Untuk Karo / Kabag / Katim, ambil surat di mana user pernah menjadi pengirim atau penerima disposisi yang sudah diproses / selesai
      final dataDisposisi = await _client
          .from(_tableName)
          .select('surat_id')
          .or('dari_user_id.eq.$userId,kepada_user_id.eq.$userId');

      if (dataDisposisi.isEmpty) return [];

      final List<String> suratIds = (dataDisposisi as List)
          .map((e) => e['surat_id'].toString())
          .toSet()
          .toList();

      final dataSurat = await _client
          .from('arsip_surat')
          .select('*, disposisi(*)')
          .inFilter('id', suratIds)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(dataSurat);
      return listMap.map((json) => ArsipSurat.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat Riwayat surat ($userId): $e');
      throw Exception('Gagal memuat Riwayat surat: $e');
    }
  }

  /// Mengirim disposisi ke satu atau banyak tujuan (Batch Insert Multi-Target Disposisi)
  static Future<void> kirimDisposisiMulti({
    required String suratId,
    String? parentDisposisiId,
    required String dariUserId,
    required String dariRole,
    required String dariJabatan,
    required List<Map<String, String>>
    penerimaList, // List of {'user_id', 'role', 'jabatan'}
    required String instruksi,
    required String ttdPng,
  }) async {
    try {
      await _validasiPengirim(dariUserId: dariUserId, dariJabatan: dariJabatan);

      _validasiPenerima(dariJabatan: dariJabatan, penerimaList: penerimaList);
      if (penerimaList.isEmpty) {
        throw Exception('Penerima disposisi tidak boleh kosong');
      }

      debugPrint('===== DISPOSISI INSERT DEBUG =====');
      debugPrint('suratId: $suratId');
      debugPrint('parentDisposisiId: $parentDisposisiId');
      debugPrint('dariUserId: $dariUserId');
      debugPrint('dariJabatan: $dariJabatan');
      debugPrint('target: $penerimaList');
      debugPrint('instruksi: $instruksi');
      debugPrint('==================================');

      final rowsToInsert = penerimaList.map((penerima) {
        return {
          'surat_id': suratId,
          'parent_disposisi_id': parentDisposisiId,
          'dari_user_id': dariUserId,
          'dari_role': dariRole,
          'dari_jabatan': dariJabatan,
          'kepada_user_id': penerima['user_id'],
          'kepada_role': penerima['role'] ?? '',
          'kepada_jabatan': penerima['jabatan'] ?? '',
          'instruksi': instruksi,
          'status_disposisi': 'pending',
          'ttd_png': ttdPng,
          'assigned_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      debugPrint(
        '[LOG DISPOSISI] Batch insert ${rowsToInsert.length} baris disposisi baru...',
      );
      await _client.from(_tableName).insert(rowsToInsert);

      // Jika ada parent_disposisi_id, update status parent ke 'diproses' (hanya jika belum 'selesai')
      if (parentDisposisiId != null && parentDisposisiId.isNotEmpty) {
        await _client
            .from(_tableName)
            .update({
              'status_disposisi': 'diproses',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', parentDisposisiId)
            .neq('status_disposisi', 'selesai');
      }

      // Sync deskripsi JSON metadata & status_global di tabel arsip_surat
      final currentSurat = await _client
          .from('arsip_surat')
          .select('deskripsi')
          .eq('id', suratId)
          .maybeSingle();
      Map<String, dynamic> deskripsiMap = {};
      if (currentSurat != null && currentSurat['deskripsi'] is Map) {
        deskripsiMap = Map<String, dynamic>.from(currentSurat['deskripsi']);
      }
      final penerimaJabatanList = penerimaList
          .map((p) => p['jabatan'] ?? '')
          .where((j) => j.isNotEmpty)
          .toList();
      deskripsiMap['instruksi_disposisi'] = instruksi;
      deskripsiMap['diteruskan_kepada'] = penerimaJabatanList;
      deskripsiMap['penerima_level'] = dariJabatan;

      await _client
          .from('arsip_surat')
          .update({
            'status_global': 'dalam_proses',
            'deskripsi': deskripsiMap,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', suratId);

      debugPrint('===== DISPOSISI INSERT RESULT =====');
      debugPrint('success: true');
      debugPrint('insertedRows: ${rowsToInsert.length}');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('===== DISPOSISI ERROR =====');
      debugPrint(e.toString());
      debugPrint('===========================');
      throw Exception('Gagal mengirim disposisi: $e');
    }
  }

  /// Menandai disposisi sebagai sudah dibaca (`opened_at` = NOW(), status = 'dibaca')
  static Future<void> markAsRead(String disposisiId) async {
    try {
      await _client
          .from(_tableName)
          .update({
            'opened_at': DateTime.now().toIso8601String(),
            'status_disposisi': 'dibaca',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', disposisiId)
          .filter('opened_at', 'is', null);
    } catch (e) {
      debugPrint(
        '[LOG ERR] Gagal update opened_at disposisi ($disposisiId): $e',
      );
    }
  }

  /// Menyelesaikan tugas disposisi (diisi oleh Katim / penerima akhir)
  static Future<void> selesaikanDisposisi({
    required String disposisiId,
    required String catatan,
    String? ttdPng,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'catatan': catatan,
        'status_disposisi': 'selesai',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (ttdPng != null && ttdPng.isNotEmpty) {
        updateData['ttd_png'] = ttdPng;
      }

      await _client.from(_tableName).update(updateData).eq('id', disposisiId);

      // Check if all active disposisi rows for this surat are completed
      final dispRow = await _client
          .from(_tableName)
          .select('surat_id')
          .eq('id', disposisiId)
          .maybeSingle();
      if (dispRow != null && dispRow['surat_id'] != null) {
        final suratId = dispRow['surat_id'].toString();
        final allDisposisi = await _client
            .from(_tableName)
            .select('status_disposisi')
            .eq('surat_id', suratId);
        final activeList = List<Map<String, dynamic>>.from(
          allDisposisi,
        ).where((d) => d['status_disposisi'] != 'ditarik').toList();
        final allCompleted =
            activeList.isNotEmpty &&
            activeList.every((d) => d['status_disposisi'] == 'selesai');
        if (allCompleted) {
          await _client
              .from('arsip_surat')
              .update({
                'status_global': 'selesai',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', suratId);
        }
      }

      debugPrint('[LOG SUCCESS] Disposisi ($disposisiId) diselesaikan.');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal menyelesaikan disposisi ($disposisiId): $e');
      throw Exception('Gagal menyelesaikan disposisi: $e');
    }
  }

  /// Menarik/Membatalkan disposisi oleh pengirim (Tarik Disposisi)
  static Future<void> tarikDisposisi({
    required String disposisiId,
    required String userId,
  }) async {
    try {
      await _client
          .from(_tableName)
          .update({
            'status_disposisi': 'ditarik',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', disposisiId)
          .eq('dari_user_id', userId);

      debugPrint('[LOG SUCCESS] Disposisi ($disposisiId) berhasil ditarik');
    } catch (e) {
      debugPrint('[LOG ERR] Gagal menarik disposisi ($disposisiId): $e');
      throw Exception('Gagal menarik disposisi: $e');
    }
  }

  /// Memuat riwayat disposisi untuk 1 surat
  static Future<List<DisposisiModel>> getDisposisiBySuratId(
    String suratId,
  ) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('surat_id', suratId)
          .order('assigned_at', ascending: true);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => DisposisiModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint(
        '[LOG ERR] Gagal memuat riwayat disposisi surat ($suratId): $e',
      );
      throw Exception('Gagal memuat riwayat disposisi surat: $e');
    }
  }
}
