import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';

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
  List<Map<String, dynamic>> _kendaraanList = [];
  bool _loadingKendaraan = true;
  String? _errorKendaraan;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadKendaraan();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKendaraan() async {
    try {
      final data = await DatabaseService.getKendaraan();

      final mapped = data.map((k) {
        final status = (k['status'] ?? 'tersedia').toString();

        Color statusColor;
        String statusLabel;

        if (status == 'tersedia') {
          statusColor = AppColors.success;
          statusLabel = 'Tersedia';
        } else if (status == 'dipinjam') {
          statusColor = AppColors.warning;
          statusLabel = 'Digunakan';
        } else {
          statusColor = AppColors.error;
          statusLabel = 'Servis';
        }

        return {
          'id': k['id'],
          'nama': k['nama'] ?? '-',
          'plat': k['plat_nomor'] ?? '-',
          'jenis': k['jenis'] ?? '-',
          'status': statusLabel,
          'statusColor': statusColor,
          'bbm': 0.75,
          'servisDate': '-',
          'warna': '-',
          'tahun': '-',
          'cc': '-',
          'icon': Icons.directions_car,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _kendaraanList = mapped;
        _loadingKendaraan = false;
        _errorKendaraan = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingKendaraan = false;
        _errorKendaraan = e.toString();
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text(
        'Kendaraan Dinas',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            return;
          }

          if (NavigationService.goToTabUser != null) {
            NavigationService.goToTabUser!(0);
            return;
          }

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
            MaterialPageRoute(
              builder: (_) => const KalenderKendaraanScreen(),
            ),
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
    if (_loadingKendaraan) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorKendaraan != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat kendaraan',
            subtitle: 'Cek koneksi atau policy Supabase kendaraan',
          ),
        ),
      );
    }

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

    return RefreshIndicator(
      onRefresh: _loadKendaraan,
      child: Column(
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
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: 'Kendaraan tidak ditemukan',
                        subtitle: 'Coba gunakan kata kunci lain',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _KendaraanTile(data: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
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
        title: Text(
          data['nama'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

  Color _iconColor() {
    if (icon == Icons.calendar_today_outlined) return AppColors.primary;
    return AppColors.primary.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: _iconColor()),
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
        title: const Text(
          'Form Peminjaman Kendaraan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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
  String? _selectedKendaraanId;
  String? _selectedDriver;

  final _tujuanCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  DateTime? _tglBerangkat;
  DateTime? _tglKembali;

  bool _loading = false;
  bool _loadingKendaraan = true;

  List<Map<String, dynamic>> _kendaraanData = [];
  List<String> _kendaraanList = [];

  final List<String> _driverList = [
    'Bpk. Sutrisno (Pengemudi)',
    'Bpk. Haryanto (Pengemudi)',
    'Bpk. Wahyu (Pengemudi)',
    'Mandiri (Sendiri)',
  ];

  @override
  void initState() {
    super.initState();
    _loadKendaraanUntukForm();
  }

  Future<void> _loadKendaraanUntukForm() async {
    try {
      final data = await DatabaseService.getKendaraan();

      final tersedia = data.where((k) {
        final status = (k['status'] ?? '').toString().toLowerCase();
        return status == 'tersedia';
      }).toList();

      final listNama = tersedia.map((k) {
        final nama = k['nama'] ?? '-';
        final plat = k['plat_nomor'] ?? '-';
        return '$nama - $plat';
      }).toList();

      if (!mounted) return;

      setState(() {
        _kendaraanData = tersedia;
        _kendaraanList = List<String>.from(listNama);
        _loadingKendaraan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingKendaraan = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat kendaraan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _pilihKendaraan(String? value) {
    if (value == null) {
      setState(() {
        _selectedKendaraan = null;
        _selectedKendaraanId = null;
      });
      return;
    }

    final index = _kendaraanList.indexOf(value);

    if (index == -1) {
      setState(() {
        _selectedKendaraan = value;
        _selectedKendaraanId = null;
      });
      return;
    }

    final kendaraan = _kendaraanData[index];

    setState(() {
      _selectedKendaraan = value;
      _selectedKendaraanId = kendaraan['id']?.toString();
    });
  }

  Future<void> _submitPeminjaman() async {
    if (_loading) return;

    if (_selectedKendaraanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan terlebih dahulu')),
      );
      return;
    }

    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pengemudi terlebih dahulu')),
      );
      return;
    }

    if (_tujuanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tujuan perjalanan wajib diisi')),
      );
      return;
    }

    if (_lokasiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi tujuan wajib diisi')),
      );
      return;
    }

    if (_tglBerangkat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal berangkat wajib dipilih')),
      );
      return;
    }

    final tanggalMulai = _tglBerangkat!;
    final tanggalSelesai = _tglKembali ?? _tglBerangkat!;

    if (tanggalSelesai.isBefore(tanggalMulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal kembali tidak boleh sebelum tanggal berangkat'),
        ),
      );
      return;
    }

    final keperluan = '''
Kendaraan: $_selectedKendaraan
Pengemudi: $_selectedDriver
Tujuan: ${_tujuanCtrl.text.trim()}
Lokasi: ${_lokasiCtrl.text.trim()}
Keterangan: ${_keteranganCtrl.text.trim().isEmpty ? '-' : _keteranganCtrl.text.trim()}
''';

    setState(() => _loading = true);

    try {
      await DatabaseService.ajukanPeminjamanKendaraan(
        kendaraanId: _selectedKendaraanId!,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        keperluan: keperluan,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _selectedKendaraan = null;
        _selectedKendaraanId = null;
        _selectedDriver = null;
        _tglBerangkat = null;
        _tglKembali = null;
        _tujuanCtrl.clear();
        _lokasiCtrl.clear();
        _keteranganCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Peminjaman kendaraan berhasil diajukan!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan peminjaman: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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

          if (_loadingKendaraan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Memuat kendaraan...'),
                ],
              ),
            )
          else
            _DropdownField(
              value: _selectedKendaraan,
              items: _kendaraanList,
              hint: 'Pilih kendaraan tersedia',
              icon: Icons.directions_car_outlined,
              onChanged: _pilihKendaraan,
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
                      onPick: (d) {
                        setState(() => _tglBerangkat = d);
                      },
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
                      onPick: (d) {
                        setState(() => _tglKembali = d);
                      },
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
              onPressed: _submitPeminjaman,
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
      initialValue: value,
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
              color: AppColors.primary,
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
class _RiwayatKendaraan extends StatefulWidget {
  const _RiwayatKendaraan();

  @override
  State<_RiwayatKendaraan> createState() => _RiwayatKendaraanState();
}

class _RiwayatKendaraanState extends State<_RiwayatKendaraan> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _riwayatData = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final peminjaman = await DatabaseService.getPeminjamanSaya();
      final kendaraan = await DatabaseService.getKendaraan();

      final kendaraanMap = {
        for (final k in kendaraan) k['id'].toString(): k,
      };

      final data = peminjaman.where((p) {
        return p['tipe_item'] == 'kendaraan';
      }).map((p) {
        final kendaraanItem = kendaraanMap[p['item_id'].toString()];
        final keperluan = p['keperluan']?.toString() ?? '-';

        final kendaraanNama = kendaraanItem != null
            ? '${kendaraanItem['nama']} - ${kendaraanItem['plat_nomor']}'
            : _ambilIsiKeperluan(keperluan, 'Kendaraan') ?? 'Kendaraan';

        final pengemudi =
            _ambilIsiKeperluan(keperluan, 'Pengemudi') ?? '-';
        final tujuan = _ambilIsiKeperluan(keperluan, 'Tujuan') ?? '-';
        final lokasi = _ambilIsiKeperluan(keperluan, 'Lokasi') ?? '-';

        final status = _mapStatus(p['status']);

        return {
          'kendaraan': kendaraanNama,
          'tujuan': lokasi == '-' ? tujuan : '$tujuan - $lokasi',
          'peminjam': 'Saya',
          'driver': pengemudi,
          'tglBerangkat': _formatTanggal(p['tanggal_mulai']),
          'tglKembali': _formatTanggal(p['tanggal_selesai']),
          'jarak': '-',
          'status': status,
          'statusColor': _statusColor(status),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _riwayatData = data;
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

  String? _ambilIsiKeperluan(String text, String label) {
    final lines = text.split('\n');

    for (final line in lines) {
      final clean = line.trim();

      if (clean.startsWith('$label:')) {
        return clean.replaceFirst('$label:', '').trim();
      }
    }

    return null;
  }

  String _mapStatus(dynamic status) {
    switch (status.toString()) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _formatTanggal(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat riwayat',
            subtitle: 'Cek koneksi atau policy Supabase',
          ),
        ),
      );
    }

    if (_riwayatData.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRiwayat,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 120),
            EmptyState(
              icon: Icons.history_outlined,
              title: 'Belum ada riwayat',
              subtitle: 'Pengajuan kendaraan kamu akan muncul di sini',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRiwayat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _riwayatData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _RiwayatTile(data: _riwayatData[i]),
      ),
    );
  }
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
                color: AppColors.primary,
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
        title: const Text(
          'Detail Perjalanan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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

// --- Kalender Kendaraan Screen ---
class KalenderKendaraanScreen extends StatelessWidget {
  const KalenderKendaraanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kalender Kendaraan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const _KalenderKendaraan(),
    );
  }
}

// --- Kalender Kendaraan ---
class _KalenderKendaraan extends StatefulWidget {
  const _KalenderKendaraan();

  @override
  State<_KalenderKendaraan> createState() => _KalenderKendaraanState();
}

class _KalenderKendaraanState extends State<_KalenderKendaraan> {
  DateTime _month = DateTime(2026, 4);
  String _selectedKendaraan = 'Toyota Innova';

  final List<String> _kendaraanList = [
    'Toyota Innova',
    'Honda CRV',
    'Mitsubishi Pajero',
    'Toyota Hiace',
    'Daihatsu Xenia',
    'Toyota Land Cruiser',
  ];

  final Map<String, List<int>> _booked = {
    'Toyota Innova': [5, 8, 9, 12, 15, 21],
    'Honda CRV': [6, 7, 10, 16, 17, 22, 23],
    'Mitsubishi Pajero': [9, 11, 13, 18, 25],
    'Toyota Hiace': [8, 14, 15, 16, 20, 27],
    'Daihatsu Xenia': [4, 5, 10, 19, 24, 28],
    'Toyota Land Cruiser': [7, 12, 13, 18, 26, 29],
  };

  final Map<String, Map<int, Map<String, String>>> _bookingDetails = {
    'Toyota Innova': {
      5: {
        'peminjam': 'Drs. Ahmad Fauzi',
        'tujuan': 'Kantor DPRD Provinsi',
        'durasi': '08:00 – 17:00 (9 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      8: {
        'peminjam': 'Ir. Henny Marlina',
        'tujuan': 'Bandara Radin Inten II',
        'durasi': '06:00 – 10:00 (4 jam)',
        'driver': 'Bpk. Haryanto',
      },
      9: {
        'peminjam': 'Budi Santoso, S.H.',
        'tujuan': 'Kabupaten Pringsewu',
        'durasi': '09:00 – 16:00 (7 jam)',
        'driver': 'Mandiri',
      },
      12: {
        'peminjam': 'Sari Dewi',
        'tujuan': 'Kec. Kedaton',
        'durasi': '08:00 – 12:00 (4 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      15: {
        'peminjam': 'Rendi Pratama',
        'tujuan': 'Kab. Lampung Utara',
        'durasi': '07:00 – 18:00 (11 jam)',
        'driver': 'Bpk. Wahyu',
      },
      21: {
        'peminjam': 'Andi Wijaya',
        'tujuan': 'Pelabuhan Bakauheni',
        'durasi': '05:00 – 15:00 (10 jam)',
        'driver': 'Bpk. Sutrisno',
      },
    },
    'Honda CRV': {
      6: {
        'peminjam': 'Maya Putri',
        'tujuan': 'Kantor Walikota',
        'durasi': '09:00 – 13:00 (4 jam)',
        'driver': 'Mandiri',
      },
      7: {
        'peminjam': 'Tono Basuki',
        'tujuan': 'Kab. Lampung Selatan',
        'durasi': '08:00 – 16:00 (8 jam)',
        'driver': 'Bpk. Haryanto',
      },
      10: {
        'peminjam': 'Lina Susanti',
        'tujuan': 'Gedung Serbaguna Prov.',
        'durasi': '10:00 – 14:00 (4 jam)',
        'driver': 'Mandiri',
      },
      16: {
        'peminjam': 'Ir. Henny Marlina',
        'tujuan': 'Kota Metro',
        'durasi': '07:00 – 19:00 (12 jam)',
        'driver': 'Bpk. Haryanto',
      },
      17: {
        'peminjam': 'Drs. Ahmad Fauzi',
        'tujuan': 'Bandara Radin Inten II',
        'durasi': '12:00 – 15:00 (3 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      22: {
        'peminjam': 'Hendra Putra',
        'tujuan': 'RS Urip Sumoharjo',
        'durasi': '09:00 – 11:00 (2 jam)',
        'driver': 'Mandiri',
      },
      23: {
        'peminjam': 'Fajar Nugroho',
        'tujuan': 'Kab. Tanggamus',
        'durasi': '07:00 – 18:00 (11 jam)',
        'driver': 'Bpk. Wahyu',
      },
    },
    'Mitsubishi Pajero': {
      9: {
        'peminjam': 'Drs. Ahmad Fauzi',
        'tujuan': 'Kab. Lampung Barat',
        'durasi': '06:00 – 20:00 (14 jam)',
        'driver': 'Bpk. Haryanto',
      },
      11: {
        'peminjam': 'Andi Wijaya',
        'tujuan': 'Kec. Sukarame',
        'durasi': '09:00 – 12:00 (3 jam)',
        'driver': 'Mandiri',
      },
      13: {
        'peminjam': 'Sari Dewi',
        'tujuan': 'Kantor BPN Provinsi',
        'durasi': '10:00 – 14:00 (4 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      18: {
        'peminjam': 'Budi Santoso, S.H.',
        'tujuan': 'Kab. Way Kanan',
        'durasi': '07:00 – 19:00 (12 jam)',
        'driver': 'Bpk. Wahyu',
      },
      25: {
        'peminjam': 'Rendi Pratama',
        'tujuan': 'Kab. Pesawaran',
        'durasi': '08:00 – 15:00 (7 jam)',
        'driver': 'Bpk. Haryanto',
      },
    },
    'Toyota Hiace': {
      8: {
        'peminjam': 'Tim Protokol',
        'tujuan': 'Bandara – Penjemputan',
        'durasi': '14:00 – 17:00 (3 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      14: {
        'peminjam': 'Panitia Seminar',
        'tujuan': 'Hotel Novotel Lampung',
        'durasi': '08:00 – 22:00 (14 jam)',
        'driver': 'Bpk. Haryanto',
      },
      15: {
        'peminjam': 'Panitia Seminar',
        'tujuan': 'Hotel Novotel Lampung',
        'durasi': '08:00 – 22:00 (14 jam)',
        'driver': 'Bpk. Haryanto',
      },
      16: {
        'peminjam': 'Panitia Seminar',
        'tujuan': 'Hotel Novotel Lampung',
        'durasi': '08:00 – 17:00 (9 jam)',
        'driver': 'Bpk. Haryanto',
      },
      20: {
        'peminjam': 'Tim Olahraga',
        'tujuan': 'GOR Saburai',
        'durasi': '06:00 – 10:00 (4 jam)',
        'driver': 'Bpk. Wahyu',
      },
      27: {
        'peminjam': 'Rombongan Studi',
        'tujuan': 'Kota Palembang',
        'durasi': '05:00 – 22:00 (17 jam)',
        'driver': 'Bpk. Sutrisno',
      },
    },
    'Daihatsu Xenia': {
      4: {
        'peminjam': 'Budi Santoso, S.H.',
        'tujuan': 'Kab. Pringsewu',
        'durasi': '08:00 – 17:00 (9 jam)',
        'driver': 'Mandiri',
      },
      5: {
        'peminjam': 'Lina Susanti',
        'tujuan': 'Kec. Rajabasa',
        'durasi': '09:00 – 13:00 (4 jam)',
        'driver': 'Mandiri',
      },
      10: {
        'peminjam': 'Tono Basuki',
        'tujuan': 'Kec. Tanjung Senang',
        'durasi': '10:00 – 12:00 (2 jam)',
        'driver': 'Mandiri',
      },
      19: {
        'peminjam': 'Maya Putri',
        'tujuan': 'Kantor Disdukcapil',
        'durasi': '09:00 – 11:00 (2 jam)',
        'driver': 'Mandiri',
      },
      24: {
        'peminjam': 'Sari Dewi',
        'tujuan': 'Kec. Kemiling',
        'durasi': '10:00 – 14:00 (4 jam)',
        'driver': 'Mandiri',
      },
      28: {
        'peminjam': 'Andi Wijaya',
        'tujuan': 'Kab. Tulang Bawang',
        'durasi': '07:00 – 18:00 (11 jam)',
        'driver': 'Bpk. Wahyu',
      },
    },
    'Toyota Land Cruiser': {
      7: {
        'peminjam': 'Gubernur / Pimpinan',
        'tujuan': 'Kab. Lampung Barat',
        'durasi': '07:00 – 19:00 (12 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      12: {
        'peminjam': 'Gubernur / Pimpinan',
        'tujuan': 'Kab. Pesisir Barat',
        'durasi': '06:00 – 21:00 (15 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      13: {
        'peminjam': 'Kepala Biro Umum',
        'tujuan': 'Jakarta (Dinas Luar)',
        'durasi': '06:00 – 22:00 (16 jam)',
        'driver': 'Bpk. Haryanto',
      },
      18: {
        'peminjam': 'Gubernur / Pimpinan',
        'tujuan': 'Kab. Mesuji',
        'durasi': '07:00 – 20:00 (13 jam)',
        'driver': 'Bpk. Sutrisno',
      },
      26: {
        'peminjam': 'Wakil Gubernur',
        'tujuan': 'Kota Metro',
        'durasi': '09:00 – 15:00 (6 jam)',
        'driver': 'Bpk. Haryanto',
      },
      29: {
        'peminjam': 'Kepala Biro Umum',
        'tujuan': 'Kab. Lampung Tengah',
        'durasi': '08:00 – 17:00 (9 jam)',
        'driver': 'Bpk. Wahyu',
      },
    },
  };

  void _showDayDetail(BuildContext context, int day, bool isBooked) {
    final Map<String, String>? detail = isBooked
        ? (_bookingDetails[_selectedKendaraan]?[day])
        : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isBooked
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBooked ? Icons.directions_car : Icons.check_circle_outline,
                color: isBooked ? AppColors.warning : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$day ${_monthName(_month.month)} ${_month.year}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _selectedKendaraan,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: isBooked && detail != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 16, color: AppColors.divider),
                  _dialogRow(
                    Icons.person_outline,
                    'Peminjam',
                    detail['peminjam']!,
                  ),
                  const SizedBox(height: 10),
                  _dialogRow(Icons.place_outlined, 'Tujuan', detail['tujuan']!),
                  const SizedBox(height: 10),
                  _dialogRow(Icons.access_time, 'Durasi', detail['durasi']!),
                  const SizedBox(height: 10),
                  _dialogRow(
                    Icons.drive_eta_outlined,
                    'Pengemudi',
                    detail['driver']!,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kendaraan sedang digunakan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 16, color: AppColors.divider),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kendaraan tersedia untuk dipinjam',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
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

  Widget _dialogRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final booked = _booked[_selectedKendaraan] ?? [];
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kendaraan selector chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kendaraanList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _kendaraanList[i] == _selectedKendaraan;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedKendaraan = _kendaraanList[i]),
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
                      _kendaraanList[i],
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Month nav — plain white style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${_monthName(_month.month)} ${_month.year}',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Day headers in gold
                Row(
                  children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

                    final Color cellColor;
                    final Color textColor;
                    final BoxBorder? cellBorder;

                    if (isBooked) {
                      cellColor = const Color(0xFFFEE2E2); // Soft red
                      textColor = const Color(0xFFEF4444); // Red
                      cellBorder = Border.all(color: const Color(0xFFFCA5A5), width: 1);
                    } else if (isToday) {
                      cellColor = AppColors.primary;
                      textColor = Colors.white;
                      cellBorder = null;
                    } else {
                      cellColor = Colors.white;
                      textColor = const Color(0xFF334155); // Slate 700
                      cellBorder = Border.all(color: const Color(0xFFE2E8F0), width: 1);
                    }

                    return GestureDetector(
                      onTap: () => _showDayDetail(context, day, isBooked),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cellColor,
                          shape: BoxShape.circle,
                          border: cellBorder,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: isToday || isBooked ? FontWeight.bold : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LegendDot(
                      color: Colors.white,
                      borderColor: Color(0xFFE2E8F0),
                      label: 'Tersedia',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: AppColors.primary,
                      borderColor: Colors.transparent,
                      label: 'Hari ini',
                    ),
                    const SizedBox(width: 16),
                    const _LegendDot(
                      color: Color(0xFFFEE2E2),
                      borderColor: Color(0xFFFCA5A5),
                      label: 'Booking',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;
  const _LegendDot({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
