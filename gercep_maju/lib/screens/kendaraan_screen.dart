import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({super.key});

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kendaraan Dinas'),
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
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Fleet'),
            Tab(text: 'Pinjam'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildFleetTab(),
          const _FormPinjamKendaraan(),
          const _RiwayatKendaraan(),
        ],
      ),
    );
  }

  Widget _buildFleetTab() {
    final filtered = _kendaraanList
        .where(
          (k) =>
              _searchQuery.isEmpty ||
              (k['nama'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (k['plat'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Cari kendaraan / nomor plat...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'Kendaraan tidak ditemukan',
                  subtitle: 'Coba gunakan kata kunci lain',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _KendaraanTile(data: filtered[i]),
                ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _kendaraanList = [
    {
      'nama': 'Toyota Innova',
      'plat': 'B 1234 XY',
      'jenis': 'MPV',
      'status': 'Tersedia',
      'statusColor': AppColors.success,
      'bbm': 0.75,
      'servisDate': '20 Apr 2026',
      'warna': 'Putih',
      'tahun': '2022',
      'cc': '2000',
      'icon': Icons.directions_car,
    },
    {
      'nama': 'Honda CRV',
      'plat': 'B 5678 AB',
      'jenis': 'SUV',
      'status': 'Digunakan',
      'statusColor': AppColors.warning,
      'bbm': 0.45,
      'servisDate': '25 Apr 2026',
      'warna': 'Hitam',
      'tahun': '2021',
      'cc': '1500',
      'icon': Icons.directions_car,
    },
    {
      'nama': 'Mitsubishi Pajero',
      'plat': 'B 9999 ZZ',
      'jenis': 'SUV',
      'status': 'Tersedia',
      'statusColor': AppColors.success,
      'bbm': 0.90,
      'servisDate': '30 Apr 2026',
      'warna': 'Silver',
      'tahun': '2023',
      'cc': '2400',
      'icon': Icons.directions_car,
    },
    {
      'nama': 'Toyota Hiace',
      'plat': 'B 3456 CD',
      'jenis': 'Van',
      'status': 'Servis',
      'statusColor': AppColors.error,
      'bbm': 0.20,
      'servisDate': '10 Apr 2026',
      'warna': 'Putih',
      'tahun': '2020',
      'cc': '2700',
      'icon': Icons.airport_shuttle,
    },
    {
      'nama': 'Daihatsu Xenia',
      'plat': 'BE 1111 AC',
      'jenis': 'MPV',
      'status': 'Tersedia',
      'statusColor': AppColors.success,
      'bbm': 0.60,
      'servisDate': '15 Apr 2026',
      'warna': 'Merah',
      'tahun': '2021',
      'cc': '1300',
      'icon': Icons.directions_car,
    },
    {
      'nama': 'Toyota Land Cruiser',
      'plat': 'BE 8888 PJ',
      'jenis': 'SUV',
      'status': 'Tersedia',
      'statusColor': AppColors.success,
      'bbm': 0.85,
      'servisDate': '28 Apr 2026',
      'warna': 'Hitam',
      'tahun': '2023',
      'cc': '4000',
      'icon': Icons.directions_car,
    },
  ];
}

class _KendaraanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KendaraanTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final double bbm = data['bbm'] as double;
    final Color bbmColor = bbm > 0.5
        ? AppColors.success
        : bbm > 0.25
        ? AppColors.warning
        : AppColors.error;

    return NeuCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailKendaraanScreen(data: data)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data['icon'] as IconData,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'] as String, style: AppTextStyles.h4),
                    Text(
                      '${data['plat']} • ${data['jenis']}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(
                          label: data['status'] as String,
                          color: data['statusColor'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Servis: ${data['servisDate']}',
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.local_gas_station_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'BBM',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bbm,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(bbmColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(bbm * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: bbmColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DetailKendaraanScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailKendaraanScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double bbm = data['bbm'] as double;
    final Color bbmColor = bbm > 0.5
        ? AppColors.success
        : bbm > 0.25
        ? AppColors.warning
        : AppColors.error;
    final Color statusColor = data['statusColor'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(data['nama'] as String),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    data['icon'] as IconData,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['nama'] as String,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    data['plat'] as String,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusBadge(
                    label: data['status'] as String,
                    color: Colors.white,
                    bgColor: statusColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spesifikasi Kendaraan', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Jenis',
                    value: data['jenis'] as String,
                    icon: Icons.category_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Warna',
                    value: data['warna'] as String,
                    icon: Icons.palette_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Tahun',
                    value: data['tahun'] as String,
                    icon: Icons.calendar_today_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Mesin',
                    value: '${data['cc']} cc',
                    icon: Icons.settings_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Servis Berikut',
                    value: data['servisDate'] as String,
                    icon: Icons.build_outlined,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Level BBM', style: AppTextStyles.h3),
                      Text(
                        '${(bbm * 100).round()}%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: bbmColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: bbm,
                      minHeight: 14,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(bbmColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (data['status'] == 'Tersedia')
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Ajukan Peminjaman',
                  icon: Icons.car_rental,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _FormPinjamKendaraanPage(),
                      ),
                    );
                  },
                ),
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
    required this.isLast,
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
                width: 100,
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

class _FormPinjamKendaraan extends StatelessWidget {
  const _FormPinjamKendaraan();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: _FormPinjamKendaraanContent(),
    );
  }
}

class _FormPinjamKendaraanPage extends StatelessWidget {
  const _FormPinjamKendaraanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Form Peminjaman Kendaraan'),
        backgroundColor: AppColors.primary,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: _FormPinjamKendaraanContent(),
      ),
    );
  }
}

class _FormPinjamKendaraanContent extends StatefulWidget {
  const _FormPinjamKendaraanContent();

  @override
  State<_FormPinjamKendaraanContent> createState() =>
      _FormPinjamKendaraanContentState();
}

class _FormPinjamKendaraanContentState
    extends State<_FormPinjamKendaraanContent> {
  String? _selectedKendaraan;
  String? _selectedDriver;
  final _tujuanCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  DateTime? _tglBerangkat;
  DateTime? _tglKembali;
  bool _loading = false;

  final List<String> _kendaraanList = [
    'Toyota Innova - B 1234 XY',
    'Mitsubishi Pajero - B 9999 ZZ',
    'Daihatsu Xenia - BE 1111 AC',
    'Toyota Land Cruiser - BE 8888 PJ',
  ];
  final List<String> _driverList = [
    'Bpk. Sutrisno (Pengemudi)',
    'Bpk. Haryanto (Pengemudi)',
    'Bpk. Wahyu (Pengemudi)',
    'Mandiri (Sendiri)',
  ];

  @override
  void dispose() {
    _tujuanCtrl.dispose();
    _lokasiCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Form Peminjaman Kendaraan', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),

          _Label('Pilih Kendaraan *'),
          const SizedBox(height: 6),
          _DropdownField(
            value: _selectedKendaraan,
            items: _kendaraanList,
            hint: 'Pilih kendaraan tersedia',
            icon: Icons.directions_car_outlined,
            onChanged: (v) => setState(() => _selectedKendaraan = v),
          ),
          const SizedBox(height: 16),

          _Label('Pengemudi *'),
          const SizedBox(height: 6),
          _DropdownField(
            value: _selectedDriver,
            items: _driverList,
            hint: 'Pilih pengemudi / supir',
            icon: Icons.person_outline,
            onChanged: (v) => setState(() => _selectedDriver = v),
          ),
          const SizedBox(height: 16),

          _Label('Tujuan Perjalanan *'),
          const SizedBox(height: 6),
          AppTextField(
            hint: 'Tulis tujuan perjalanan dinas',
            prefixIcon: Icons.place_outlined,
            controller: _tujuanCtrl,
          ),
          const SizedBox(height: 16),

          _Label('Lokasi Tujuan *'),
          const SizedBox(height: 6),
          AppTextField(
            hint: 'Alamat / lokasi tujuan',
            prefixIcon: Icons.location_on_outlined,
            controller: _lokasiCtrl,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Tgl Berangkat *'),
                    const SizedBox(height: 6),
                    _DateField(
                      date: _tglBerangkat,
                      onPick: (d) => setState(() => _tglBerangkat = d),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Tgl Kembali'),
                    const SizedBox(height: 6),
                    _DateField(
                      date: _tglKembali,
                      onPick: (d) => setState(() => _tglKembali = d),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _Label('Keterangan Tambahan'),
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
              label: 'Ajukan Peminjaman Kendaraan',
              icon: Icons.send_outlined,
              isLoading: _loading,
              onPressed: () async {
                setState(() => _loading = true);
                await Future.delayed(const Duration(milliseconds: 1500));
                if (context.mounted) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Peminjaman kendaraan berhasil diajukan!',
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
  );
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  const _DropdownField({
    this.value,
    required this.items,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
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
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      hint: Text(
        hint,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textHint,
          fontSize: 13,
        ),
      ),
      items: items
          .map(
            (r) => DropdownMenuItem(
              value: r,
              child: Text(r, style: AppTextStyles.body.copyWith(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  const _DateField({this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Pilih tanggal',
              style: date != null
                  ? AppTextStyles.body.copyWith(fontSize: 12)
                  : AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Riwayat Kendaraan ---
class _RiwayatKendaraan extends StatelessWidget {
  const _RiwayatKendaraan();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _riwayatData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RiwayatTile(data: _riwayatData[i]),
    );
  }

  static const List<Map<String, dynamic>> _riwayatData = [
    {
      'kendaraan': 'Toyota Innova - B 1234 XY',
      'tujuan': 'Kantor DPRD Provinsi Lampung',
      'peminjam': 'Drs. Ahmad Fauzi',
      'driver': 'Bpk. Sutrisno',
      'tglBerangkat': '5 Apr 2026',
      'tglKembali': '5 Apr 2026',
      'jarak': '24 km',
      'status': 'Selesai',
      'statusColor': AppColors.success,
    },
    {
      'kendaraan': 'Honda CRV - B 5678 AB',
      'tujuan': 'Bandara Radin Inten II',
      'peminjam': 'Ir. Henny Marlina',
      'driver': 'Bpk. Haryanto',
      'tglBerangkat': '6 Apr 2026',
      'tglKembali': '7 Apr 2026',
      'jarak': '32 km',
      'status': 'Berlangsung',
      'statusColor': AppColors.warning,
    },
    {
      'kendaraan': 'Daihatsu Xenia - BE 1111 AC',
      'tujuan': 'Kabupaten Pringsewu',
      'peminjam': 'Budi Santoso, S.H.',
      'driver': 'Mandiri',
      'tglBerangkat': '4 Apr 2026',
      'tglKembali': '4 Apr 2026',
      'jarak': '58 km',
      'status': 'Selesai',
      'statusColor': AppColors.success,
    },
  ];
}

class _RiwayatTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RiwayatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = data['statusColor'] as Color;
    return NeuCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DetailRiwayatScreen(data: data)),
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
                  Icons.directions_car,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['kendaraan'] as String,
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['peminjam'] as String,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: data['status'] as String, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data['tujuan'] as String,
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ),
              const Icon(
                Icons.social_distance_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                data['jarak'] as String,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${data['tglBerangkat']} → ${data['tglKembali']}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRiwayatScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DetailRiwayatScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Perjalanan', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Kendaraan',
                    value: data['kendaraan'] as String,
                    icon: Icons.directions_car_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Peminjam',
                    value: data['peminjam'] as String,
                    icon: Icons.person_outline,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Pengemudi',
                    value: data['driver'] as String,
                    icon: Icons.drive_eta_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Tujuan',
                    value: data['tujuan'] as String,
                    icon: Icons.place_outlined,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Berangkat',
                    value: data['tglBerangkat'] as String,
                    icon: Icons.flight_takeoff,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Kembali',
                    value: data['tglKembali'] as String,
                    icon: Icons.flight_land,
                    isLast: false,
                  ),
                  _DetailRow(
                    label: 'Jarak',
                    value: data['jarak'] as String,
                    icon: Icons.social_distance_outlined,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Map placeholder
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rute Perjalanan', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Peta Rute Perjalanan',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '(Google Maps Integration)',
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
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
