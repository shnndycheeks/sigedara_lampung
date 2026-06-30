import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';

class AdminPersetujuanScreen extends StatefulWidget {
  const AdminPersetujuanScreen({super.key});

  @override
  State<AdminPersetujuanScreen> createState() => _AdminPersetujuanScreenState();
}

class _AdminPersetujuanScreenState extends State<AdminPersetujuanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  int _filterIndex = 0;
  bool _loading = true;
  String? _error;

  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

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
      final pegawai = await DatabaseService.getPegawaiProfiles();
      final ruangan = await DatabaseService.getRuangan();
      final kendaraan = await DatabaseService.getKendaraan();

      final Map<String, Map<String, dynamic>> pegawaiById = {
        for (final p in pegawai) p['id'].toString(): p,
      };

      final Map<String, Map<String, dynamic>> ruanganById = {
        for (final r in ruangan) r['id'].toString(): r,
      };

      final Map<String, Map<String, dynamic>> kendaraanById = {
        for (final k in kendaraan) k['id'].toString(): k,
      };

      final List<Map<String, dynamic>> gedungTemp = [];
      final List<Map<String, dynamic>> kendaraanTemp = [];

      for (final item in peminjaman) {
        final tipe = (item['tipe_item'] ?? '').toString().toLowerCase();
        final userId = (item['user_id'] ?? '').toString();
        final itemId = (item['item_id'] ?? '').toString();

        final profile = pegawaiById[userId];

        final mapped = {
          'id': item['id'],
          'nama': _namaPegawai(profile),
          'nip': _nipPegawai(profile),
          'unit': _unitPegawai(profile),
          'fasilitas': tipe == 'kendaraan'
              ? _namaKendaraan(kendaraanById[itemId], itemId)
              : _namaRuangan(ruanganById[itemId], itemId),
          'tgl_pinjam': _formatTanggal(item['tanggal_mulai']),
          'tgl_kembali': _formatTanggal(item['tanggal_selesai']),
          'waktu': _formatWaktuRange(
            item['tanggal_mulai'],
            item['tanggal_selesai'],
          ),
          'keperluan': (item['keperluan'] ?? '-').toString(),
          'status': _formatStatus(item['status']),
          'status_db': (item['status'] ?? 'pending').toString(),
          'catatan_admin': item['catatan_admin'],
          'tipe_item': tipe,
        };

        if (tipe == 'kendaraan') {
          kendaraanTemp.add(mapped);
        } else if (tipe == 'ruangan' || tipe == 'gedung') {
          gedungTemp.add(mapped);
        }
      }

      if (!mounted) return;

      setState(() {
        _gedungData = gedungTemp;
        _kendaraanData = kendaraanTemp;
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

  static String _namaPegawai(Map<String, dynamic>? profile) {
    if (profile == null) return 'Pegawai tidak ditemukan';

    final nama = (profile['nama'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();

    if (nama.isNotEmpty) return nama;
    if (email.isNotEmpty) return email;

    return 'Pegawai';
  }

  static String _nipPegawai(Map<String, dynamic>? profile) {
    if (profile == null) return '-';

    final nip = (profile['nip'] ?? '').toString().trim();
    if (nip.isEmpty || nip == 'null') return '-';

    return nip;
  }

  static String _unitPegawai(Map<String, dynamic>? profile) {
    if (profile == null) return '-';

    final jabatan = (profile['jabatan'] ?? '').toString().trim();
    if (jabatan.isEmpty || jabatan == 'null') return 'Pegawai';

    return jabatan;
  }

  static String _namaRuangan(Map<String, dynamic>? data, String fallback) {
    if (data == null) return fallback;

    return (data['nama'] ??
            data['nama_ruangan'] ??
            data['ruangan'] ??
            data['name'] ??
            fallback)
        .toString();
  }

  static String _namaKendaraan(Map<String, dynamic>? data, String fallback) {
    if (data == null) return fallback;

    final nama = (data['nama'] ??
            data['nama_kendaraan'] ??
            data['merk'] ??
            data['jenis'] ??
            'Kendaraan')
        .toString();

    final plat = (data['plat_nomor'] ??
            data['nomor_polisi'] ??
            data['no_polisi'] ??
            data['nopol'] ??
            '')
        .toString()
        .trim();

    if (plat.isEmpty || plat == 'null') return nama;

    return '$nama - $plat';
  }

  static String _formatStatus(dynamic value) {
    final status = (value ?? 'pending').toString().toLowerCase();

    if (status == 'disetujui' ||
        status == 'approved' ||
        status == 'approve' ||
        status == 'accepted') {
      return 'Disetujui';
    }

    if (status == 'ditolak' ||
        status == 'rejected' ||
        status == 'reject' ||
        status == 'declined') {
      return 'Ditolak';
    }

    return 'Menunggu';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _formatTanggal(dynamic value) {
    final date = _parseDate(value);

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

  static String _formatJam(dynamic value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatWaktuRange(dynamic mulai, dynamic selesai) {
    return '${_formatJam(mulai)} - ${_formatJam(selesai)} WIB';
  }

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

  Future<void> _handleAction(
    Map<String, dynamic> item,
    String newStatus, {
    String? catatanAdmin,
  }) async {
    final id = item['id']?.toString();

    if (id == null || id.isEmpty || id == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID peminjaman tidak ditemukan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dbStatus = newStatus == 'Disetujui' ? 'disetujui' : 'ditolak';

    try {
      await DatabaseService.updateStatusPeminjaman(
        peminjamanId: id,
        status: dbStatus,
        catatanAdmin: catatanAdmin,
      );

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Disetujui'
                ? 'Permintaan dari ${item['nama']} disetujui.'
                : 'Permintaan dari ${item['nama']} ditolak.',
          ),
          backgroundColor: newStatus == 'Disetujui'
              ? AppColors.success
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            Text('Pemohon: ${item['nama']}', style: AppTextStyles.bodySmall),
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
            onPressed: () {
              reasonCtrl.dispose();
              Navigator.pop(context);
            },
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              reasonCtrl.dispose();
              Navigator.pop(context);

              _handleAction(
                item,
                'Ditolak',
                catatanAdmin: reason.isEmpty ? 'Ditolak oleh admin' : reason,
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

  Widget _buildPersetujuanTab(List<Map<String, dynamic>> data) {
    final filtered = _filterIndex == 0
        ? data
        : data
            .where(
              (d) =>
                  d['status'].toString().toLowerCase() ==
                  _filters[_filterIndex].toLowerCase(),
            )
            .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _filterIndex == i
                          ? AppColors.primaryDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filterIndex == i
                            ? AppColors.primaryDark
                            : AppColors.divider,
                      ),
                      boxShadow: _filterIndex == i
                          ? [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _filterIndex == i
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Tidak ada data',
                        subtitle: 'Tidak ada permintaan dengan filter ini',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _PersetujuanTile(
                      data: filtered[i],
                      statusColor: _statusColor(filtered[i]['status']),
                      onApprove: () =>
                          _handleAction(filtered[i], 'Disetujui'),
                      onReject: () => _showRejectDialog(context, filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 120),
            EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal memuat persetujuan',
              subtitle: _error!,
            ),
          ],
        ),
      );
    } else {
      body = TabBarView(
        controller: _tab,
        children: [
          _buildPersetujuanTab(_gedungData),
          _buildPersetujuanTab(_kendaraanData),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Persetujuan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AdminColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              NavigationService.goHomeAdmin?.call();
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
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
            Tab(text: 'Pinjam Kendaraan'),
          ],
        ),
      ),
      body: body,
    );
  }
}

class _PersetujuanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PersetujuanTile({
    required this.data,
    required this.statusColor,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    final isPending = status == 'Menunggu';

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'] as String, style: AppTextStyles.h4),
                    Text(
                      '${data['unit']} - ${data['nip']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.place_outlined,
            text: data['fasilitas'] as String,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text: '${data['tgl_pinjam']} - ${data['tgl_kembali']}',
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.access_time,
            text: data['waktu'] as String,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.notes_outlined,
            text: data['keperluan'] as String,
          ),
          if (data['catatan_admin'] != null &&
              data['catatan_admin'].toString().trim().isNotEmpty &&
              data['catatan_admin'].toString() != 'null') ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.comment_outlined,
              text: 'Catatan admin: ${data['catatan_admin']}',
            ),
          ],
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

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