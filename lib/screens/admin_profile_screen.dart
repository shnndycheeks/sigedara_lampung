import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import 'notifikasi_screen.dart';
import 'pengaturan_screen.dart';
import 'role_selector_screen.dart';
import 'admin_pegawai_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _notifPersetujuan = true;
  bool _notifAset = true;
  bool _notifSistem = true;
  bool _biometrik = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AdminColors.primary,
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AdminColors.primaryDark, const Color(0xFF854D0E)],
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
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: AppColors.gold,
                              size: 38,
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
                        'Admin Sistem',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'ADMINISTRATOR',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Biro Umum Setda Prov. Lampung',
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NeuCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.person_outline,
                          label: 'Username',
                          value: 'admin',
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                        _ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: 'admin@biroumumlampung.go.id',
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                        _ProfileInfoRow(
                          icon: Icons.business_outlined,
                          label: 'Unit',
                          value: 'Biro Umum Setda',
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                        _ProfileInfoRow(
                          icon: Icons.access_time,
                          label: 'Login Terakhir',
                          value: '08 Apr 2026 • 08:45',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Notifikasi', style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  NeuCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _SwitchRow(
                          label: 'Persetujuan Baru',
                          subtitle: 'Notif saat ada permintaan masuk',
                          value: _notifPersetujuan,
                          onChanged: (v) =>
                              setState(() => _notifPersetujuan = v),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _SwitchRow(
                          label: 'Laporan Aset',
                          subtitle: 'Notif aset bermasalah atau jatuh tempo',
                          value: _notifAset,
                          onChanged: (v) => setState(() => _notifAset = v),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _SwitchRow(
                          label: 'Notifikasi Sistem',
                          subtitle: 'Update & maintenance sistem',
                          value: _notifSistem,
                          onChanged: (v) => setState(() => _notifSistem = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Keamanan', style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  NeuCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _SwitchRow(
                          label: 'Autentikasi Biometrik',
                          subtitle: 'Gunakan sidik jari untuk login',
                          value: _biometrik,
                          onChanged: (v) => setState(() => _biometrik = v),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuRow(
                          icon: Icons.lock_reset,
                          label: 'Ganti Password',
                          onTap: () => _showChangePasswordDialog(context),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuRow(
                          icon: Icons.history,
                          label: 'Riwayat Login',
                          onTap: () => _showLoginHistoryDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Manajemen', style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  NeuCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _MenuRow(
                          icon: Icons.group_outlined,
                          label: 'Kelola Pegawai',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPegawaiScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuRow(
                          icon: Icons.backup_outlined,
                          label: 'Backup Data',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Backup berhasil dijadwalkan'),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _MenuRow(
                          icon: Icons.info_outline,
                          label: 'Versi Aplikasi',
                          trailing: const Text(
                            'v1.0.0',
                            style: AppTextStyles.caption,
                          ),
                          onTap: () => _showAboutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Riwayat Login', style: AppTextStyles.h3),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Hari ini, 08:30 — Android (emulator)'),
              SizedBox(height: 6),
              Text('• Kemarin, 17:45 — Android'),
              SizedBox(height: 6),
              Text('• 2 hari lalu, 09:12 — Android'),
            ],
          ),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tentang Aplikasi', style: AppTextStyles.h3),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, size: 48, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'SIGEDARA LAMPUNG',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text('Versi 1.0.0', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Sistem Manajemen Aset & Peminjaman\nKantor Biro Umum',
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

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Password', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PassField(label: 'Password Lama', controller: oldCtrl),
            const SizedBox(height: 12),
            _PassField(label: 'Password Baru', controller: newCtrl),
            const SizedBox(height: 12),
            _PassField(
              label: 'Konfirmasi Password Baru',
              controller: confirmCtrl,
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar', style: AppTextStyles.h3),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari panel admin?',
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
          ElevatedButton(
            onPressed: () {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.h4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _PassField({required this.label, required this.controller});

  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}