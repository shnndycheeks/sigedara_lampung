import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';
import 'peminjaman_screen.dart'
    show kRuanganInfo, RuanganInfoCard, KalenderGedungScreen;
import 'admin_persetujuan_screen.dart';

class AdminPeminjamanScreen extends StatefulWidget {
  const AdminPeminjamanScreen({super.key});

  @override
  State<AdminPeminjamanScreen> createState() => _AdminPeminjamanScreenState();
}

class _AdminPeminjamanScreenState extends State<AdminPeminjamanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  int _filterGedung = 0;
  int _filterKendaraan = 0;

  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _gedungData = [];
  List<Map<String, dynamic>> _kendaraanData = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final peminjaman = await DatabaseService.getSemuaPeminjaman();
      final ruangan = await DatabaseService.getRuangan();
      final kendaraan = await DatabaseService.getKendaraan();
      final profiles = await DatabaseService.getPegawaiProfiles();

      final ruanganMap = {for (final r in ruangan) r['id'].toString(): r};

      final kendaraanMap = {for (final k in kendaraan) k['id'].toString(): k};

      final profileMap = {for (final p in profiles) p['id'].toString(): p};

      final List<Map<String, dynamic>> gedungList = [];
      final List<Map<String, dynamic>> kendaraanList = [];

      for (final p in peminjaman) {
        final tipe = (p['tipe_item'] ?? '').toString().toLowerCase();
        final itemId = (p['item_id'] ?? '').toString();
        final userId = (p['user_id'] ?? '').toString();

        final profile = profileMap[userId];

        final namaPegawai = _safeText(profile?['nama'], fallback: 'Pegawai');

        final nip = _safeText(profile?['nip'], fallback: '-');

        final unit = _safeText(profile?['jabatan'], fallback: '-');

        final status = _mapStatus(p['status']);
        final tanggalMulai = _parseDate(p['tanggal_mulai']);
        final tanggalSelesai = _parseDate(p['tanggal_selesai']);
        final keperluan = _safeText(p['keperluan'], fallback: '-');

        final baseData = {
          'id': p['id'],
          'raw': p,
          'user_id': userId,
          'item_id': itemId,
          'tipe_item': tipe,
          'peminjam': namaPegawai,
          'nama': namaPegawai,
          'nip': nip,
          'unit': unit,
          'tujuan': _extractTujuan(keperluan),
          'keperluan': keperluan,
          'tanggal': _formatTanggalLengkap(tanggalMulai),
          'waktu': _formatRentangJam(tanggalMulai, tanggalSelesai),
          'tgl_pinjam': _formatTanggalPendek(tanggalMulai),
          'tgl_kembali': _formatTanggalPendek(tanggalSelesai),
          'peserta': _extractPeserta(keperluan),
          'status': status,
          'catatan_admin': p['catatan_admin'],
          'approved_by': p['approved_by'],
          'approved_at': p['approved_at'],
          'created_at': p['created_at'],
        };

        if (tipe == 'ruangan' || tipe == 'gedung') {
          final r = ruanganMap[itemId];
          final namaRuangan = _namaRuangan(r);

          gedungList.add({
            ...baseData,
            'ruangan': namaRuangan,
            'fasilitas': namaRuangan,
          });
        } else if (tipe == 'kendaraan') {
          final k = kendaraanMap[itemId];
          final namaKendaraan = _namaKendaraan(k);

          kendaraanList.add({
            ...baseData,
            'fasilitas': namaKendaraan,
            'kendaraan': namaKendaraan,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _gedungData = gedungList;
        _kendaraanData = kendaraanList;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _mapStatus(dynamic status) {
    final value = (status ?? '').toString().toLowerCase();

    switch (value) {
      case 'disetujui':
      case 'approved':
        return 'Disetujui';
      case 'ditolak':
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      case 'menunggu':
      default:
        return 'Menunggu';
    }
  }

  String _statusToDatabase(String status) {
    switch (status) {
      case 'Disetujui':
        return 'disetujui';
      case 'Ditolak':
        return 'ditolak';
      default:
        return 'pending';
    }
  }

  String _formatTanggalPendek(DateTime? date) {
    if (date == null) return '-';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTanggalLengkap(DateTime? date) {
    if (date == null) return '-';

    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  String _formatJam(DateTime? date) {
    if (date == null) return '-';

    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatRentangJam(DateTime? mulai, DateTime? selesai) {
    if (mulai == null || selesai == null) return '-';

    return '${_formatJam(mulai)} - ${_formatJam(selesai)} WIB';
  }

  String _extractTujuan(String keperluan) {
    if (keperluan.trim().isEmpty) return '-';

    final parts = keperluan.split('|');

    if (parts.isEmpty) return keperluan;

    final first = parts.first.trim();

    return first.isEmpty ? keperluan : first;
  }

  int _extractPeserta(String keperluan) {
    final reg = RegExp(r'Peserta:\s*(\d+)', caseSensitive: false);
    final match = reg.firstMatch(keperluan);

    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? '0') ?? 0;
  }

  String _extractKeterangan(String keperluan) {
    final match = RegExp(
      r'Keterangan:\s*([^|]+)',
      caseSensitive: false,
    ).firstMatch(keperluan);

    return match?.group(1)?.trim() ?? '';
  }

  String _namaRuangan(Map<String, dynamic>? r) {
    if (r == null) return 'Ruangan';

    return _safeText(
      r['nama'] ?? r['nama_ruangan'] ?? r['ruangan'] ?? r['name'],
      fallback: 'Ruangan',
    );
  }

  String _namaKendaraan(Map<String, dynamic>? k) {
    if (k == null) return 'Kendaraan';

    final nama = _safeText(
      k['nama'] ?? k['merk'] ?? k['tipe'],
      fallback: 'Kendaraan',
    );

    final plat = _safeText(
      k['plat_nomor'] ?? k['no_polisi'] ?? k['nomor_polisi'],
      fallback: '',
    );

    if (plat.isEmpty) return nama;

    return '$nama - $plat';
  }

  List<Map<String, dynamic>> _filteredData({
    required List<Map<String, dynamic>> source,
    required int filterIndex,
  }) {
    if (filterIndex == 0) return source;

    return source.where((d) {
      return d['status'].toString().toLowerCase() ==
          _filters[filterIndex].toLowerCase();
    }).toList();
  }

  DateTime _gabungTanggalJam(DateTime tanggal, TimeOfDay jam) {
    return DateTime(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      jam.hour,
      jam.minute,
    );
  }

  TimeOfDay _timeFromDate(DateTime? date, {required int fallbackHour}) {
    if (date == null) {
      return TimeOfDay(hour: fallbackHour, minute: 0);
    }

    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Peminjaman'),
        backgroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => NavigationService.goHomeAdmin?.call(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.task_alt_rounded, color: Colors.white),
            tooltip: 'Proses Persetujuan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPersetujuanScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KalenderGedungScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Peminjaman Gedung'),
            Tab(text: 'Peminjaman Kendaraan'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _loadData)
          : TabBarView(
              controller: _tab,
              children: [_buildGedungTab(), _buildKendaraanTab()],
            ),
    );
  }

  Widget _buildGedungTab() {
    final filtered = _filteredData(
      source: _gedungData,
      filterIndex: _filterGedung,
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _FilterBar(
            filters: _filters,
            selectedIndex: _filterGedung,
            onChanged: (i) => setState(() => _filterGedung = i),
          ),
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: 'Tidak ada data',
                        subtitle: 'Belum ada peminjaman gedung dari Supabase',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _GedungTile(
                      data: filtered[i],
                      onApprove: () => _handleStatus(filtered[i], 'Disetujui'),
                      onReject: () => _showRejectDialog(context, filtered[i]),
                      onEdit: () => _showEditDialog(filtered[i]),
                      onDelete: () => _showDeleteDialog(filtered[i]),
                      onDetail: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _AdminDetailPeminjamanScreen(
                            data: filtered[i],
                            onApprove: () =>
                                _handleStatus(filtered[i], 'Disetujui'),
                            onReject: () =>
                                _showRejectDialog(context, filtered[i]),
                            onEdit: () => _showEditDialog(filtered[i]),
                            onDelete: () => _showDeleteDialog(filtered[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKendaraanTab() {
    final filtered = _filteredData(
      source: _kendaraanData,
      filterIndex: _filterKendaraan,
    );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _FilterBar(
            filters: _filters,
            selectedIndex: _filterKendaraan,
            onChanged: (i) => setState(() => _filterKendaraan = i),
          ),
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: 'Tidak ada data',
                        subtitle:
                            'Belum ada peminjaman kendaraan dari Supabase',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _KendaraanTile(
                      data: filtered[i],
                      onApprove: () => _handleStatus(filtered[i], 'Disetujui'),
                      onReject: () => _showRejectDialog(context, filtered[i]),
                      onEdit: () => _showEditDialog(filtered[i]),
                      onDelete: () => _showDeleteDialog(filtered[i]),
                      onDetail: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _AdminDetailPeminjamanScreen(
                            data: filtered[i],
                            onApprove: () =>
                                _handleStatus(filtered[i], 'Disetujui'),
                            onReject: () =>
                                _showRejectDialog(context, filtered[i]),
                            onEdit: () => _showEditDialog(filtered[i]),
                            onDelete: () => _showDeleteDialog(filtered[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatus(
    Map<String, dynamic> item,
    String status, {
    String? catatanAdmin,
  }) async {
    try {
      await DatabaseService.updateStatusPeminjaman(
        peminjamanId: item['id'].toString(),
        status: _statusToDatabase(status),
        catatanAdmin: catatanAdmin,
      );

      if (!mounted) return;

      setState(() => item['status'] = status);

      _showSnack(item['peminjam'].toString(), status);

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleEdit({
    required Map<String, dynamic> item,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String keperluan,
  }) async {
    try {
      await DatabaseService.updatePeminjaman(
        peminjamanId: item['id'].toString(),
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        keperluan: keperluan,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peminjaman berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal edit peminjaman: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> item) async {
    try {
      await DatabaseService.hapusPeminjaman(item['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peminjaman berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal hapus peminjaman: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSnack(String name, String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'Disetujui'
              ? 'Permintaan $name disetujui.'
              : 'Permintaan $name ditolak.',
        ),
        backgroundColor: status == 'Disetujui'
            ? AppColors.success
            : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final raw = item['raw'] as Map<String, dynamic>?;

    final mulaiAwal = _parseDate(raw?['tanggal_mulai']);
    final selesaiAwal = _parseDate(raw?['tanggal_selesai']);

    DateTime selectedDate = mulaiAwal ?? DateTime.now();
    TimeOfDay startTime = _timeFromDate(mulaiAwal, fallbackHour: 8);
    TimeOfDay endTime = _timeFromDate(selesaiAwal, fallbackHour: 10);

    final tipe = item['tipe_item'].toString();
    final isGedung = tipe == 'ruangan' || tipe == 'gedung';

    final tujuanCtrl = TextEditingController(text: item['tujuan'].toString());

    final pesertaCtrl = TextEditingController(
      text: (item['peserta'] as int) > 0 ? item['peserta'].toString() : '',
    );

    final keteranganCtrl = TextEditingController(
      text: _extractKeterangan(item['keperluan'].toString()),
    );

    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              isGedung ? 'Edit Peminjaman Gedung' : 'Edit Peminjaman Kendaraan',
              style: AppTextStyles.h3,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['fasilitas'].toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Tanggal', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _EditTimeBox(
                          label: 'Jam Mulai',
                          time: startTime,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );

                            if (picked != null) {
                              setDialogState(() => startTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditTimeBox(
                          label: 'Jam Selesai',
                          time: endTime,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );

                            if (picked != null) {
                              setDialogState(() => endTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Tujuan / Keperluan', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tujuanCtrl,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Masukkan tujuan peminjaman',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (isGedung) ...[
                    const SizedBox(height: 14),
                    const Text('Jumlah Peserta', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pesertaCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah peserta',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Keterangan Tambahan', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: keteranganCtrl,
                    maxLines: 3,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Opsional',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final tujuan = tujuanCtrl.text.trim();
                        final peserta = pesertaCtrl.text.trim();
                        final ket = keteranganCtrl.text.trim();

                        if (tujuan.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tujuan wajib diisi'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        if (isGedung && peserta.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jumlah peserta wajib diisi'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final mulai = _gabungTanggalJam(
                          selectedDate,
                          startTime,
                        );

                        final selesai = _gabungTanggalJam(
                          selectedDate,
                          endTime,
                        );

                        if (!selesai.isAfter(mulai)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Jam selesai harus lebih besar dari jam mulai',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final keperluanBaru = isGedung
                            ? [
                                tujuan,
                                'Peserta: $peserta',
                                'Ruangan: ${item['fasilitas']}',
                                if (ket.isNotEmpty) 'Keterangan: $ket',
                              ].join(' | ')
                            : [
                                tujuan,
                                'Kendaraan: ${item['fasilitas']}',
                                if (ket.isNotEmpty) 'Keterangan: $ket',
                              ].join(' | ');

                        setDialogState(() => saving = true);

                        await _handleEdit(
                          item: item,
                          tanggalMulai: mulai,
                          tanggalSelesai: selesai,
                          keperluan: keperluanBaru,
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);
                      },
                icon: saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(saving ? 'Menyimpan...' : 'Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Peminjaman', style: AppTextStyles.h3),
        content: Text(
          'Yakin ingin menghapus peminjaman "${item['fasilitas']}" dari ${item['peminjam']}?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDelete(item);
            },
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> item) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Permintaan', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pemohon: ${item['peminjam']}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            const Text('Alasan Penolakan', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              _handleStatus(
                item,
                'Ditolak',
                catatanAdmin: reasonCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: NeuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Gagal memuat data', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selectedIndex == i
                    ? AppColors.primaryDark
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedIndex == i
                      ? AppColors.primaryDark
                      : AppColors.divider,
                ),
                boxShadow: selectedIndex == i
                    ? [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selectedIndex == i
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GedungTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  const _GedungTile({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Disetujui':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    final isPending = status == 'Menunggu';
    final ruangan = data['ruangan'] as String;
    final info = kRuanganInfo[ruangan];

    final Color roomColor = info != null
        ? info['color'] as Color
        : AppColors.primary;

    final IconData roomIcon = info != null
        ? info['icon'] as IconData
        : Icons.meeting_room_rounded;

    return NeuCard(
      onTap: onDetail,
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [roomColor, Color.lerp(roomColor, Colors.black, 0.3)!],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(roomIcon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ruangan,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                StatusBadge(label: status, color: _statusColor(status)),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'hapus') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'hapus',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _AdminPeminjamanContent(
              data: data,
              icon: Icons.business_outlined,
              isPending: isPending,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ),
        ],
      ),
    );
  }
}

class _KendaraanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  const _KendaraanTile({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Disetujui':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    final isPending = status == 'Menunggu';

    return NeuCard(
      onTap: onDetail,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data['fasilitas'] as String,
                  style: AppTextStyles.h4,
                ),
              ),
              StatusBadge(label: status, color: _statusColor(status)),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'hapus') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _AdminPeminjamanContent(
            data: data,
            icon: Icons.directions_car_outlined,
            isPending: isPending,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ],
      ),
    );
  }
}

class _AdminPeminjamanContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final IconData icon;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdminPeminjamanContent({
    required this.data,
    required this.icon,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final peserta = data['peserta'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['peminjam'] as String, style: AppTextStyles.h4),
                  Text(
                    '${data['unit']} • ${data['nip']}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 10),
        _AdminInfoRow(
          icon: Icons.description_outlined,
          text: data['tujuan'] as String,
        ),
        const SizedBox(height: 5),
        _AdminInfoRow(
          icon: Icons.calendar_today_outlined,
          text: '${data['tanggal']} • ${data['waktu']}',
        ),
        const SizedBox(height: 5),
        if (peserta > 0)
          _AdminInfoRow(icon: Icons.people_outline, text: '$peserta peserta')
        else
          _AdminInfoRow(icon: icon, text: data['fasilitas'] as String),
        if (isPending) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AdminInfoRow({required this.icon, required this.text});

  Color _iconColor() {
    if (icon == Icons.calendar_today_outlined) {
      return AppColors.primaryDark;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _iconColor()),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

class _AdminDetailPeminjamanScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminDetailPeminjamanScreen({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    final tipe = data['tipe_item'] as String;
    final statusColor = _statusColor(status);
    final isGedung = tipe == 'ruangan' || tipe == 'gedung';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isGedung ? 'Detail Peminjaman Gedung' : 'Detail Kendaraan'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus',
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'Disetujui'
                        ? Icons.check_circle_rounded
                        : status == 'Ditolak'
                        ? Icons.cancel_rounded
                        : Icons.pending_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (isGedung) RuanganInfoCard(ruangan: data['ruangan'] as String),
            if (isGedung) const SizedBox(height: 14),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pemohon', style: AppTextStyles.h3),
                  const SizedBox(height: 14),
                  _DetailRowAdmin(
                    label: 'Peminjam',
                    value: data['peminjam'] as String,
                    icon: Icons.person_outline,
                  ),
                  _DetailRowAdmin(
                    label: 'NIP',
                    value: data['nip'] as String,
                    icon: Icons.badge_outlined,
                  ),
                  _DetailRowAdmin(
                    label: 'Unit',
                    value: data['unit'] as String,
                    icon: Icons.account_balance_outlined,
                  ),
                  _DetailRowAdmin(
                    label: isGedung ? 'Ruangan' : 'Kendaraan',
                    value: data['fasilitas'] as String,
                    icon: isGedung
                        ? Icons.meeting_room_outlined
                        : Icons.directions_car_outlined,
                  ),
                  _DetailRowAdmin(
                    label: 'Tujuan',
                    value: data['tujuan'] as String,
                    icon: Icons.description_outlined,
                  ),
                  _DetailRowAdmin(
                    label: 'Tanggal',
                    value: data['tanggal'] as String,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _DetailRowAdmin(
                    label: 'Waktu',
                    value: data['waktu'] as String,
                    icon: Icons.access_time,
                  ),
                  if ((data['peserta'] as int) > 0)
                    _DetailRowAdmin(
                      label: 'Peserta',
                      value: '${data['peserta']} orang',
                      icon: Icons.people_outline,
                    ),
                  _DetailRowAdmin(
                    label: 'Keperluan',
                    value: data['keperluan'] as String,
                    icon: Icons.notes_outlined,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (status == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowAdmin extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _DetailRowAdmin({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  Color _iconColor() {
    if (icon == Icons.calendar_today_outlined) {
      return AppColors.primaryDark;
    }
    return AppColors.primaryDark.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: _iconColor()),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _EditTimeBox extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _EditTimeBox({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(text, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
