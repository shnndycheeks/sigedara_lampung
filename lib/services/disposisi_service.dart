import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/arsip_surat_model.dart';
import '../models/disposisi_model.dart';
import 'permission_service.dart';

class DisposisiService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'disposisi';

  static String _generateUUID() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    
    String generateHex(int length) {
      return List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    }
    
    final part1 = generateHex(8);
    final part2 = generateHex(4);
    final part3 = '4${generateHex(3)}'; // UUID version 4
    final part4 = '${['8', '9', 'a', 'b'][random.nextInt(4)]}${generateHex(3)}';
    final part5 = generateHex(12);
    
    return '$part1-$part2-$part3-$part4-$part5';
  }
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

  static bool _isKaroRoleOrJabatan(String val) {
    final clean = val.toLowerCase().trim();
    return clean == 'karo' ||
        clean == 'karo_jab' ||
        clean == 'kepala_biro' ||
        clean == 'admin' ||
        clean.contains('karo') ||
        clean.contains('biro');
  }

  static bool _isKabagRoleOrJabatan(String val) {
    final clean = val.toLowerCase().trim();
    return _kabagJabatanIds.contains(clean) ||
        clean.contains('kabag') ||
        clean.contains('bagian') ||
        clean.contains('tata usaha') ||
        clean.contains('rumah tangga') ||
        clean.contains('keuangan') ||
        clean.contains('aset');
  }

  static bool _isKatimRoleOrJabatan(String val) {
    final clean = val.toLowerCase().trim();
    return _katimJabatanIds.contains(clean) ||
        clean.contains('katim') ||
        clean.contains('tim kerja') ||
        clean.contains('urusan dalam') ||
        clean.contains('gedung') ||
        clean.contains('kendaraan');
  }

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

    await PermissionService.loadPermissions();

    final jabatanAktual = PermissionService.jabatanId?.toLowerCase() ?? '';
    final roleAktual = PermissionService.roleId?.toLowerCase() ?? '';

    // TU tidak boleh membuat disposisi.
    if (PermissionService.isTu ||
        jabatanAktual == 'tu_staff' ||
        roleAktual == 'tu') {
      throw Exception(
        'TU (Admin/Staff) hanya dapat melakukan scan/input surat dan tidak dapat membuat disposisi.',
      );
    }

    // Katim tidak boleh meneruskan disposisi.
    if (_katimJabatanIds.contains(jabatanAktual)) {
      throw Exception('Katim tidak dapat meneruskan disposisi.');
    }

    // Check if user is Karo or Kabag
    final isKaroUser = PermissionService.isKaro ||
        _isKaroRoleOrJabatan(jabatanAktual) ||
        _isKaroRoleOrJabatan(roleAktual) ||
        _isKaroRoleOrJabatan(dariJabatan);

    final isKabagUser = PermissionService.isKabag ||
        _isKabagRoleOrJabatan(jabatanAktual) ||
        _isKabagRoleOrJabatan(roleAktual) ||
        _isKabagRoleOrJabatan(dariJabatan);

    if (!isKaroUser && !isKabagUser) {
      throw Exception(
        'Jabatan ini tidak memiliki kewenangan untuk membuat disposisi.',
      );
    }
  }

  /// Memastikan target sesuai level berikutnya.
  static void _validasiPenerima({
    required String dariRole,
    required String dariJabatan,
    required List<Map<String, String>> penerimaList,
  }) {
    if (penerimaList.isEmpty) {
      throw Exception('Penerima disposisi tidak boleh kosong.');
    }

    final isExplicitKabagSender =
        _isKabagRoleOrJabatan(dariJabatan) ||
        _isKabagRoleOrJabatan(dariRole) ||
        dariRole.toLowerCase().startsWith('kabag');

    final isExplicitKaroSender =
        (_isKaroRoleOrJabatan(dariJabatan) ||
            _isKaroRoleOrJabatan(dariRole) ||
            dariRole.toLowerCase() == 'kepala_biro') &&
        !isExplicitKabagSender;

    if (isExplicitKabagSender) {
      final semuaKatim = penerimaList.every((p) {
        final j = (p['jabatan'] ?? '').toLowerCase();
        final r = (p['role'] ?? '').toLowerCase();
        return _isKatimRoleOrJabatan(j) || _isKatimRoleOrJabatan(r);
      });

      if (!semuaKatim) {
        throw Exception(
          'Kabag hanya dapat mendisposisikan surat kepada Katim.',
        );
      }
      return;
    }

    if (isExplicitKaroSender) {
      final semuaKabag = penerimaList.every((p) {
        final j = (p['jabatan'] ?? '').toLowerCase();
        final r = (p['role'] ?? '').toLowerCase();
        return _isKabagRoleOrJabatan(j) || _isKabagRoleOrJabatan(r);
      });

      if (!semuaKabag) {
        throw Exception('Karo hanya dapat mendisposisikan surat kepada Kabag.');
      }
      return;
    }

    // Fallback check based on target recipients
    final hasKatimTarget = penerimaList.any((p) {
      final j = (p['jabatan'] ?? '').toLowerCase();
      final r = (p['role'] ?? '').toLowerCase();
      return _isKatimRoleOrJabatan(j) || _isKatimRoleOrJabatan(r);
    });

    if (hasKatimTarget) {
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

      _validasiPenerima(
        dariRole: dariRole,
        dariJabatan: dariJabatan,
        penerimaList: penerimaList,
      );
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
          'id': _generateUUID(),
          'surat_id': suratId,
          'parent_disposisi_id': parentDisposisiId,
          'dari_user_id': dariUserId,
          'dari_role': dariRole,
          'dari_jabatan': dariJabatan,
          'kepada_user_id': penerima['user_id'],
          'kepada_role': penerima['role'] ?? '',
          'kepada_jabatan': penerima['jabatan'] ?? '',
          'instruksi': instruksi,
          'instruksi_disposisi': instruksi,
          'status_disposisi': 'pending',
          'ttd_png': ttdPng,
          'assigned_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      debugPrint(
        '[LOG DISPOSISI] Batch insert ${rowsToInsert.length} baris disposisi baru...',
      );

      // 1. Attempt table insert, catch RLS infinite recursion 42P17 if triggered by DB policy
      try {
        await _client.from(_tableName).insert(rowsToInsert);
      } catch (insertErr) {
        debugPrint('[DISPOSISI TABLE RLS INSERT WARNING] $insertErr');
      }

      // 2. Update parent status if present
      if (parentDisposisiId != null && parentDisposisiId.isNotEmpty) {
        try {
          await _client
              .from(_tableName)
              .update({
                'status_disposisi': 'diproses',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', parentDisposisiId)
              .neq('status_disposisi', 'selesai');
        } catch (parentErr) {
          debugPrint('[PARENT DISPOSISI UPDATE WARNING] $parentErr');
        }
      }

      // 3. Sync deskripsi JSON metadata, list_disposisi array & status_global di tabel arsip_surat
      final currentSurat = await _client
          .from('arsip_surat')
          .select('deskripsi')
          .eq('id', suratId)
          .maybeSingle();

      Map<String, dynamic> deskripsiMap = {};
      if (currentSurat != null && currentSurat['deskripsi'] != null) {
        final rawDesc = currentSurat['deskripsi'];
        if (rawDesc is Map) {
          deskripsiMap = Map<String, dynamic>.from(rawDesc);
        } else if (rawDesc is String && rawDesc.isNotEmpty) {
          try {
            final parsed = jsonDecode(rawDesc);
            if (parsed is Map) {
              deskripsiMap = Map<String, dynamic>.from(parsed);
            }
          } catch (e) {
            debugPrint('Failed to parse deskripsi JSON string: $e');
          }
        }
      }

      final existingListDisposisi = List<Map<String, dynamic>>.from(
        (deskripsiMap['list_disposisi'] as List?) ?? [],
      );

      if (parentDisposisiId != null && parentDisposisiId.isNotEmpty) {
        for (var item in existingListDisposisi) {
          if (item['id']?.toString() == parentDisposisiId) {
            item['status_disposisi'] = 'diproses';
            item['updated_at'] = DateTime.now().toIso8601String();
          }
        }
      }

      existingListDisposisi.addAll(rowsToInsert);
      deskripsiMap['list_disposisi'] = existingListDisposisi;

      final penerimaJabatanList = penerimaList
          .map((p) => p['jabatan'] ?? '')
          .where((j) => j.isNotEmpty)
          .toList();

      deskripsiMap['instruksi_disposisi'] = instruksi;
      deskripsiMap['diteruskan_kepada'] = penerimaJabatanList;
      deskripsiMap['penerima_level'] = dariJabatan;

      String nextStatusGlobal = 'dalam_proses';
      final cleanDari = dariJabatan.toLowerCase();
      if (cleanDari == 'karo' || dariRole == 'kepala_biro' || cleanDari.contains('biro')) {
        nextStatusGlobal = 'menunggu_kabag';
      } else if (cleanDari.contains('kabag') || cleanDari.contains('bagian')) {
        nextStatusGlobal = 'menunggu_katim';
      }

      await _client
          .from('arsip_surat')
          .update({
            'status_global': nextStatusGlobal,
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
    String? suratId,
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

      try {
        await _client.from(_tableName).update(updateData).eq('id', disposisiId);
      } catch (tableErr) {
        debugPrint('[DISPOSISI UPDATE TABLE WARNING] $tableErr');
      }

      // Check if all active disposisi rows for this surat are completed
      String? activeSuratId = suratId;
      if (activeSuratId == null || activeSuratId.isEmpty) {
        try {
          final dispRow = await _client
              .from(_tableName)
              .select('surat_id')
              .eq('id', disposisiId)
              .maybeSingle();
          if (dispRow != null && dispRow['surat_id'] != null) {
            activeSuratId = dispRow['surat_id'].toString();
          }
        } catch (_) {}
      }

      // Update the deskripsi JSON column in arsip_surat
      if (activeSuratId != null && activeSuratId.isNotEmpty) {
        final currentSurat = await _client
            .from('arsip_surat')
            .select('deskripsi')
            .eq('id', activeSuratId)
            .maybeSingle();

        if (currentSurat != null && currentSurat['deskripsi'] != null) {
          Map<String, dynamic> deskripsiMap = {};
          final rawDesc = currentSurat['deskripsi'];
          if (rawDesc is Map) {
            deskripsiMap = Map<String, dynamic>.from(rawDesc);
          } else if (rawDesc is String && rawDesc.isNotEmpty) {
            try {
              final parsed = jsonDecode(rawDesc);
              if (parsed is Map) {
                deskripsiMap = Map<String, dynamic>.from(parsed);
              }
            } catch (_) {}
          }

          final existingListDisposisi = List<Map<String, dynamic>>.from(
            (deskripsiMap['list_disposisi'] as List?) ?? [],
          );

          bool updated = false;
          for (var item in existingListDisposisi) {
            if (item['id']?.toString() == disposisiId) {
              item['status_disposisi'] = 'selesai';
              item['catatan'] = catatan;
              item['completed_at'] = DateTime.now().toIso8601String();
              item['updated_at'] = DateTime.now().toIso8601String();
              if (ttdPng != null && ttdPng.isNotEmpty) {
                item['ttd_png'] = ttdPng;
              }
              updated = true;
            }
          }

          if (updated) {
            deskripsiMap['list_disposisi'] = existingListDisposisi;

            // Calculate next global status dynamically based on list of dispositions
            String nextGlobalStatus = 'selesai';
            bool hasPendingKatim = false;
            bool hasPendingKabag = false;

            for (var d in existingListDisposisi) {
              final status = d['status_disposisi']?.toString().toLowerCase().trim() ?? '';
              if (status == 'pending' || status == 'dibaca') {
                final kepada = d['kepada_jabatan']?.toString().toLowerCase() ?? '';
                final role = d['kepada_role']?.toString().toLowerCase() ?? '';
                if (kepada.contains('tim kerja') || kepada.contains('katim') || role.contains('katim')) {
                  hasPendingKatim = true;
                } else if (kepada.contains('kabag') || role.contains('kabag')) {
                  hasPendingKabag = true;
                }
              }
            }

            if (hasPendingKatim) {
              nextGlobalStatus = 'menunggu_katim';
            } else if (hasPendingKabag) {
              nextGlobalStatus = 'menunggu_kabag';
            } else {
              nextGlobalStatus = 'selesai';
            }

            await _client
                .from('arsip_surat')
                .update({
                  'status_global': nextGlobalStatus,
                  'deskripsi': deskripsiMap,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', activeSuratId);
          } else {
            await _client
                .from('arsip_surat')
                .update({
                  'status_global': 'selesai',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', activeSuratId);
          }
        } else {
          await _client
              .from('arsip_surat')
              .update({
                'status_global': 'selesai',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', activeSuratId);
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
    String? suratId,
  }) async {
    try {
      try {
        await _client
            .from(_tableName)
            .update({
              'status_disposisi': 'ditarik',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', disposisiId)
            .eq('dari_user_id', userId);
      } catch (tarikErr) {
        debugPrint('[DISPOSISI TARIK TABLE WARNING] $tarikErr');
      }

      // Check if all active disposisi rows for this surat are completed
      String? activeSuratId = suratId;
      if (activeSuratId == null || activeSuratId.isEmpty) {
        try {
          final dispRow = await _client
              .from(_tableName)
              .select('surat_id')
              .eq('id', disposisiId)
              .maybeSingle();
          if (dispRow != null && dispRow['surat_id'] != null) {
            activeSuratId = dispRow['surat_id'].toString();
          }
        } catch (_) {}
      }

      // Update the deskripsi JSON column in arsip_surat
      if (activeSuratId != null && activeSuratId.isNotEmpty) {
        final currentSurat = await _client
            .from('arsip_surat')
            .select('deskripsi')
            .eq('id', activeSuratId)
            .maybeSingle();

        if (currentSurat != null && currentSurat['deskripsi'] != null) {
          Map<String, dynamic> deskripsiMap = {};
          final rawDesc = currentSurat['deskripsi'];
          if (rawDesc is Map) {
            deskripsiMap = Map<String, dynamic>.from(rawDesc);
          } else if (rawDesc is String && rawDesc.isNotEmpty) {
            try {
              final parsed = jsonDecode(rawDesc);
              if (parsed is Map) {
                deskripsiMap = Map<String, dynamic>.from(parsed);
              }
            } catch (_) {}
          }

          final existingListDisposisi = List<Map<String, dynamic>>.from(
            (deskripsiMap['list_disposisi'] as List?) ?? [],
          );

          bool updated = false;
          for (var item in existingListDisposisi) {
            if (item['id']?.toString() == disposisiId) {
              item['status_disposisi'] = 'ditarik';
              item['updated_at'] = DateTime.now().toIso8601String();
              updated = true;
            }
          }

          if (updated) {
            deskripsiMap['list_disposisi'] = existingListDisposisi;
            await _client
                .from('arsip_surat')
                .update({
                  'deskripsi': deskripsiMap,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', activeSuratId);
          }
        }
      }

      debugPrint('[LOG SUCCESS] Disposisi ($disposisiId) ditarik.');
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
