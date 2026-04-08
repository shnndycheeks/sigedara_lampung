import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text(
              'Baca Semua',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NotifTile(data: _notifData[i]),
      ),
    );
  }

  final List<Map<String, dynamic>> _notifData = [
    {
      'title': 'Permintaan Peminjaman Disetujui',
      'body':
          'Peminjaman Ruang Rapat B oleh Ir. Siti Nurhaliza telah disetujui oleh Kepala Biro.',
      'time': '10 menit lalu',
      'icon': Icons.check_circle_rounded,
      'color': AppColors.success,
      'read': false,
    },
    {
      'title': 'Pengingat Pajak Kendaraan',
      'body':
          'Pajak Toyota Innova (B 1234 XY) akan jatuh tempo dalam 8 hari. Segera proses perpanjangan.',
      'time': '1 jam lalu',
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.warning,
      'read': false,
    },
    {
      'title': 'Permintaan Baru Masuk',
      'body':
          'Henny Marlina mengajukan peminjaman Ruang Serbaguna untuk 11 April 2026.',
      'time': '2 jam lalu',
      'icon': Icons.business_center_outlined,
      'color': AppColors.primary,
      'read': false,
    },
    {
      'title': 'Kendaraan Dikembalikan',
      'body':
          'Honda CRV (B 5678 AB) telah dikembalikan oleh Bpk. Haryanto dari perjalanan ke Bandara.',
      'time': '3 jam lalu',
      'icon': Icons.directions_car,
      'color': AppColors.info,
      'read': true,
    },
    {
      'title': 'Servis Kendaraan Selesai',
      'body':
          'Toyota Innova (B 1234 XY) telah selesai diservis di Auto2000. Siap digunakan kembali.',
      'time': 'Kemarin',
      'icon': Icons.build_circle_rounded,
      'color': AppColors.success,
      'read': true,
    },
    {
      'title': 'Pengingat KIR Kendaraan',
      'body': 'Toyota Hiace (B 3456 CD) perlu perpanjangan KIR dalam 13 hari.',
      'time': 'Kemarin',
      'icon': Icons.verified_outlined,
      'color': AppColors.warning,
      'read': true,
    },
    {
      'title': 'Peminjaman Ditolak',
      'body':
          'Maaf, permintaan Ruang Serbaguna ditolak karena jadwal sudah terisi. Silakan pilih tanggal lain.',
      'time': '2 hari lalu',
      'icon': Icons.cancel_rounded,
      'color': AppColors.error,
      'read': true,
    },
  ];
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotifTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool read = data['read'] as bool;
    final Color color = data['color'] as Color;
    return Container(
      decoration: BoxDecoration(
        color: read ? AppColors.surface : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: read ? AppColors.divider : color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(data['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] as String,
                          style: AppTextStyles.h4.copyWith(
                            color: read
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['body'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: read
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['time'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: read ? AppColors.textHint : color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
