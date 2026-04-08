import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({super.key});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _filterIndex = 0;

  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Peminjaman Gedung'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
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
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KalenderGedungScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Daftar Permintaan'),
            Tab(text: 'Ajukan Pinjam'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildListTab(), _buildFormTab()],
      ),
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        // Filter chips
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
                    horizontal: 16,
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
                    boxShadow: _filterIndex == i
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
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
            itemCount: _peminjamanData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PeminjamanTile(data: _peminjamanData[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFormTab() {
    return const _FormPinjamanGedung();
  }

  final List<Map<String, dynamic>> _peminjamanData = [
    {
      'ruangan': 'Aula Utama',
      'peminjam': 'Drs. Ahmad Fauzi, M.Si',
      'tujuan': 'Rapat Koordinasi Teknis',
      'tanggal': 'Senin, 8 April 2026',
      'waktu': '09.00 – 12.00 WIB',
      'peserta': 45,
      'status': 'Menunggu',
      'statusColor': AppColors.warning,
    },
    {
      'ruangan': 'Ruang Rapat B',
      'peminjam': 'Ir. Siti Nurhaliza',
      'tujuan': 'Presentasi Laporan Keuangan',
      'tanggal': 'Selasa, 9 April 2026',
      'waktu': '13.00 – 15.00 WIB',
      'peserta': 20,
      'status': 'Disetujui',
      'statusColor': AppColors.success,
    },
    {
      'ruangan': 'Ruang Rapat A',
      'peminjam': 'Budi Santoso, S.H.',
      'tujuan': 'Konsultasi Hukum Internal',
      'tanggal': 'Rabu, 10 April 2026',
      'waktu': '10.00 – 11.30 WIB',
      'peserta': 10,
      'status': 'Disetujui',
      'statusColor': AppColors.success,
    },
    {
      'ruangan': 'Ruang Serbaguna',
      'peminjam': 'Henny Marlina, M.Pd',
      'tujuan': 'Pelatihan SDM',
      'tanggal': 'Kamis, 11 April 2026',
      'waktu': '08.00 – 17.00 WIB',
      'peserta': 60,
      'status': 'Ditolak',
      'statusColor': AppColors.error,
    },
    {
      'ruangan': 'Aula Utama',
      'peminjam': 'Dinas Kesehatan',
      'tujuan': 'Sosialisasi Kesehatan Masyarakat',
      'tanggal': 'Jumat, 12 April 2026',
      'waktu': '09.00 – 13.00 WIB',
      'peserta': 80,
      'status': 'Menunggu',
      'statusColor': AppColors.warning,
    },
  ];
}

class _PeminjamanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PeminjamanTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPeminjamanScreen(data: data)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['ruangan'] as String, style: AppTextStyles.h4),
                    Text(
                      data['peminjam'] as String,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: data['status'] as String,
                color: data['statusColor'] as Color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text(
            data['tujuan'] as String,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: data['tanggal'] as String,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.access_time,
                label: data['waktu'] as String,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoChip(
            icon: Icons.people_outline,
            label: '${data['peserta']} peserta',
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _FormPinjamanGedung extends StatefulWidget {
  const _FormPinjamanGedung();

  @override
  State<_FormPinjamanGedung> createState() => _FormPinjamanGedungState();
}

class _FormPinjamanGedungState extends State<_FormPinjamanGedung> {
  String? _selectedRuangan;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _pesertaCtrl = TextEditingController();
  final _tujuanCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  bool _loading = false;

  final List<String> _ruanganList = [
    'Aula Utama',
    'Ruang Rapat A',
    'Ruang Rapat B',
    'Ruang Serbaguna',
    'Ruang Vip Gubernur',
  ];

  @override
  void dispose() {
    _pesertaCtrl.dispose();
    _tujuanCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Form Pengajuan Peminjaman',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _FormLabel('Pilih Ruangan *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedRuangan,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.meeting_room_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  hint: Text(
                    'Pilih ruangan yang tersedia',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                  items: _ruanganList
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: AppTextStyles.body),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRuangan = v),
                ),
                const SizedBox(height: 16),

                _FormLabel('Tanggal Kegiatan *'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Pilih tanggal kegiatan',
                          style: _selectedDate != null
                              ? AppTextStyles.body
                              : AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel('Jam Mulai *'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 8,
                                  minute: 0,
                                ),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (t != null) setState(() => _startTime = t);
                            },
                            child: _TimeField(time: _startTime),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel('Jam Selesai *'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 10,
                                  minute: 0,
                                ),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (t != null) setState(() => _endTime = t);
                            },
                            child: _TimeField(time: _endTime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _FormLabel('Jumlah Peserta *'),
                const SizedBox(height: 6),
                AppTextField(
                  hint: 'Masukkan jumlah peserta',
                  prefixIcon: Icons.people_outline,
                  controller: _pesertaCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                _FormLabel('Tujuan / Nama Kegiatan *'),
                const SizedBox(height: 6),
                AppTextField(
                  hint: 'Tulis tujuan penggunaan ruangan',
                  prefixIcon: Icons.description_outlined,
                  controller: _tujuanCtrl,
                ),
                const SizedBox(height: 16),

                _FormLabel('Keterangan Tambahan'),
                const SizedBox(height: 6),
                TextField(
                  controller: _keteranganCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Keterangan tambahan (opsional)...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Ajukan Permintaan',
                    icon: Icons.send_outlined,
                    isLoading: _loading,
                    onPressed: () async {
                      setState(() => _loading = true);
                      await Future.delayed(const Duration(milliseconds: 1500));
                      if (mounted) {
                        setState(() => _loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Permintaan berhasil diajukan!',
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
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
  );
}

class _TimeField extends StatelessWidget {
  final TimeOfDay? time;
  const _TimeField({this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            time != null
                ? '${time!.hour.toString().padLeft(2, '0')}.${time!.minute.toString().padLeft(2, '0')}'
                : 'Pilih jam',
            style: time != null
                ? AppTextStyles.body.copyWith(fontSize: 13)
                : AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Detail Peminjaman Screen ---
class DetailPeminjamanScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailPeminjamanScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = data['statusColor'] as Color;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Peminjaman'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data['status'] == 'Disetujui'
                          ? Icons.check_circle_rounded
                          : data['status'] == 'Ditolak'
                          ? Icons.cancel_rounded
                          : Icons.pending_rounded,
                      color: statusColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nomor: PMJ-2026-0${DateTime.now().millisecond % 99 + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Peminjaman', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Ruangan',
                    value: data['ruangan'] as String,
                    icon: Icons.meeting_room_outlined,
                  ),
                  _DetailRow(
                    label: 'Peminjam',
                    value: data['peminjam'] as String,
                    icon: Icons.person_outline,
                  ),
                  _DetailRow(
                    label: 'Tujuan',
                    value: data['tujuan'] as String,
                    icon: Icons.description_outlined,
                  ),
                  _DetailRow(
                    label: 'Tanggal',
                    value: data['tanggal'] as String,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _DetailRow(
                    label: 'Waktu',
                    value: data['waktu'] as String,
                    icon: Icons.access_time,
                  ),
                  _DetailRow(
                    label: 'Peserta',
                    value: '${data['peserta']} orang',
                    icon: Icons.people_outline,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline approval
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riwayat Persetujuan', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _ApprovalStep(
                    label: 'Diajukan',
                    time: '07 Apr 2026 08:30',
                    done: true,
                    isFirst: true,
                  ),
                  _ApprovalStep(
                    label: 'Diterima Staf Rumah Tangga',
                    time: '07 Apr 2026 09:15',
                    done: data['status'] != 'Menunggu',
                  ),
                  _ApprovalStep(
                    label: 'Disetujui Kepala Biro',
                    time: data['status'] == 'Disetujui'
                        ? '07 Apr 2026 10:00'
                        : '—',
                    done: data['status'] == 'Disetujui',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (data['status'] == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Cabut Permintaan',
                      onPressed: () => Navigator.pop(context),
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: 'Edit',
                      icon: Icons.edit,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isLast;
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
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
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  final String label, time;
  final bool done;
  final bool isFirst;
  final bool isLast;
  const _ApprovalStep({
    required this.label,
    required this.time,
    required this.done,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: done ? AppColors.success : AppColors.divider,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: done
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 12),
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: done
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.h4.copyWith(
                  color: done ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
              Text(time, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Kalender Gedung Screen ---
class KalenderGedungScreen extends StatefulWidget {
  const KalenderGedungScreen({super.key});

  @override
  State<KalenderGedungScreen> createState() => _KalenderGedungScreenState();
}

class _KalenderGedungScreenState extends State<KalenderGedungScreen> {
  DateTime _month = DateTime(2026, 4);
  String _selectedRoom = 'Aula Utama';
  final List<String> _rooms = [
    'Aula Utama',
    'Ruang Rapat A',
    'Ruang Rapat B',
    'Ruang Serbaguna',
  ];

  // Mock booked dates
  final Map<String, List<int>> _booked = {
    'Aula Utama': [8, 9, 12, 15, 16, 21, 22],
    'Ruang Rapat A': [7, 8, 10, 14, 17, 23],
    'Ruang Rapat B': [9, 11, 13, 18, 19, 24, 25],
    'Ruang Serbaguna': [8, 12, 16, 20, 26, 27, 28],
  };

  @override
  Widget build(BuildContext context) {
    final booked = _booked[_selectedRoom] ?? [];
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ketersediaan Ruangan'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room selector
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _rooms[i] == _selectedRoom;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoom = _rooms[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _rooms[i],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            NeuCard(
              child: Column(
                children: [
                  // Month nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        ),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_monthName(_month.month)} ${_month.year}',
                        style: AppTextStyles.h3,
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month + 1),
                        ),
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Day headers
                  Row(
                    children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                    itemCount: daysInMonth + startWeekday,
                    itemBuilder: (_, i) {
                      if (i < startWeekday) return const SizedBox();
                      final day = i - startWeekday + 1;
                      final isBooked = booked.contains(day);
                      final isToday =
                          DateTime.now().day == day &&
                          DateTime.now().month == _month.month &&
                          DateTime.now().year == _month.year;
                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isBooked
                              ? AppColors.success.withValues(alpha: 0.85)
                              : isToday
                              ? AppColors.primary
                              : AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: isBooked
                              ? null
                              : Border.all(
                                  color: AppColors.info.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBooked
                                  ? Colors.white
                                  : isToday
                                  ? Colors.white
                                  : AppColors.info,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: AppColors.info.withValues(alpha: 0.15),
                        label: 'Tersedia',
                        textColor: AppColors.info,
                        borderColor: AppColors.info.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        color: AppColors.primary,
                        label: 'Hari ini',
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        color: AppColors.success.withValues(alpha: 0.85),
                        label: 'Sudah Diboking',
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
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
    return names[m];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  final Color? borderColor;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
