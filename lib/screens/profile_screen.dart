import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'notifikasi_screen.dart';
import '../screens/pengaturan_screen.dart';
import '../screens/role_selector_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifPeminjaman = NotificationService.notifPeminjaman.value;
  bool _notifPajak = NotificationService.notifPajak.value;
  bool _notifServis = NotificationService.notifServis.value;
  bool _biometrik = true;
  bool _darkMode = ThemeService.isDark.value;

  bool _loading = true;
  String? _error;

  String _nama = 'Pegawai';
  String _nip = '-';
  String _jabatan = '-';
  String _unitKerja = 'Biro Umum Setda';
  String _email = '-';
  String _noHp = '-';

  int _totalPeminjaman = 0;
  int _totalKendaraan = 0;
  int _totalPending = 0;

  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _client.auth.currentUser;

      if (user == null) {
        throw Exception('User belum login');
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final peminjaman = await _client
          .from('peminjaman')
          .select('id, status, tipe_item')
          .eq('user_id', user.id);

      final nama = _safeText(
        profile?['nama'],
        fallback: user.userMetadata?['nama']?.toString() ?? 'Pegawai',
      );

      final nip = _safeText(profile?['nip'], fallback: '-');

      final jabatan = _safeText(
        profile?['jabatan'] ?? profile?['posisi'] ?? profile?['bagian'],
        fallback: '-',
      );

      final unitKerja = _safeText(
        profile?['unit_kerja'] ??
            profile?['unit'] ??
            profile?['dinas'] ??
            profile?['instansi'],
        fallback: 'Biro Umum Setda',
      );

      final email = _safeText(profile?['email'], fallback: user.email ?? '-');

      final noHp = _safeText(
        profile?['no_hp'] ??
            profile?['nomor_hp'] ??
            profile?['phone'] ??
            profile?['telepon'],
        fallback: '-',
      );

      final List<dynamic> listPeminjaman = peminjaman as List<dynamic>;

      final totalKendaraan = listPeminjaman.where((item) {
        final tipe = (item['tipe_item'] ?? '').toString().toLowerCase();
        return tipe == 'kendaraan';
      }).length;

      final totalPending = listPeminjaman.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return status == 'pending' || status == 'menunggu';
      }).length;

      if (!mounted) return;

      setState(() {
        _nama = nama;
        _nip = nip;
        _jabatan = jabatan;
        _unitKerja = unitKerja;
        _email = email;
        _noHp = noHp;

        _totalPeminjaman = listPeminjaman.length;
        _totalKendaraan = totalKendaraan;
        _totalPending = totalPending;

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

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _initialName(String name) {
    final clean = name.trim();

    if (clean.isEmpty || clean == '-') return 'P';

    return clean.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 212,
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
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
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
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 28),
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
                                    child: Center(
                                      child: Text(
                                        _initialName(_nama),
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  _nama,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'NIP: $_nip',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _jabatan,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
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
                child: _error != null
                    ? _ErrorProfileView(
                        message: _error!,
                        onRetry: _loadProfileData,
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              _StatCard(
                                value: _totalPeminjaman.toString(),
                                label: 'Peminjaman',
                                icon: Icons.business_outlined,
                                color: AppColors.primary,
                                onTap: () =>
                                    NavigationService.goToTabUser?.call(1),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                value: _totalKendaraan.toString(),
                                label: 'Kendaraan',
                                icon: Icons.directions_car_outlined,
                                color: const Color(0xFF059669),
                                onTap: () =>
                                    NavigationService.goToTabUser?.call(2),
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                value: _totalPending.toString(),
                                label: 'Pending',
                                icon: Icons.pending_outlined,
                                color: AppColors.warning,
                                onTap: () =>
                                    NavigationService.goToTabUser?.call(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informasi Akun',
                                  style: AppTextStyles.h3,
                                ),
                                const SizedBox(height: 14),
                                _InfoRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Jabatan',
                                  value: _jabatan,
                                ),
                                _InfoRow(
                                  icon: Icons.business_outlined,
                                  label: 'Unit Kerja',
                                  value: _unitKerja,
                                ),
                                _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: _email,
                                ),
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'No. HP',
                                  value: _noHp,
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                  onChanged: (v) {
                                    setState(() => _notifPeminjaman = v);
                                    NotificationService.notifPeminjaman.value =
                                        v;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Notifikasi Peminjaman ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(
                                  height: 16,
                                  color: AppColors.divider,
                                ),
                                _SwitchRow(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Pengingat Pajak',
                                  value: _notifPajak,
                                  color: AppColors.warning,
                                  onChanged: (v) {
                                    setState(() => _notifPajak = v);
                                    NotificationService.notifPajak.value = v;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Pengingat Pajak ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(
                                  height: 16,
                                  color: AppColors.divider,
                                ),
                                _SwitchRow(
                                  icon: Icons.build_outlined,
                                  label: 'Pengingat Servis',
                                  value: _notifServis,
                                  color: AppColors.info,
                                  onChanged: (v) {
                                    setState(() => _notifServis = v);
                                    NotificationService.notifServis.value = v;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Pengingat Servis ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                  onChanged: (v) =>
                                      setState(() => _biometrik = v),
                                ),
                                const Divider(
                                  height: 16,
                                  color: AppColors.divider,
                                ),
                                _SwitchRow(
                                  icon: Icons.dark_mode_outlined,
                                  label: 'Mode Gelap',
                                  value: _darkMode,
                                  color: AppColors.textPrimary,
                                  onChanged: (v) {
                                    setState(() => _darkMode = v);
                                    ThemeService.isDark.value = v;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Mode Gelap ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          NeuCard(
                            child: Column(
                              children: [
                                _MenuItem(
                                  icon: Icons.lock_outline,
                                  label: 'Ganti Password',
                                  color: AppColors.primary,
                                  onTap: () =>
                                      _showChangePasswordDialog(context),
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppColors.divider,
                                ),
                                _MenuItem(
                                  icon: Icons.description_outlined,
                                  label: 'Panduan Pengguna',
                                  color: AppColors.info,
                                  onTap: () => _showGuideDialog(context),
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppColors.divider,
                                ),
                                _MenuItem(
                                  icon: Icons.info_outline,
                                  label: 'Tentang Aplikasi',
                                  color: AppColors.textSecondary,
                                  onTap: () => _showAbout(context),
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppColors.divider,
                                ),
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
                            'SIGEDARA LAMPUNG v1.0.0\nBiro Umum Setda Provinsi Lampung',
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
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final oldPassword = oldCtrl.text.trim();
              final newPassword = newCtrl.text.trim();
              final confirmPassword = confirmCtrl.text.trim();

              if (oldPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua kolom wajib diisi')),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password baru minimal 6 karakter'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konfirmasi password tidak sama'),
                  ),
                );
                return;
              }

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPassword),
                );

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diperbarui')),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengganti password: $e')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Panduan Pengguna'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Dashboard — Lihat ringkasan aktivitas dan status peminjaman.',
              ),
              SizedBox(height: 8),
              Text('2. Pinjam — Ajukan dan kelola permintaan peminjaman aset.'),
              SizedBox(height: 8),
              Text(
                '3. Kendaraan — Lihat ketersediaan dan pesan kendaraan dinas.',
              ),
              SizedBox(height: 8),
              Text('4. Aset — Telusuri inventaris aset kantor.'),
              SizedBox(height: 8),
              Text('5. Laporan — Laporkan kerusakan aset atau inventaris.'),
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
            const Text('SIGEDARA LAMPUNG', style: AppTextStyles.h3),
            const Text('Versi 1.0.0', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            const Text(
              'Sistem Informasi Gedung dan Kendaraan Lampung untuk mendukung layanan peminjaman gedung dan kendaraan pada Biro Umum Setda Provinsi Lampung.',
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
            onPressed: () async {
              try {
                await AuthService.logout();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
                  (_) => false,
                );
              } catch (_) {}
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

class _ErrorProfileView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorProfileView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 10),
          const Text('Gagal memuat profil', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(12),
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
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
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
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
