import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getKendaraan() async {
    final data = await _client
        .from('kendaraan')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAssets() async {
    final data = await _client
        .from('assets')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getRuangan() async {
    final data = await _client
        .from('ruangan')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getPegawaiProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('role', 'pegawai')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> updateStatusPegawai({
    required String userId,
    required String status,
  }) async {
    await _client.from('profiles').update({
      'status': status,
    }).eq('id', userId);
  }

  static Future<void> tambahAset({
    required String nama,
    required String kodeAsset,
    required String lokasi,
    String kategori = 'Elektronik',
    String kondisi = 'baik',
    String status = 'tersedia',
  }) async {
    await _client.from('assets').insert({
      'nama': nama,
      'kode_asset': kodeAsset,
      'kategori': kategori,
      'kondisi': kondisi,
      'status': status,
      'lokasi': lokasi,
    });
  }

  static Future<void> updateAset({
    required String id,
    required String nama,
    required String kodeAsset,
    required String lokasi,
    required String kategori,
    required String kondisi,
    String status = 'tersedia',
  }) async {
    await _client.from('assets').update({
      'nama': nama,
      'kode_asset': kodeAsset,
      'kategori': kategori,
      'kondisi': kondisi,
      'status': status,
      'lokasi': lokasi,
    }).eq('id', id);
  }

  static Future<void> hapusAset(String id) async {
    await _client.from('assets').delete().eq('id', id);
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER CEK BENTROK JADWAL
  // ─────────────────────────────────────────────────────────────

  static String _formatJam(DateTime date) {
    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatTanggal(DateTime date) {
    final local = date.toLocal();

    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${local.day} ${bulan[local.month]} ${local.year}';
  }

  static Future<List<Map<String, dynamic>>> cekBentrokPeminjaman({
    required String tipeItem,
    required String itemId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
  }) async {
    if (!tanggalSelesai.isAfter(tanggalMulai)) {
      throw Exception('Jam selesai harus lebih besar dari jam mulai');
    }

    final data = await _client.rpc(
      'cek_bentrok_peminjaman',
      params: {
        'p_tipe_item': tipeItem,
        'p_item_id': itemId,
        'p_tanggal_mulai': tanggalMulai.toIso8601String(),
        'p_tanggal_selesai': tanggalSelesai.toIso8601String(),
      },
    );

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> _pastikanTidakBentrok({
  required String tipeItem,
  required String itemId,
  required DateTime tanggalMulai,
  required DateTime tanggalSelesai,
  required String namaItem,
}) async {
  final dataBentrok = await cekBentrokPeminjaman(
    tipeItem: tipeItem,
    itemId: itemId,
    tanggalMulai: tanggalMulai,
    tanggalSelesai: tanggalSelesai,
  );

  if (dataBentrok.isEmpty) return;

  final isKendaraan = tipeItem.toLowerCase() == 'kendaraan';

  DateTime mulaiBaru;
  DateTime selesaiBaru;

  if (isKendaraan) {
    mulaiBaru = DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
    );

    selesaiBaru = DateTime(
      tanggalSelesai.year,
      tanggalSelesai.month,
      tanggalSelesai.day,
    ).add(const Duration(days: 1));
  } else {
    mulaiBaru = tanggalMulai;
    selesaiBaru = tanggalSelesai;
  }

  for (final jadwal in dataBentrok) {
    final mulaiLamaRaw = DateTime.tryParse(
      (jadwal['tanggal_mulai'] ?? '').toString(),
    );

    final selesaiLamaRaw = DateTime.tryParse(
      (jadwal['tanggal_selesai'] ?? '').toString(),
    );

    if (mulaiLamaRaw == null || selesaiLamaRaw == null) {
      continue;
    }

    DateTime mulaiLama;
    DateTime selesaiLama;

    if (isKendaraan) {
      mulaiLama = DateTime(
        mulaiLamaRaw.year,
        mulaiLamaRaw.month,
        mulaiLamaRaw.day,
      );

      selesaiLama = DateTime(
        selesaiLamaRaw.year,
        selesaiLamaRaw.month,
        selesaiLamaRaw.day,
      ).add(const Duration(days: 1));
    } else {
      mulaiLama = mulaiLamaRaw;
      selesaiLama = selesaiLamaRaw;
    }

    final benarBentrok =
        mulaiBaru.isBefore(selesaiLama) && selesaiBaru.isAfter(mulaiLama);

    if (benarBentrok) {
      if (isKendaraan) {
        throw Exception(
          '$namaItem sudah dibooking pada ${_formatTanggal(mulaiLamaRaw)} '
          'sampai ${_formatTanggal(selesaiLamaRaw)}',
        );
      }

      throw Exception(
        '$namaItem sudah dibooking pada ${_formatTanggal(mulaiLamaRaw)} '
        'jam ${_formatJam(mulaiLamaRaw)} - ${_formatJam(selesaiLamaRaw)}',
      );
    }
  }
}

  static Future<String> _resolveRuanganId(String ruanganId) async {
    String finalRuanganId = ruanganId;

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(ruanganId);

    if (!isUuid) {
      final ruangan = await _client
          .from('ruangan')
          .select('id')
          .eq('nama', ruanganId)
          .maybeSingle();

      if (ruangan == null) {
        throw Exception(
          'Ruangan "$ruanganId" tidak ditemukan di tabel ruangan',
        );
      }

      finalRuanganId = ruangan['id'].toString();
    }

    return finalRuanganId;
  }

  static Future<String> _getNamaRuangan(String ruanganId) async {
    final ruangan = await _client
        .from('ruangan')
        .select()
        .eq('id', ruanganId)
        .maybeSingle();

    if (ruangan == null) return 'Ruangan';

    return (ruangan['nama'] ??
            ruangan['nama_ruangan'] ??
            ruangan['ruangan'] ??
            ruangan['name'] ??
            'Ruangan')
        .toString();
  }

  static Future<String> _getNamaKendaraan(String kendaraanId) async {
    final kendaraan = await _client
        .from('kendaraan')
        .select()
        .eq('id', kendaraanId)
        .maybeSingle();

    if (kendaraan == null) return 'Kendaraan';

    final nama = (kendaraan['nama'] ??
            kendaraan['nama_kendaraan'] ??
            kendaraan['tipe'] ??
            kendaraan['jenis'] ??
            'Kendaraan')
        .toString()
        .trim();

    final plat = (kendaraan['plat_nomor'] ??
            kendaraan['no_polisi'] ??
            kendaraan['nomor_polisi'] ??
            kendaraan['nopol'] ??
            '')
        .toString()
        .trim();

    if (plat.isEmpty) return nama;

    return '$nama ($plat)';
  }

  // ─────────────────────────────────────────────────────────────
  // PEMINJAMAN GEDUNG / RUANGAN
  // ─────────────────────────────────────────────────────────────

  static Future<void> ajukanPeminjamanGedung({
    required String ruanganId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String keperluan,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final finalRuanganId = await _resolveRuanganId(ruanganId);
    final namaRuangan = await _getNamaRuangan(finalRuanganId);

    await _pastikanTidakBentrok(
      tipeItem: 'ruangan',
      itemId: finalRuanganId,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      namaItem: namaRuangan,
    );

    await _client.from('peminjaman').insert({
      'user_id': user.id,
      'tipe_item': 'ruangan',
      'item_id': finalRuanganId,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'keperluan': keperluan,
      'status': 'pending',
      'catatan_admin': null,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // PEMINJAMAN KENDARAAN
  // ─────────────────────────────────────────────────────────────

  static Future<void> ajukanPeminjamanKendaraan({
    required String kendaraanId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String keperluan,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final namaKendaraan = await _getNamaKendaraan(kendaraanId);

    await _pastikanTidakBentrok(
      tipeItem: 'kendaraan',
      itemId: kendaraanId,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      namaItem: namaKendaraan,
    );

    await _client.from('peminjaman').insert({
      'user_id': user.id,
      'tipe_item': 'kendaraan',
      'item_id': kendaraanId,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'keperluan': keperluan,
      'status': 'pending',
      'catatan_admin': null,
    });
  }

  static Future<List<Map<String, dynamic>>> getPeminjamanSaya() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final data = await _client
        .from('peminjaman')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getSemuaPeminjaman() async {
    final data = await _client
        .from('peminjaman')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> updateStatusPeminjaman({
    required String peminjamanId,
    required String status,
    String? catatanAdmin,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Admin belum login');
    }

    await _client.from('peminjaman').update({
      'status': status,
      'catatan_admin': catatanAdmin,
      'approved_by': user.id,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', peminjamanId);
  }

  // ─────────────────────────────────────────────────────────────
  // EDIT & HAPUS PEMINJAMAN
  // ─────────────────────────────────────────────────────────────

  static Future<void> updatePeminjaman({
    required String peminjamanId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String keperluan,
  }) async {
    if (!tanggalSelesai.isAfter(tanggalMulai)) {
      throw Exception('Jam selesai harus lebih besar dari jam mulai');
    }

    await _client.from('peminjaman').update({
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'keperluan': keperluan,
    }).eq('id', peminjamanId);
  }

  static Future<void> hapusPeminjaman(String peminjamanId) async {
    await _client.from('peminjaman').delete().eq('id', peminjamanId);
  }

  // ─────────────────────────────────────────────────────────────
  // DASHBOARD PEGAWAI
  // ─────────────────────────────────────────────────────────────

  static Future<Map<String, int>> getDashboardStats() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final assets = await _client.from('assets').select('id');

    final kendaraan = await _client.from('kendaraan').select('id');

    final peminjamanSaya = await _client
        .from('peminjaman')
        .select('id, tipe_item, status')
        .eq('user_id', user.id);

    final List<Map<String, dynamic>> assetList =
        List<Map<String, dynamic>>.from(assets);

    final List<Map<String, dynamic>> kendaraanList =
        List<Map<String, dynamic>>.from(kendaraan);

    final List<Map<String, dynamic>> peminjamanList =
        List<Map<String, dynamic>>.from(peminjamanSaya);

    final totalAset = assetList.length;
    final totalKendaraan = kendaraanList.length;

    final peminjamanGedung = peminjamanList.where((p) {
      final tipe = (p['tipe_item'] ?? '').toString().toLowerCase();
      return tipe == 'ruangan' || tipe == 'gedung';
    }).length;

    final menungguPersetujuan = peminjamanList.where((p) {
      final status = (p['status'] ?? '').toString().toLowerCase();
      return status == 'pending' || status == 'menunggu';
    }).length;

    return {
      'total_aset': totalAset,
      'total_kendaraan': totalKendaraan,
      'peminjaman_gedung': peminjamanGedung,
      'menunggu_persetujuan': menungguPersetujuan,
    };
  }
}