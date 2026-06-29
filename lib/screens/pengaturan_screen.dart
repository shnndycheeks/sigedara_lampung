import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  // Tampilan
  bool _darkMode = ThemeService.isDark.value;
  double _fontSize = 1.0; // 0.85 = kecil, 1.0 = normal, 1.15 = besar

  // Notifikasi
  bool _notifPeminjaman = NotificationService.notifPeminjaman.value;
  bool _notifPajak = NotificationService.notifPajak.value;
  bool _notifServis = NotificationService.notifServis.value;
  bool _notifEmail = false;
  String _waktuRingkasan = 'Setiap hari, 08:00';

  // Privasi & Keamanan
  bool _biometrik = true;
  bool _sembunyikanNIP = false;
  String _autoLogout = '30 menit';

  // Data & Penyimpanan
  bool _sinkronOtomatis = true;
  String _intervalSinkron = '15 menit';

  final List<String> _opsiAutoLogout = [
    '10 menit',
    '30 menit',
    '1 jam',
    'Tidak pernah',
  ];

  final List<String> _opsiIntervalSinkron = [
    '5 menit',
    '15 menit',
    '30 menit',
    '1 jam',
  ];

  final List<Map<String, String>> _waktuRingkasanList = [
    {'label': 'Setiap hari, 07:00', 'value': 'Setiap hari, 07:00'},
    {'label': 'Setiap hari, 08:00', 'value': 'Setiap hari, 08:00'},
    {'label': 'Setiap hari, 12:00', 'value': 'Setiap hari, 12:00'},
    {'label': 'Setiap hari, 17:00', 'value': 'Setiap hari, 17:00'},
    {'label': 'Nonaktif', 'value': 'Nonaktif'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetSemuaPengaturan,
            child: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── TAMPILAN ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Tampilan',
            color: AppColors.primary,
          ),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF4F46E5),
                title: 'Mode Gelap',
                subtitle: 'Ubah tema aplikasi menjadi gelap',
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  ThemeService.isDark.value = v;
                  _showSnackbar(
                    context,
                    'Mode Gelap ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                  );
                },
              ),
              const _Divider(),
              _SliderTile(
                icon: Icons.text_fields_rounded,
                iconColor: AppColors.info,
                title: 'Ukuran Teks',
                subtitle: _fontSizeLabel(_fontSize),
                value: _fontSize,
                min: 0.85,
                max: 1.15,
                divisions: 2,
                onChanged: (v) => setState(() => _fontSize = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── NOTIFIKASI ────────────────────────────────────
          _SectionHeader(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            color: AppColors.warning,
          ),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.business_center_outlined,
                iconColor: AppColors.primary,
                title: 'Notifikasi Peminjaman',
                subtitle: 'Status pengajuan dan persetujuan',
                value: _notifPeminjaman,
                onChanged: (v) {
                  setState(() => _notifPeminjaman = v);
                  NotificationService.notifPeminjaman.value = v;
                  _showSnackbar(
                    context,
                    'Notifikasi Peminjaman ${v ? 'aktif' : 'nonaktif'}',
                  );
                },
              ),
              const _Divider(),
              _SwitchTile(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.warning,
                title: 'Pengingat Pajak Kendaraan',
                subtitle: 'Notif H-30 sebelum jatuh tempo',
                value: _notifPajak,
                onChanged: (v) {
                  setState(() => _notifPajak = v);
                  NotificationService.notifPajak.value = v;
                  _showSnackbar(
                    context,
                    'Pengingat Pajak ${v ? 'aktif' : 'nonaktif'}',
                  );
                },
              ),
              const _Divider(),
              _SwitchTile(
                icon: Icons.build_outlined,
                iconColor: AppColors.info,
                title: 'Pengingat Jadwal Servis',
                subtitle: 'Notif saat kendaraan mendekati jadwal servis',
                value: _notifServis,
                onChanged: (v) {
                  setState(() => _notifServis = v);
                  NotificationService.notifServis.value = v;
                  _showSnackbar(
                    context,
                    'Pengingat Servis ${v ? 'aktif' : 'nonaktif'}',
                  );
                },
              ),
              const _Divider(),
              _SwitchTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Notifikasi via Email',
                subtitle: 'Kirim ringkasan ke email terdaftar',
                value: _notifEmail,
                onChanged: (v) {
                  setState(() => _notifEmail = v);
                  _showSnackbar(
                    context,
                    'Notifikasi Email ${v ? 'aktif' : 'nonaktif'}',
                  );
                },
              ),
              const _Divider(),
              _DropdownTile(
                icon: Icons.schedule_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Waktu Ringkasan Harian',
                value: _waktuRingkasan,
                items: _waktuRingkasanList.map((e) => e['value']!).toList(),
                labels: _waktuRingkasanList.map((e) => e['label']!).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _waktuRingkasan = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── PRIVASI & KEAMANAN ────────────────────────────
          _SectionHeader(
            icon: Icons.security_outlined,
            title: 'Privasi & Keamanan',
            color: const Color(0xFF7C3AED),
          ),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.fingerprint,
                iconColor: const Color(0xFF7C3AED),
                title: 'Login Biometrik',
                subtitle: 'Gunakan sidik jari untuk masuk aplikasi',
                value: _biometrik,
                onChanged: (v) {
                  setState(() => _biometrik = v);
                  _showSnackbar(
                    context,
                    'Login Biometrik ${v ? 'diaktifkan' : 'dinonaktifkan'}',
                  );
                },
              ),
              const _Divider(),
              _SwitchTile(
                icon: Icons.visibility_off_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Sembunyikan NIP',
                subtitle: 'Tampilkan sebagian NIP di profil',
                value: _sembunyikanNIP,
                onChanged: (v) => setState(() => _sembunyikanNIP = v),
              ),
              const _Divider(),
              _DropdownTile(
                icon: Icons.timer_off_outlined,
                iconColor: AppColors.error,
                title: 'Auto Logout',
                value: _autoLogout,
                items: _opsiAutoLogout,
                labels: _opsiAutoLogout,
                onChanged: (v) {
                  if (v != null) setState(() => _autoLogout = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── DATA & PENYIMPANAN ────────────────────────────
          _SectionHeader(
            icon: Icons.storage_outlined,
            title: 'Data & Penyimpanan',
            color: const Color(0xFF059669),
          ),
          _SettingCard(
            children: [
              _SwitchTile(
                icon: Icons.sync_outlined,
                iconColor: const Color(0xFF059669),
                title: 'Sinkronisasi Otomatis',
                subtitle: 'Perbarui data secara berkala di latar belakang',
                value: _sinkronOtomatis,
                onChanged: (v) => setState(() => _sinkronOtomatis = v),
              ),
              if (_sinkronOtomatis) ...[
                const _Divider(),
                _DropdownTile(
                  icon: Icons.update_outlined,
                  iconColor: AppColors.info,
                  title: 'Interval Sinkronisasi',
                  value: _intervalSinkron,
                  items: _opsiIntervalSinkron,
                  labels: _opsiIntervalSinkron,
                  onChanged: (v) {
                    if (v != null) setState(() => _intervalSinkron = v);
                  },
                ),
              ],
              const _Divider(),
              _ActionTile(
                icon: Icons.cleaning_services_outlined,
                iconColor: AppColors.warning,
                title: 'Hapus Cache',
                subtitle: 'Bersihkan data sementara aplikasi',
                trailing: const Text(
                  '12,4 MB',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () => _showHapusCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── BAHASA ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.language_outlined,
            title: 'Bahasa & Regional',
            color: AppColors.info,
          ),
          _SettingCard(
            children: [
              _ActionTile(
                icon: Icons.flag_outlined,
                iconColor: const Color(0xFFDC2626),
                title: 'Bahasa Aplikasi',
                subtitle: 'Bahasa Indonesia',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ID',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ],
                ),
                onTap: () => _showTidakTersedia(context, 'Ganti Bahasa'),
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.info,
                title: 'Format Tanggal',
                subtitle: 'dd MMMM yyyy (contoh: 13 April 2026)',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onTap: () => _showTidakTersedia(context, 'Format Tanggal'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── TENTANG ───────────────────────────────────────
          _SectionHeader(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            color: AppColors.textSecondary,
          ),
          _SettingCard(
            children: [
              _ActionTile(
                icon: Icons.new_releases_outlined,
                iconColor: AppColors.primary,
                title: 'Versi Aplikasi',
                subtitle: 'SIGEDARA LAMPUNG v1.0.0',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Terbaru',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () {},
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.article_outlined,
                iconColor: AppColors.info,
                title: 'Kebijakan Privasi',
                subtitle: 'Pelajari cara kami melindungi data Anda',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onTap: () => _showPrivacyPolicy(context),
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.gavel_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Syarat & Ketentuan',
                subtitle: 'Ketentuan penggunaan aplikasi',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onTap: () => _showTerms(context),
              ),
              const _Divider(),
              _ActionTile(
                icon: Icons.support_agent_outlined,
                iconColor: const Color(0xFF059669),
                title: 'Hubungi Dukungan',
                subtitle: 'helpdesk@biroumumlampung.go.id',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onTap: () => _showKontakDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'SIGEDARA LAMPUNG v1.0.0\nBiro Umum Setda Provinsi Lampung\n© 2026',
            style: AppTextStyles.caption.copyWith(height: 1.8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fontSizeLabel(double v) {
    if (v <= 0.85) return 'Kecil';
    if (v >= 1.15) return 'Besar';
    return 'Normal';
  }

  void _showSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showTidakTersedia(BuildContext context, String fitur) {
    _showSnackbar(context, '$fitur belum tersedia');
  }

  void _resetSemuaPengaturan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Pengaturan', style: AppTextStyles.h3),
        content: const Text(
          'Semua pengaturan akan dikembalikan ke nilai awal. Tindakan ini tidak dapat dibatalkan.',
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
              Navigator.pop(context);
              setState(() {
                _darkMode = false;
                _fontSize = 1.0;
                _notifPeminjaman = true;
                _notifPajak = true;
                _notifServis = false;
                _notifEmail = false;
                _waktuRingkasan = 'Setiap hari, 08:00';
                _biometrik = true;
                _sembunyikanNIP = false;
                _autoLogout = '30 menit';
                _sinkronOtomatis = true;
                _intervalSinkron = '15 menit';
              });
              ThemeService.isDark.value = false;
              NotificationService.notifPeminjaman.value = true;
              NotificationService.notifPajak.value = true;
              NotificationService.notifServis.value = false;
              _showSnackbar(context, 'Pengaturan berhasil direset');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHapusCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Cache', style: AppTextStyles.h3),
        content: const Text(
          'Data sementara (12,4 MB) akan dihapus. Aplikasi mungkin sedikit lebih lambat saat pertama kali digunakan kembali.',
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
              Navigator.pop(context);
              _showSnackbar(context, 'Cache berhasil dihapus');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kebijakan Privasi', style: AppTextStyles.h3),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aplikasi SIGEDARA LAMPUNG mengumpulkan data yang diperlukan untuk pengelolaan aset dan layanan internal Biro Umum Setda Provinsi Lampung.',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 10),
              Text('Data yang dikumpulkan:', style: AppTextStyles.h4),
              SizedBox(height: 6),
              Text(
                '• Identitas pengguna (nama, NIP, jabatan)\n'
                '• Riwayat peminjaman aset dan kendaraan\n'
                '• Log aktivitas dalam sistem\n'
                '• Preferensi notifikasi',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 10),
              Text(
                'Data hanya digunakan untuk keperluan operasional internal dan tidak dibagikan kepada pihak ketiga.',
                style: AppTextStyles.bodySmall,
              ),
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

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Syarat & Ketentuan', style: AppTextStyles.h3),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Penggunaan Akun', style: AppTextStyles.h4),
              SizedBox(height: 4),
              Text(
                'Akun hanya boleh digunakan oleh pemilik yang terdaftar. Dilarang meminjamkan atau menyebarkan kredensial login kepada pihak lain.',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 10),
              Text('2. Peminjaman Aset', style: AppTextStyles.h4),
              SizedBox(height: 4),
              Text(
                'Pengguna bertanggung jawab penuh atas aset yang dipinjam hingga dikembalikan dalam kondisi baik.',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 10),
              Text('3. Etika Penggunaan', style: AppTextStyles.h4),
              SizedBox(height: 4),
              Text(
                'Dilarang menyalahgunakan fasilitas aset negara untuk kepentingan pribadi di luar tugas kedinasan.',
                style: AppTextStyles.bodySmall,
              ),
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

  void _showKontakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hubungi Dukungan', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KontakItem(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'helpdesk@biroumumlampung.go.id',
            ),
            const SizedBox(height: 12),
            _KontakItem(
              icon: Icons.phone_outlined,
              label: 'Telepon',
              value: '(0721) 482–020',
            ),
            const SizedBox(height: 12),
            _KontakItem(
              icon: Icons.access_time_outlined,
              label: 'Jam Layanan',
              value: 'Senin – Jumat, 08.00 – 16.00 WIB',
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
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.h4.copyWith(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
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
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(fontSize: 14)),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _SliderTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            label: subtitle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> items;
  final List<String> labels;
  final ValueChanged<String?> onChanged;
  const _DropdownTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              icon: const Icon(
                Icons.expand_more,
                color: AppColors.textHint,
                size: 18,
              ),
              borderRadius: BorderRadius.circular(12),
              items: List.generate(
                items.length,
                (i) =>
                    DropdownMenuItem(value: items[i], child: Text(labels[i])),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontSize: 14)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}

class _KontakItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _KontakItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            Text(value, style: AppTextStyles.body.copyWith(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
