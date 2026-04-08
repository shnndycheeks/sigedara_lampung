import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'peminjaman_screen.dart';
import 'kendaraan_screen.dart';
import 'aset_screen.dart';
import 'notifikasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      Color(0xFFE8C84F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GerCep Maju',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Divisi Rumah Tangga',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search
                            IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              onPressed: () => _showSearch(context),
                            ),
                            // Notif
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotifikasiScreen(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '3',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selamat Pagi, Ahmad 👋',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        Text(
                          'Senin, 7 April 2026',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
            automaticallyImplyLeading: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loading ? _buildSkeleton() : _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 120, height: 18),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: SkeletonBox(width: double.infinity, height: 100)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(width: double.infinity, height: 100)),
          ],
        ),
        const SizedBox(height: 12),
        const SkeletonBox(width: double.infinity, height: 100),
        const SizedBox(height: 24),
        const SkeletonBox(width: 150, height: 18),
        const SizedBox(height: 14),
        const SkeletonBox(width: double.infinity, height: 80),
        const SizedBox(height: 8),
        const SkeletonBox(width: double.infinity, height: 80),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats summary row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CC)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '7 permintaan menunggu persetujuan hari ini',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF92700A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader(title: 'Ringkasan Aktivitas'),
        const SizedBox(height: 12),

        // 3 main module cards
        Row(
          children: [
            Expanded(
              child: _ModuleCard(
                title: 'Peminjaman\nGedung',
                value: '5',
                sub: 'aktif',
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
              child: _ModuleCard(
                title: 'Kendaraan\nDinas',
                value: '12',
                sub: 'unit',
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
        _ModuleCardWide(
          title: 'Manajemen Aset',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFFD97706),
          items: const [
            '⚠ 3 kendaraan pajak jatuh tempo',
            '🔧 2 AC perlu servis rutin',
            '📋 Inventaris: 47 ruangan tercatat',
          ],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AsetScreen()),
          ),
        ),
        const SizedBox(height: 24),

        // Quick actions
        const SectionHeader(title: 'Aksi Cepat'),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.add_circle_outline,
              label: 'Ajukan\nPinjam',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
              ),
            ),
            _QuickAction(
              icon: Icons.car_rental,
              label: 'Pinjam\nKendaraan',
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KendaraanScreen()),
              ),
            ),
            _QuickAction(
              icon: Icons.report_problem_outlined,
              label: 'Laporan\nKerusakan',
              color: const Color(0xFFDC2626),
              onTap: () {},
            ),
            _QuickAction(
              icon: Icons.qr_code_scanner,
              label: 'Scan\nAset',
              color: const Color(0xFF7C3AED),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent activity
        SectionHeader(
          title: 'Aktivitas Terkini',
          actionLabel: 'Lihat Semua',
          onAction: () {},
        ),
        const SizedBox(height: 12),
        ..._recentActivities.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityTile(data: a),
          ),
        ),
        const SizedBox(height: 16),

        // Upcoming calendar reminder
        const SectionHeader(title: 'Pengingat Jadwal'),
        const SizedBox(height: 12),
        ..._reminders.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReminderTile(data: r),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _GlobalSearch());
  }

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'icon': Icons.business,
      'title': 'Peminjaman Ruang Rapat A',
      'sub': 'Diajukan oleh Budi S. • 2 jam lalu',
      'status': 'Menunggu',
      'color': AppColors.warning,
    },
    {
      'icon': Icons.directions_car,
      'title': 'Kendaraan B 1234 XY — Perjalanan Dinas',
      'sub': 'Dipinjam oleh Siti N. • 4 jam lalu',
      'status': 'Aktif',
      'color': AppColors.success,
    },
    {
      'icon': Icons.build,
      'title': 'Servis AC Ruang 203',
      'sub': 'Dijadwalkan • 8 April 2026',
      'status': 'Terjadwal',
      'color': AppColors.info,
    },
  ];

  final List<Map<String, dynamic>> _reminders = [
    {
      'icon': Icons.receipt_long,
      'title': 'Pajak Kendaraan — Toyota Innova',
      'date': '15 Apr 2026',
      'days': 8,
      'color': AppColors.warning,
    },
    {
      'icon': Icons.build_circle,
      'title': 'Servis Rutin — Honda CRV',
      'date': '20 Apr 2026',
      'days': 13,
      'color': AppColors.info,
    },
  ];
}

class _ModuleCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCardWide extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final VoidCallback onTap;
  const _ModuleCardWide({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4.copyWith(color: color)),
                  const SizedBox(height: 6),
                  ...items.map(
                    (s) => Text(
                      s,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: data['color'] as Color,
              size: 20,
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
                Text(data['sub'] as String, style: AppTextStyles.caption),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data['icon'] as IconData,
              color: data['color'] as Color,
              size: 20,
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
                  'Jatuh tempo: ${data['date']}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data['days']}h',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
    'Ruang Rapat A',
    'Ruang Rapat B',
    'Aula Utama',
    'Ruang Serbaguna',
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
    if (results.isEmpty)
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: 'Coba kata kunci lain',
      );
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
