import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';
import 'peminjaman_screen.dart';
import 'kendaraan_screen.dart';
import 'notifikasi_screen.dart';
import 'aset_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String _namaUser = 'Pegawai';
  String _unitUser = 'Divisi Rumah Tangga';

  int _totalPeminjamanGedung = 0;
  int _totalKendaraan = 0;
  int _totalAset = 0;
  int _menungguPersetujuan = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = _client.auth.currentUser;

      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('nama, jabatan')
            .eq('id', user.id)
            .maybeSingle();

        final stats = await DatabaseService.getDashboardStats();

        if (!mounted) return;

        if (profile != null) {
          final nama = (profile['nama'] ?? '').toString().trim();
          final jabatan = (profile['jabatan'] ?? '').toString().trim();

          _namaUser = nama.isEmpty ? 'Pegawai' : nama;
          _unitUser = jabatan.isEmpty || jabatan == 'null'
              ? 'Divisi Rumah Tangga'
              : jabatan;
        }

        _totalPeminjamanGedung = stats['peminjaman_gedung'] ?? 0;
        _totalKendaraan = stats['total_kendaraan'] ?? 0;
        _totalAset = stats['total_aset'] ?? 0;
        _menungguPersetujuan = stats['menunggu_persetujuan'] ?? 0;
      }
    } catch (_) {
      // Kalau gagal ambil data, dashboard tetap tampil dengan angka default.
    }

    await Future.delayed(const Duration(milliseconds: 450));

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _loading = true);
    await _loadDashboardData();
  }

  String get _salam {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  String get _tanggalHariIni {
    final now = DateTime.now();

    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const bulan = [
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

    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  String get _teksMenunggu {
    if (_menungguPersetujuan == 0) {
      return 'Semua pengajuan kamu sudah tertangani';
    }

    return '$_menungguPersetujuan pengajuan masih menunggu persetujuan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 235,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primaryDark,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: _loading ? _buildSkeleton() : _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            Color(0xFFE5BE34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: 50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -35,
            bottom: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SIGEDARA LAMPUNG',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _unitUser,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.search_rounded,
                        onTap: () => _showSearch(context),
                      ),
                      const SizedBox(width: 8),
                      _HeaderIconButton(
                        icon: Icons.report_problem_outlined,
                        onTap: () => NavigationService.goToTabUser?.call(4),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _HeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotifikasiScreen(),
                              ),
                            ),
                          ),
                          if (_menungguPersetujuan > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  _menungguPersetujuan > 9
                                      ? '9+'
                                      : '$_menungguPersetujuan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Selamat $_salam,',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _namaUser,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _tanggalHariIni,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: double.infinity, height: 74),
        SizedBox(height: 18),
        SkeletonBox(width: 150, height: 18),
        SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 150),
        SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 92),
        SizedBox(height: 22),
        SkeletonBox(width: 150, height: 18),
        SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 82),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ApprovalNoticeCard(
          text: _teksMenunggu,
          count: _menungguPersetujuan,
          onTap: () => NavigationService.goToTabUser?.call(1),
        ),
        const SizedBox(height: 22),
        const Text(
          'Ringkasan Aktivitas',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ModernStatCard(
                title: 'Peminjaman Gedung',
                value: '$_totalPeminjamanGedung',
                subtitle: 'pengajuan',
                icon: Icons.business_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModernStatCard(
                title: 'Kendaraan Dinas',
                value: '$_totalKendaraan',
                subtitle: 'unit tersedia',
                icon: Icons.directions_car_rounded,
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KendaraanScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideStatCard(
          title: 'Aset & Inventaris',
          value: '$_totalAset',
          subtitle: 'item tercatat di sistem',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => AsetScreen(onBack: () => Navigator.pop(ctx)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Akses Cepat',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_business_rounded,
                label: 'Ajukan Gedung',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.car_rental_rounded,
                label: 'Pinjam Kendaraan',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KendaraanScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.warning_amber_rounded,
                label: 'Lapor Rusak',
                color: AppColors.error,
                onTap: () => NavigationService.goToTabUser?.call(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _ReminderPanel(
          onTap: () => NavigationService.goToTabUser?.call(3),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Aktivitas Terkini',
          actionLabel: 'Lihat Semua',
          onAction: () => NavigationService.goToTabUser?.call(4),
        ),
        const SizedBox(height: 12),
        ..._recentActivities.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityTile(data: a),
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Pengingat Jadwal'),
        const SizedBox(height: 12),
        ..._reminders.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReminderTile(data: r),
          ),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _GlobalSearch());
  }

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'icon': Icons.business,
      'title': 'Peminjaman Ruang Abung',
      'sub': 'Menunggu persetujuan admin',
      'status': 'Menunggu',
      'color': AppColors.warning,
    },
    {
      'icon': Icons.directions_car,
      'title': 'Kendaraan dinas',
      'sub': 'Cek ketersediaan unit kendaraan',
      'status': 'Aktif',
      'color': AppColors.success,
    },
    {
      'icon': Icons.build,
      'title': 'Servis aset berkala',
      'sub': 'Jadwal pemeliharaan rutin',
      'status': 'Info',
      'color': AppColors.info,
    },
  ];

  final List<Map<String, dynamic>> _reminders = [
    {
      'icon': Icons.receipt_long,
      'title': 'Pajak Kendaraan',
      'date': 'Pantau jatuh tempo kendaraan dinas',
      'days': 8,
      'color': AppColors.warning,
    },
    {
      'icon': Icons.build_circle,
      'title': 'Servis Rutin',
      'date': 'Cek jadwal pemeliharaan aset',
      'days': 13,
      'color': AppColors.info,
    },
  ];
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ApprovalNoticeCard extends StatelessWidget {
  final String text;
  final int count;
  final VoidCallback onTap;

  const _ApprovalNoticeCard({
    required this.text,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPending = count > 0;
    final Color color = hasPending ? AppColors.warning : AppColors.success;
    final IconData icon =
        hasPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending ? 'Perlu Dipantau' : 'Status Aman',
                      style: AppTextStyles.h4.copyWith(color: color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: AppTextStyles.caption.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(
                  icon,
                  size: 82,
                  color: color.withValues(alpha: 0.07),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontSize: 12,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _WideStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WideStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  final VoidCallback onTap;

  const _ReminderPanel({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFFD97706);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.20)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengingat Pajak & Servis',
                      style: AppTextStyles.h4.copyWith(color: color),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pantau jadwal pajak kendaraan, servis AC, dan KIR kendaraan.',
                      style: AppTextStyles.caption.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: data['color'] as Color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data['sub'] as String,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusBadge(
            label: data['status'] as String,
            color: data['color'] as Color,
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReminderTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: data['color'] as Color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data['date'] as String,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${data['days']}h',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: data['color'] as Color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSearch extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white54),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
      );

  final List<String> _allItems = [
    'Ruang Abung',
    'Ruang Sungkai',
    'Balai Keratun Lt. 3',
    'R. Rapat Utama',
    'Toyota Innova B 1234 XY',
    'Honda CRV B 5678 AB',
    'Mitsubishi Pajero B 9999 ZZ',
    'AC Ruang 201',
    'AC Ruang 202',
    'Genset Utama',
    'Printer Canon A3',
  ];

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = query.isEmpty
        ? _allItems
        : _allItems
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: 'Coba kata kunci lain',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.search, color: AppColors.primary),
        title: Text(results[i], style: AppTextStyles.body),
      ),
    );
  }
}