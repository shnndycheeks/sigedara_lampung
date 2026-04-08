import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class AdminPersetujuanScreen extends StatefulWidget {
  const AdminPersetujuanScreen({super.key});

  @override
  State<AdminPersetujuanScreen> createState() => _AdminPersetujuanScreenState();
}

class _AdminPersetujuanScreenState extends State<AdminPersetujuanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _filterIndex = 0;

  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Persetujuan'),
        backgroundColor: AppColors.primaryDark,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            NavigationService.goHomeAdmin?.call();
          },
        ),
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
      body: TabBarView(
        controller: _tab,
        children: [
          _buildPersetujuanTab(_gedungData),
          _buildPersetujuanTab(_kendaraanData),
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

    return Column(
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
              ? const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Tidak ada data',
                  subtitle: 'Tidak ada permintaan dengan filter ini',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PersetujuanTile(
                    data: filtered[i],
                    onApprove: () => _handleAction(filtered[i], 'Disetujui'),
                    onReject: () => _showRejectDialog(context, filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _handleAction(Map<String, dynamic> item, String newStatus) {
    setState(() {
      item['status'] = newStatus;
    });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> item) {
    final _reasonCtrl = TextEditingController();
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
              controller: _reasonCtrl,
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
              _handleAction(item, 'Ditolak');
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

  final List<Map<String, dynamic>> _gedungData = [
    {
      'nama': 'Drs. Budi Santoso',
      'nip': '197203141998031002',
      'unit': 'Dinas Pendidikan',
      'fasilitas': 'Gedung Serba Guna',
      'tgl_pinjam': '10 Apr 2026',
      'tgl_kembali': '10 Apr 2026',
      'keperluan': 'Rapat Koordinasi',
      'status': 'Menunggu',
    },
    {
      'nama': 'Hj. Siti Rahayu',
      'nip': '198005201999032001',
      'unit': 'Dinas Kesehatan',
      'fasilitas': 'Aula Utama',
      'tgl_pinjam': '12 Apr 2026',
      'tgl_kembali': '12 Apr 2026',
      'keperluan': 'Seminar Kesehatan',
      'status': 'Menunggu',
    },
    {
      'nama': 'Ahmad Supriyanto',
      'nip': '197810112002121003',
      'unit': 'Sekretariat',
      'fasilitas': 'Ruang Rapat Lt. 2',
      'tgl_pinjam': '08 Apr 2026',
      'tgl_kembali': '08 Apr 2026',
      'keperluan': 'Rapat Internal',
      'status': 'Disetujui',
    },
    {
      'nama': 'Dra. Wulandari',
      'nip': '197402181996032001',
      'unit': 'Dinas Sosial',
      'fasilitas': 'Ruang Rapat Lt. 1',
      'tgl_pinjam': '05 Apr 2026',
      'tgl_kembali': '05 Apr 2026',
      'keperluan': 'Pelatihan Staf',
      'status': 'Ditolak',
    },
  ];

  final List<Map<String, dynamic>> _kendaraanData = [
    {
      'nama': 'M. Rizal, S.Kom',
      'nip': '199001152015031001',
      'unit': 'Biro Umum',
      'fasilitas': 'Toyota Innova — B 1234 XY',
      'tgl_pinjam': '11 Apr 2026',
      'tgl_kembali': '12 Apr 2026',
      'keperluan': 'Kunjungan Kerja ke Jakarta',
      'status': 'Menunggu',
    },
    {
      'nama': 'Hj. Ratna W.',
      'nip': '198503252010012002',
      'unit': 'Dinas PUPR',
      'fasilitas': 'Toyota Avanza — BE 5555 AA',
      'tgl_pinjam': '09 Apr 2026',
      'tgl_kembali': '09 Apr 2026',
      'keperluan': 'Survei Lapangan',
      'status': 'Disetujui',
    },
    {
      'nama': 'Agus Salim',
      'nip': '198712202012011003',
      'unit': 'Inspektorat',
      'fasilitas': 'Mitsubishi Pajero — BE 9999 ZZ',
      'tgl_pinjam': '06 Apr 2026',
      'tgl_kembali': '07 Apr 2026',
      'keperluan': 'Audit Lapangan',
      'status': 'Ditolak',
    },
  ];
}

// ── Persetujuan Tile ──────────────────────────────────────────────────────────
class _PersetujuanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PersetujuanTile({
    required this.data,
    required this.onApprove,
    required this.onReject,
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
                      '${data['unit']} • ${data['nip']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: status, color: _statusColor(status)),
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
            text: '${data['tgl_pinjam']} — ${data['tgl_kembali']}',
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.notes_outlined,
            text: data['keperluan'] as String,
          ),
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
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}
