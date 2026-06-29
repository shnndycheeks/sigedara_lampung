import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/database_service.dart';

class AdminPegawaiScreen extends StatefulWidget {
  const AdminPegawaiScreen({super.key});

  @override
  State<AdminPegawaiScreen> createState() => _AdminPegawaiScreenState();
}

class _AdminPegawaiScreenState extends State<AdminPegawaiScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  List<Map<String, dynamic>> _pegawaiList = [];

  @override
  void initState() {
    super.initState();
    _loadPegawai();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPegawai() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DatabaseService.getPegawaiProfiles();

      if (!mounted) return;

      setState(() {
        _pegawaiList = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPegawai {
    if (_searchQuery.trim().isEmpty) return _pegawaiList;

    final q = _searchQuery.toLowerCase();

    return _pegawaiList.where((p) {
      final nama = (p['nama'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      final nip = (p['nip'] ?? '').toString().toLowerCase();
      final jabatan = (p['jabatan'] ?? '').toString().toLowerCase();
      final status = (p['status'] ?? '').toString().toLowerCase();

      return nama.contains(q) ||
          email.contains(q) ||
          nip.contains(q) ||
          jabatan.contains(q) ||
          status.contains(q);
    }).toList();
  }

  String _formatTanggal(dynamic value) {
    if (value == null) return '-';

    try {
      final dt = DateTime.parse(value.toString()).toLocal();

      String dua(int n) => n.toString().padLeft(2, '0');

      return '${dua(dt.day)}/${dua(dt.month)}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _ubahStatusPegawai(Map<String, dynamic> data) async {
    final id = data['id']?.toString();

    if (id == null || id.isEmpty || id == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pegawai tidak ditemukan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentStatus = (data['status'] ?? 'aktif').toString().toLowerCase();
    final newStatus = currentStatus == 'aktif' ? 'nonaktif' : 'aktif';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          newStatus == 'aktif' ? 'Aktifkan Pegawai' : 'Nonaktifkan Pegawai',
          style: AppTextStyles.h3,
        ),
        content: Text(
          newStatus == 'aktif'
              ? 'Aktifkan kembali akun "${data['nama']}"?'
              : 'Nonaktifkan akun "${data['nama']}"?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'aktif' ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(newStatus == 'aktif' ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DatabaseService.updateStatusPegawai(
        userId: id,
        status: newStatus,
      );

      if (!mounted) return;

      await _loadPegawai();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'aktif'
                ? 'Pegawai berhasil diaktifkan'
                : 'Pegawai berhasil dinonaktifkan',
          ),
          backgroundColor:
              newStatus == 'aktif' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status pegawai: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDetailPegawai(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailPegawaiSheet(
        data: data,
        tanggal: _formatTanggal(data['created_at']),
        onUbahStatus: () {
          Navigator.pop(context);
          _ubahStatusPegawai(data);
        },
      ),
    );
  }

  int get _totalAktif {
    return _pegawaiList.where((p) {
      return (p['status'] ?? 'aktif').toString().toLowerCase() == 'aktif';
    }).length;
  }

  int get _totalNonaktif {
    return _pegawaiList.where((p) {
      return (p['status'] ?? 'aktif').toString().toLowerCase() == 'nonaktif';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPegawai;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Pegawai'),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPegawai,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Cari nama, email, NIP, jabatan...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'Aktif',
                    value: '$_totalAktif',
                    icon: Icons.verified_user_outlined,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    label: 'Nonaktif',
                    value: '$_totalNonaktif',
                    icon: Icons.block_outlined,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? RefreshIndicator(
                        onRefresh: _loadPegawai,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                              icon: Icons.error_outline,
                              title: 'Gagal memuat pegawai',
                              subtitle:
                                  'Cek koneksi atau policy tabel profiles',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPegawai,
                        child: filtered.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(20),
                                children: const [
                                  SizedBox(height: 120),
                                  EmptyState(
                                    icon: Icons.person_search_outlined,
                                    title: 'Pegawai tidak ditemukan',
                                    subtitle:
                                        'Coba gunakan kata kunci lain',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final item = filtered[i];

                                  return _PegawaiTile(
                                    data: item,
                                    tanggal:
                                        _formatTanggal(item['created_at']),
                                    onTap: () => _showDetailPegawai(item),
                                    onUbahStatus: () =>
                                        _ubahStatusPegawai(item),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PegawaiTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tanggal;
  final VoidCallback onTap;
  final VoidCallback onUbahStatus;

  const _PegawaiTile({
    required this.data,
    required this.tanggal,
    required this.onTap,
    required this.onUbahStatus,
  });

  Color _statusColor(String status) {
    return status == 'aktif' ? AppColors.success : AppColors.error;
  }

  String _statusLabel(String status) {
    return status == 'aktif' ? 'Aktif' : 'Nonaktif';
  }

  @override
  Widget build(BuildContext context) {
    final nama = (data['nama'] ?? '-').toString();
    final email = (data['email'] ?? '-').toString();
    final nip = (data['nip'] ?? '-').toString();
    final jabatan = (data['jabatan'] ?? '-').toString();
    final status = (data['status'] ?? 'aktif').toString().toLowerCase();
    final isAktif = status == 'aktif';

    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAktif
                    ? [
                        AppColors.primaryDark.withValues(alpha: 0.90),
                        AppColors.primary.withValues(alpha: 0.90),
                      ]
                    : [
                        AppColors.textSecondary.withValues(alpha: 0.90),
                        AppColors.textHint.withValues(alpha: 0.90),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAktif ? Icons.person_rounded : Icons.person_off_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        nip == 'null' || nip.isEmpty ? 'NIP: -' : 'NIP: $nip',
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        jabatan == 'null' || jabatan.isEmpty
                            ? 'Jabatan: -'
                            : jabatan,
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
              const SizedBox(height: 8),
              Text(
                tanggal,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
              IconButton(
                tooltip: isAktif ? 'Nonaktifkan' : 'Aktifkan',
                onPressed: onUbahStatus,
                icon: Icon(
                  isAktif ? Icons.block_outlined : Icons.check_circle_outline,
                  color: isAktif ? AppColors.error : AppColors.success,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailPegawaiSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tanggal;
  final VoidCallback onUbahStatus;

  const _DetailPegawaiSheet({
    required this.data,
    required this.tanggal,
    required this.onUbahStatus,
  });

  @override
  Widget build(BuildContext context) {
    final nama = (data['nama'] ?? '-').toString();
    final email = (data['email'] ?? '-').toString();
    final role = (data['role'] ?? '-').toString();
    final nip = (data['nip'] ?? '-').toString();
    final jabatan = (data['jabatan'] ?? '-').toString();
    final status = (data['status'] ?? 'aktif').toString().toLowerCase();
    final isAktif = status == 'aktif';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAktif
                    ? const [AppColors.primaryDark, AppColors.primary]
                    : [
                        AppColors.textSecondary.withValues(alpha: 0.9),
                        AppColors.textHint.withValues(alpha: 0.9),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              isAktif ? Icons.person_rounded : Icons.person_off_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          StatusBadge(
            label: isAktif ? 'Aktif' : 'Nonaktif',
            color: isAktif ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 18),
          NeuCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _DetailRowPegawai(
                  icon: Icons.verified_user_outlined,
                  label: 'Role',
                  value: role,
                ),
                _DetailRowPegawai(
                  icon: Icons.badge_outlined,
                  label: 'NIP',
                  value: nip == 'null' || nip.isEmpty ? '-' : nip,
                ),
                _DetailRowPegawai(
                  icon: Icons.work_outline,
                  label: 'Jabatan',
                  value: jabatan == 'null' || jabatan.isEmpty ? '-' : jabatan,
                ),
                _DetailRowPegawai(
                  icon: Icons.calendar_today_outlined,
                  label: 'Terdaftar',
                  value: tanggal,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Tutup',
                  icon: Icons.close,
                  outlined: true,
                  outlinedBorderColor: AppColors.primaryDark,
                  outlinedTextColor: AppColors.primaryDark,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: isAktif ? 'Nonaktifkan' : 'Aktifkan',
                  icon: isAktif
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  onPressed: onUbahStatus,
                  gradientColors: isAktif
                      ? const [AppColors.error, Color(0xFFB91C1C)]
                      : const [AppColors.success, Color(0xFF059669)],
                  shadowColor: isAktif ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRowPegawai extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRowPegawai({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryDark.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
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
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}