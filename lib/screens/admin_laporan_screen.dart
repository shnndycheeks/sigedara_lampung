import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import '../services/permission_service.dart';

class AdminLaporanScreen extends StatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  State<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends State<AdminLaporanScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  int _filterIndex = 0;
  bool _loading = true;
  String? _error;

  final List<String> _filters = ['Semua', 'Proses', 'Selesai', 'Ditolak'];
  List<Map<String, dynamic>> _laporanList = [];

  List<Map<String, dynamic>> get _filteredList {
    if (_filterIndex == 0) return _laporanList;

    final status = _filters[_filterIndex].toLowerCase();

    return _laporanList.where((item) {
      return _safeText(item['status']).toLowerCase() == status;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }
    return text;
  }

  String _formatTanggal(dynamic value) {
    final parsed = DateTime.tryParse(_safeText(value));
    if (parsed == null) return '-';

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

    return '${parsed.day.toString().padLeft(2, '0')} '
        '${bulan[parsed.month]} ${parsed.year}';
  }

  String _formatKodeLaporan(Map<String, dynamic> item) {
    final createdAt = DateTime.tryParse(_safeText(item['created_at']));
    final year = createdAt?.year ?? DateTime.now().year;
    final id = _safeText(item['id']);

    if (id.length >= 8) {
      return 'LK-$year-${id.substring(0, 8).toUpperCase()}';
    }

    return 'LK-$year-$id';
  }

  Future<void> _loadLaporan() async {
    if (!PermissionService.canAccessLaporanKendaraan) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Akses laporan kendaraan ditolak.';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _client
          .from('laporan_kerusakan')
          .select()
          .eq('jenis_aset', 'Kendaraan')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _laporanList = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<bool> _updateStatus(
    Map<String, dynamic> item,
    String newStatus,
    String catatanAdmin,
  ) async {
    final id = item['id'];

    try {
      await _client
          .from('laporan_kerusakan')
          .update({
            'status': newStatus,
            'catatan_admin': catatanAdmin.trim().isEmpty
                ? null
                : catatanAdmin.trim(),
          })
          .eq('id', id);

      if (!mounted) return false;

      await _loadLaporan();

      if (!mounted) return false;

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui laporan: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }
  }

  Future<bool> _showUpdateDialog(Map<String, dynamic> item) async {
    String newStatus = _safeText(item['status'], fallback: 'Proses');

    final catatanController = TextEditingController(
      text: _safeText(item['catatan_admin'], fallback: ''),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Status Laporan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatKodeLaporan(item),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: ['Proses', 'Selesai', 'Ditolak'].map((status) {
                      final selected = newStatus == status;
                      final color = _statusColor(status);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              newStatus = status;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(alpha: 0.12)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 1.3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? color
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: catatanController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Catatan Admin',
                      hintText: 'Tambahkan catatan untuk pegawai...',
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
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      'status': newStatus,
                      'catatan': catatanController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Dialog sudah benar-benar tertutup di sini.
    catatanController.dispose();

    if (result == null) {
      return false;
    }

    final status = result['status'] as String;
    final catatan = result['catatan'] as String;

    return await _updateStatus(item, status, catatan);
  }

  void _showDetail(Map<String, dynamic> item) {
    final status = _safeText(item['status'], fallback: 'Proses');
    final tingkat = _safeText(item['tingkat'], fallback: 'Ringan');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeText(item['nama_aset']),
                            style: AppTextStyles.h3.copyWith(fontSize: 16),
                          ),
                          Text(
                            _safeText(item['kode_aset']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _badge(status, _statusColor(status)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                _detailRow('No. Laporan', _formatKodeLaporan(item)),
                _detailRow('Pelapor', _safeText(item['nama_pelapor'])),
                _detailRow('Unit / Divisi', _safeText(item['unit'])),
                _detailRow('Nama Kendaraan', _safeText(item['nama_aset'])),
                _detailRow('Nomor Polisi', _safeText(item['kode_aset'])),
                _detailRow('Lokasi', _safeText(item['lokasi'])),
                _detailRow(
                  'Tanggal Kejadian',
                  _formatTanggal(item['tanggal_kejadian']),
                ),
                _detailRow(
                  'Tingkat Kerusakan',
                  tingkat,
                  valueColor: _tingkatColor(tingkat),
                ),
                if (_safeText(item['catatan_admin']).trim() != '-') ...[
                  _detailRow(
                    'Catatan Admin',
                    _safeText(item['catatan_admin']),
                    valueColor: AppColors.textSecondary,
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Deskripsi Kerusakan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _safeText(item['deskripsi']),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Simpan object yang dibutuhkan SEBELUM async gap.
                      final navigator = Navigator.of(sheetContext);
                      final messenger = ScaffoldMessenger.of(context);

                      final updated = await _showUpdateDialog(item);

                      if (!mounted) return;
                      if (!navigator.mounted) return;
                      if (!messenger.mounted) return;

                      if (updated) {
                        navigator.pop();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Laporan ${_formatKodeLaporan(item)} berhasil diubah.',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    label: const Text(
                      'Update Status',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'proses':
        return AppColors.warning;
      case 'selesai':
        return AppColors.success;
      case 'ditolak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _tingkatColor(String tingkat) {
    switch (tingkat.toLowerCase()) {
      case 'ringan':
        return AppColors.success;
      case 'sedang':
        return AppColors.warning;
      case 'berat':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.canAccessLaporanKendaraan) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Akses Ditolak',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AdminColors.primary,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => NavigationService.goHomeAdmin?.call(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Anda tidak memiliki izin untuk mengakses laporan kerusakan kendaraan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final list = _filteredList;
    final total = _laporanList.length;
    final proses = _laporanList
        .where((e) => _safeText(e['status']) == 'Proses')
        .length;
    final selesai = _laporanList
        .where((e) => _safeText(e['status']) == 'Selesai')
        .length;
    final ditolak = _laporanList
        .where((e) => _safeText(e['status']) == 'Ditolak')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Laporan Kerusakan Kendaraan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AdminColors.primary,
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
            onPressed: _loading ? null : _loadLaporan,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text('Gagal memuat laporan', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadLaporan,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _summaryCard(
                        'Total',
                        total.toString(),
                        AppColors.primary,
                        Icons.report_problem_outlined,
                      ),
                      const SizedBox(width: 7),
                      _summaryCard(
                        'Proses',
                        proses.toString(),
                        AppColors.warning,
                        Icons.hourglass_top_rounded,
                      ),
                      const SizedBox(width: 7),
                      _summaryCard(
                        'Selesai',
                        selesai.toString(),
                        AppColors.success,
                        Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 7),
                      _summaryCard(
                        'Ditolak',
                        ditolak.toString(),
                        AppColors.error,
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filters.length, (i) {
                        final selected = _filterIndex == i;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filters[i]),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceVariant,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            onSelected: (_) {
                              setState(() => _filterIndex = i);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: list.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadLaporan,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 140),
                              Icon(
                                Icons.directions_car_outlined,
                                size: 58,
                                color: AppColors.textHint,
                              ),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Belum ada laporan kerusakan kendaraan',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'Tarik ke bawah untuk memuat ulang',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLaporan,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(14),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              return _laporanTile(list[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 9.5, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _laporanTile(Map<String, dynamic> item) {
    final status = _safeText(item['status'], fallback: 'Proses');
    final tingkat = _safeText(item['tingkat'], fallback: 'Ringan');

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeText(item['nama_aset']),
                      style: AppTextStyles.h4.copyWith(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_safeText(item['kode_aset'])} · '
                      '${_safeText(item['nama_pelapor'])}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(tingkat, _tingkatColor(tingkat)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatTanggal(item['tanggal_kejadian']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge(status, _statusColor(status)),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
