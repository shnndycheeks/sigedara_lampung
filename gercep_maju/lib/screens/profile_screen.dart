import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import 'notifikasi_screen.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifPeminjaman = true;
  bool _notifPajak = true;
  bool _notifServis = false;
  bool _biometrik = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                NavigationService.goHomeUser?.call();
              },
            ),
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
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold,
                                width: 3,
                              ),
                              color: AppColors.primaryLight,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Drs. Ahmad Fauzi, M.Si',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIP: 197203141998031002',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'Staf Divisi Rumah Tangga',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                        value: '24',
                        label: 'Peminjaman',
                        icon: Icons.business_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: '8',
                        label: 'Kendaraan',
                        icon: Icons.directions_car_outlined,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: '3',
                        label: 'Pending',
                        icon: Icons.pending_outlined,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info section
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informasi Akun', style: AppTextStyles.h3),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Jabatan',
                          value: 'Pengadministrasi Umum',
                        ),
                        _InfoRow(
                          icon: Icons.business_outlined,
                          label: 'Unit Kerja',
                          value: 'Biro Umum Setda',
                        ),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: 'ahmad.fauzi@lampungprov.go.id',
                        ),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'No. HP',
                          value: '08123456789',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notifications settings
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan Notifikasi',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 14),
                        _SwitchRow(
                          icon: Icons.business_outlined,
                          label: 'Notifikasi Peminjaman',
                          value: _notifPeminjaman,
                          color: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _notifPeminjaman = v),
                        ),
                        const Divider(height: 16, color: AppColors.divider),
                        _SwitchRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'Pengingat Pajak',
                          value: _notifPajak,
                          color: AppColors.warning,
                          onChanged: (v) => setState(() => _notifPajak = v),
                        ),
                        const Divider(height: 16, color: AppColors.divider),
                        _SwitchRow(
                          icon: Icons.build_outlined,
                          label: 'Pengingat Servis',
                          value: _notifServis,
                          color: AppColors.info,
                          onChanged: (v) => setState(() => _notifServis = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security settings
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keamanan & Tampilan',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 14),
                        _SwitchRow(
                          icon: Icons.fingerprint,
                          label: 'Login Biometrik',
                          value: _biometrik,
                          color: const Color(0xFF7C3AED),
                          onChanged: (v) => setState(() => _biometrik = v),
                        ),
                        const Divider(height: 16, color: AppColors.divider),
                        _SwitchRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Mode Gelap',
                          value: _darkMode,
                          color: AppColors.textPrimary,
                          onChanged: (v) => setState(() => _darkMode = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu items
                  NeuCard(
                    child: Column(
                      children: [
                        _MenuItem(
                          icon: Icons.lock_outline,
                          label: 'Ganti Password',
                          color: AppColors.primary,
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuItem(
                          icon: Icons.description_outlined,
                          label: 'Panduan Pengguna',
                          color: AppColors.info,
                          onTap: () {},
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuItem(
                          icon: Icons.info_outline,
                          label: 'Tentang Aplikasi',
                          color: AppColors.textSecondary,
                          onTap: () => _showAbout(context),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuItem(
                          icon: Icons.logout,
                          label: 'Keluar',
                          color: AppColors.error,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'GerCep Maju v1.0.0\nBiro Umum Setda Provinsi Lampung',
                    style: AppTextStyles.caption.copyWith(height: 1.8),
                    textAlign: TextAlign.center,
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

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tentang Aplikasi', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text('GerCep Maju', style: AppTextStyles.h3),
            const Text('Versi 1.0.0', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            const Text(
              'Sistem informasi manajemen aset dan layanan rumah tangga Biro Umum Setda Provinsi Lampung.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar', style: AppTextStyles.h3),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: AppTextStyles.bodySmall,
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;
  const _InfoRow({
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
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 14)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: color == AppColors.error
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
