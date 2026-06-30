import 'dart:ui';
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
      backgroundColor: const Color(0xFFF8FAFC), // Light slate background
      body: Stack(
        children: [
          // Studio Spotlight Glows (Sangat halus, profesional, tidak mencolok)
          Positioned(
            top: 100,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: 0.06), // Spotlight biru sangat tipis
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.04), // Spotlight indigo sangat tipis
              ),
            ),
          ),
          // Blur tinggi untuk transisi yang sangat halus (studio lighting effect)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: const SizedBox(),
            ),
          ),
          
          // Konten Utama
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 235,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF0284C7), // Menyesuaikan warna header saat collapse
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0284C7), // Rich sky blue
            Color(0xFF1E40AF), // Deep royal blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Lingkaran dekoratif putih transparan untuk kedalaman visual
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
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
                      Image.asset(
                        'assets/images/logo_lampung.png',
                        height: 42,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 42,
                          height: 42,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIMASTER',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Sistem Informasi Aset Daerah',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _showSearch(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotifikasiScreen(),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selamat $_salam,',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _namaUser,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _unitUser,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _tanggalHariIni,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
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
        _StatusAmanCard(
          onTap: () => NavigationService.goToTabUser?.call(1),
        ),
        const SizedBox(height: 22),
        const Text(
          'Ringkasan Aktivitas',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _ActivityGrid(
          totalPeminjamanGedung: _totalPeminjamanGedung,
          totalKendaraan: _totalKendaraan,
          totalAset: _totalAset,
        ),
        const SizedBox(height: 22),
        const Text(
          'Akses Cepat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        const _QuickActionsRow(),
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

class _StatusAmanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StatusAmanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4).withValues(alpha: 0.8), // Transparan
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCFCE7).withValues(alpha: 0.8), width: 1.5), // Transparan
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), // Green 500
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Aman',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Green 700
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Semua pengajuan telah selesai dan tidak ada masalah.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF475569), // Slate 600
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF15803D),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityGrid extends StatelessWidget {
  final int totalPeminjamanGedung;
  final int totalKendaraan;
  final int totalAset;
  
  const _ActivityGrid({
    required this.totalPeminjamanGedung,
    required this.totalKendaraan,
    required this.totalAset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActivityCard(
                title: 'Pengajuan Gedung',
                value: '$totalPeminjamanGedung',
                badgeText: '+2 dari minggu lalu',
                badgeIcon: Icons.trending_up_rounded,
                icon: Icons.business_rounded,
                color: const Color(0xFF2563EB), // Blue
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActivityCard(
                title: 'Kendaraan Dinas',
                value: '$totalKendaraan',
                badgeText: '90% tersedia',
                badgeIcon: null,
                icon: Icons.directions_car_rounded,
                color: const Color(0xFF059669), // Green
                bgColor: const Color(0xFFECFDF5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KendaraanScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActivityCard(
          title: 'Aset & Inventaris',
          value: '$totalAset',
          badgeText: 'Item tercatat di sistem',
          badgeIcon: null,
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFFEA580C), // Orange
          bgColor: const Color(0xFFFFF7ED),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => AsetScreen(onBack: () => Navigator.pop(ctx)),
              ),
            );
          },
          isWide: true,
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String value;
  final String badgeText;
  final IconData? badgeIcon;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isWide;

  const _ActivityCard({
    required this.title,
    required this.value,
    required this.badgeText,
    this.badgeIcon,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> cardGradient;
    if (color == const Color(0xFF2563EB)) {
      cardGradient = [
        const Color(0xFFF0F6FF).withValues(alpha: 0.85),
        const Color(0xFFE0F2FE).withValues(alpha: 0.85)
      ]; // Blue transparan
    } else if (color == const Color(0xFF059669)) {
      cardGradient = [
        const Color(0xFFF0FDF4).withValues(alpha: 0.85),
        const Color(0xFFD1FAE5).withValues(alpha: 0.85)
      ]; // Green transparan
    } else {
      cardGradient = [
        const Color(0xFFFFF7ED).withValues(alpha: 0.85),
        const Color(0xFFFFEDD5).withValues(alpha: 0.85)
      ]; // Orange transparan
    }

    if (isWide) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 96,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  bottom: -10,
                  child: Icon(
                    icon,
                    size: 80,
                    color: color.withValues(alpha: 0.04),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (badgeIcon != null) ...[
                                  Icon(badgeIcon, size: 12, color: color),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  icon,
                  size: 76,
                  color: color.withValues(alpha: 0.04),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badgeIcon != null) ...[
                          Icon(badgeIcon, size: 12, color: color),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickIconButton(
          icon: Icons.business_rounded,
          label: 'Pengajuan',
          color: const Color(0xFF2563EB),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
            );
          },
        ),
        _QuickIconButton(
          icon: Icons.directions_car_rounded,
          label: 'Kendaraan',
          color: const Color(0xFF059669),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KendaraanScreen()),
            );
          },
        ),
        _QuickIconButton(
          icon: Icons.inventory_2_rounded,
          label: 'Inventaris',
          color: const Color(0xFFEA580C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => AsetScreen(onBack: () => Navigator.pop(ctx)),
              ),
            );
          },
        ),
        _QuickIconButton(
          icon: Icons.warning_rounded,
          label: 'Laporan',
          color: const Color(0xFFEF4444),
          onTap: () {
            NavigationService.goToTabUser?.call(4);
          },
        ),
      ],
    );
  }
}

class _QuickIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85), // Transparan
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9).withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
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