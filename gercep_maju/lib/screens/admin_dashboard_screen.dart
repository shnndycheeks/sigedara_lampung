import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'notifikasi_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
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
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF5C4000)],
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
                                color: AppColors.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.gold,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: AppColors.gold,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Panel Admin',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'GerCep Maju — Biro Umum',
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selamat datang, Admin!',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? const _SkeletonDashboard()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat cards row 1
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.pending_actions,
                                label: 'Menunggu\nPersetujuan',
                                value: '5',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Disetujui\nBulan Ini',
                                value: '18',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.directions_car_outlined,
                                label: 'Total\nKendaraan',
                                value: '12',
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Total\nAset Aktif',
                                value: '47',
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Pending approvals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Menunggu Persetujuan',
                              style: AppTextStyles.h3,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '5 pending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._pendingItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PendingTile(data: item),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick actions
                        const Text('Aksi Cepat', style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.add_business,
                                label: 'Tambah\nKendaraan',
                                color: AppColors.info,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.add_box_outlined,
                                label: 'Tambah\nAset',
                                color: AppColors.primary,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.bar_chart,
                                label: 'Laporan',
                                color: AppColors.success,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.group_outlined,
                                label: 'Pengguna',
                                color: AppColors.gold,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Activity log
                        const Text(
                          'Aktivitas Terbaru',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 12),
                        ..._activityLog.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActivityTile(data: item),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _pendingItems = [
    {
      'nama': 'Drs. Budi Santoso',
      'jenis': 'Gedung Serba Guna',
      'tgl': '10 Apr 2026',
      'type': 'gedung',
    },
    {
      'nama': 'Hj. Ratna Wulandari',
      'jenis': 'Toyota Innova — B 1234 XY',
      'tgl': '11 Apr 2026',
      'type': 'kendaraan',
    },
    {
      'nama': 'M. Rizal, S.Kom',
      'jenis': 'Ruang Rapat Lt. 2',
      'tgl': '12 Apr 2026',
      'type': 'gedung',
    },
  ];

  final List<Map<String, dynamic>> _activityLog = [
    {
      'action': 'Peminjaman Disetujui',
      'detail': 'Aula Utama — Siti Rahayu',
      'time': '2 jam lalu',
      'icon': Icons.check_circle,
      'color': AppColors.success,
    },
    {
      'action': 'Kendaraan Ditambahkan',
      'detail': 'Mitsubishi Pajero — BE 5678 ZZ',
      'time': '5 jam lalu',
      'icon': Icons.directions_car,
      'color': AppColors.info,
    },
    {
      'action': 'Peminjaman Ditolak',
      'detail': 'Ruang Pertemuan — Agus Salim',
      'time': 'Kemarin',
      'icon': Icons.cancel,
      'color': AppColors.error,
    },
    {
      'action': 'Aset Diperbarui',
      'detail': 'Laptop Dell XPS — SN-20241',
      'time': 'Kemarin',
      'icon': Icons.edit,
      'color': AppColors.warning,
    },
  ];
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Tile ──────────────────────────────────────────────────────────────
class _PendingTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PendingTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isGedung = data['type'] == 'gedung';
    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGedung ? Icons.business : Icons.directions_car,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nama'] as String,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data['jenis'] as String,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(data['tgl'] as String, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _ActionBtn(
                icon: Icons.check,
                color: AppColors.success,
                onTap: () {},
              ),
              const SizedBox(height: 6),
              _ActionBtn(
                icon: Icons.close,
                color: AppColors.error,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Tile ─────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data['color'] as Color;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(data['icon'] as IconData, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['action'] as String, style: AppTextStyles.h4),
              Text(data['detail'] as String, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text(data['time'] as String, style: AppTextStyles.caption),
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class _SkeletonDashboard extends StatelessWidget {
  const _SkeletonDashboard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
