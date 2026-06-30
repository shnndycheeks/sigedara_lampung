import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class PengingatScreen extends StatefulWidget {
  const PengingatScreen({super.key});

  @override
  State<PengingatScreen> createState() => _PengingatScreenState();
}

class _PengingatScreenState extends State<PengingatScreen> {
  int _filterIndex = 0;
  final List<String> _filters = ['Semua', 'Pajak', 'Servis', 'Kir'];

  @override
  Widget build(BuildContext context) {
    final bool standalone = ModalRoute.of(context)?.settings.name != null;
    Widget body = Column(
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
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _filterIndex == i
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterIndex == i
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
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
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _pengingatData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PengingatTile(
              data: _pengingatData[i],
              onUpload: () => _showUploadDialog(context, _pengingatData[i]),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pengingat Pajak & Servis',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (standalone) {
              Navigator.pop(context);
            } else {
              NavigationService.goHomeUser?.call();
            }
          },
        ),
      ),
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTambahPengingatDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text(
          'Tambah Pengingat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext ctx, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadBuktiSheet(data: data),
    );
  }

  void _showTambahPengingatDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormTambahPengingatSheet(),
    );
  }

  final List<Map<String, dynamic>> _pengingatData = [
    {
      'title': 'Pajak Kendaraan — Toyota Innova',
      'kode': 'B 1234 XY',
      'jenis': 'Pajak Tahunan',
      'deadline': '15 Apr 2026',
      'daysLeft': 8,
      'biaya': 'Rp 3.500.000',
      'status': 'Segera',
      'statusColor': AppColors.warning,
      'icon': Icons.receipt_long,
      'uploaded': false,
    },
    {
      'title': 'KIR Kendaraan — Toyota Hiace',
      'kode': 'B 3456 CD',
      'jenis': 'KIR/Uji Berkala',
      'deadline': '20 Apr 2026',
      'daysLeft': 13,
      'biaya': 'Rp 250.000',
      'status': 'Segera',
      'statusColor': AppColors.warning,
      'icon': Icons.verified_outlined,
      'uploaded': false,
    },
    {
      'title': 'Servis Rutin — Honda CRV',
      'kode': 'B 5678 AB',
      'jenis': 'Servis Berkala',
      'deadline': '25 Apr 2026',
      'daysLeft': 18,
      'biaya': 'Rp 1.800.000',
      'status': 'Perlu Perhatian',
      'statusColor': AppColors.info,
      'icon': Icons.build_circle_outlined,
      'uploaded': false,
    },
    {
      'title': 'Pajak Kendaraan — Mitsubishi Pajero',
      'kode': 'B 9999 ZZ',
      'jenis': 'Pajak Tahunan',
      'deadline': '30 Apr 2026',
      'daysLeft': 23,
      'biaya': 'Rp 5.200.000',
      'status': 'Perlu Perhatian',
      'statusColor': AppColors.info,
      'icon': Icons.receipt_long,
      'uploaded': false,
    },
    {
      'title': 'Servis Rutin — Daihatsu Xenia',
      'kode': 'BE 1111 AC',
      'jenis': 'Servis Berkala',
      'deadline': '5 Mei 2026',
      'daysLeft': 28,
      'biaya': 'Rp 900.000',
      'status': 'Normal',
      'statusColor': AppColors.success,
      'icon': Icons.build_circle_outlined,
      'uploaded': true,
    },
    {
      'title': 'Pajak Kendaraan — Toyota Land Cruiser',
      'kode': 'BE 8888 PJ',
      'jenis': 'Pajak Tahunan',
      'deadline': '10 Mei 2026',
      'daysLeft': 33,
      'biaya': 'Rp 8.100.000',
      'status': 'Normal',
      'statusColor': AppColors.success,
      'icon': Icons.receipt_long,
      'uploaded': true,
    },
  ];
}

class _PengingatTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onUpload;
  const _PengingatTile({required this.data, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = data['statusColor'] as Color;
    final int daysLeft = data['daysLeft'] as int;
    final bool uploaded = data['uploaded'] as bool;

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data['icon'] as IconData,
                  color: statusColor,
                  size: 22,
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
                    Text(
                      '${data['kode']} • ${data['jenis']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysLeft hr',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Jatuh tempo: ${data['deadline']}',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const Spacer(),
              const Icon(
                Icons.attach_money,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                data['biaya'] as String,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: uploaded
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: uploaded
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          uploaded
                              ? Icons.check_circle_outline
                              : Icons.upload_file_outlined,
                          size: 16,
                          color: uploaded
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          uploaded ? 'Bukti Terupload' : 'Upload Bukti',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: uploaded
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: data['status'] as String, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadBuktiSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const _UploadBuktiSheet({required this.data});

  @override
  State<_UploadBuktiSheet> createState() => _UploadBuktiSheetState();
}

class _UploadBuktiSheetState extends State<_UploadBuktiSheet> {
  bool _uploaded = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Upload Bukti Pembayaran', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(widget.data['title'] as String, style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),

          // Upload area
          GestureDetector(
            onTap: () => setState(() => _uploaded = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: _uploaded
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _uploaded ? AppColors.success : AppColors.divider,
                  width: _uploaded ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _uploaded
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: _uploaded ? AppColors.success : AppColors.textHint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploaded
                        ? 'File berhasil dipilih'
                        : 'Ketuk untuk pilih file',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _uploaded
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _uploaded
                        ? 'bukti_pajak_innova.pdf'
                        : 'PDF, JPG, atau PNG (maks. 5MB)',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppTextField(
            hint: 'Nomor referensi / kwitansi',
            prefixIcon: Icons.receipt_outlined,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Simpan Bukti',
              icon: Icons.save_outlined,
              isLoading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                await Future.delayed(const Duration(milliseconds: 1200));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Bukti pembayaran berhasil disimpan!',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTambahPengingatSheet extends StatelessWidget {
  const _FormTambahPengingatSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tambah Pengingat', style: AppTextStyles.h2),
          const SizedBox(height: 20),
          const AppTextField(
            hint: 'Nama pengingat',
            prefixIcon: Icons.alarm_outlined,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            hint: 'Kendaraan / aset terkait',
            prefixIcon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            hint: 'Tanggal jatuh tempo',
            prefixIcon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            hint: 'Estimasi biaya',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Tambah Pengingat',
              icon: Icons.add_alarm,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
