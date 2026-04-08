import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class LaporanKerusakanScreen extends StatefulWidget {
  const LaporanKerusakanScreen({super.key});

  @override
  State<LaporanKerusakanScreen> createState() => _LaporanKerusakanScreenState();
}

class _LaporanKerusakanScreenState extends State<LaporanKerusakanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _filterIndex = 0;

  final List<String> _filters = ['Semua', 'Proses', 'Selesai', 'Ditolak'];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _namaPelaporCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _namaAsetCtrl = TextEditingController();
  final _kodeAsetCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  DateTime? _tanggalKejadian;
  String _jenisAset = 'Gedung';
  String _tingkatKerusakan = 'Ringan';

  final List<String> _jenisAsetOptions = [
    'Gedung',
    'Kendaraan',
    'Elektronik',
    'Furnitur',
    'Lainnya',
  ];

  final List<String> _tingkatOptions = ['Ringan', 'Sedang', 'Berat'];

  final List<Map<String, dynamic>> _laporanList = [
    {
      'id': 'LK-2025-001',
      'namaAset': 'AC Ruang Rapat Lt. 1',
      'jenisAset': 'Elektronik',
      'kode': 'IT-E-012',
      'pelapor': 'Budi Santoso',
      'unit': 'Bagian Umum',
      'tingkat': 'Sedang',
      'lokasi': 'Gedung Utama Lt. 1',
      'deskripsi':
          'AC tidak dapat mendinginkan ruangan, suara berisik saat menyala.',
      'tanggal': '10 Jun 2025',
      'status': 'Proses',
    },
    {
      'id': 'LK-2025-002',
      'namaAset': 'Pintu Aula Utama',
      'jenisAset': 'Gedung',
      'kode': 'GDG-003',
      'pelapor': 'Sari Dewi',
      'unit': 'Bagian Protokol',
      'tingkat': 'Ringan',
      'lokasi': 'Aula Utama',
      'deskripsi': 'Engsel pintu rusak, pintu tidak dapat menutup sempurna.',
      'tanggal': '08 Jun 2025',
      'status': 'Selesai',
    },
    {
      'id': 'LK-2025-003',
      'namaAset': 'Laptop Dell XPS',
      'jenisAset': 'Elektronik',
      'kode': 'IT-0041',
      'pelapor': 'Rendi Pratama',
      'unit': 'Bagian IT',
      'tingkat': 'Berat',
      'lokasi': 'Ruang IT',
      'deskripsi': 'Layar laptop retak akibat terjatuh, tidak dapat digunakan.',
      'tanggal': '05 Jun 2025',
      'status': 'Proses',
    },
    {
      'id': 'LK-2025-004',
      'namaAset': 'Kursi Roda Kantor',
      'jenisAset': 'Furnitur',
      'kode': 'FUR-022',
      'pelapor': 'Andi Wijaya',
      'unit': 'Bagian Keuangan',
      'tingkat': 'Ringan',
      'lokasi': 'Ruang Keuangan',
      'deskripsi': 'Roda kursi patah, tidak dapat diputar.',
      'tanggal': '01 Jun 2025',
      'status': 'Selesai',
    },
    {
      'id': 'LK-2025-005',
      'namaAset': 'Genset Cadangan',
      'jenisAset': 'Elektronik',
      'kode': 'IT-GS-001',
      'pelapor': 'Hendra Putra',
      'unit': 'Bagian Teknik',
      'tingkat': 'Berat',
      'lokasi': 'Ruang Genset',
      'deskripsi':
          'Genset tidak dapat dinyalakan, kemungkinan masalah pada starter.',
      'tanggal': '28 Mei 2025',
      'status': 'Ditolak',
    },
  ];

  List<Map<String, dynamic>> get _filteredList {
    if (_filterIndex == 0) return _laporanList;
    final status = _filters[_filterIndex];
    return _laporanList.where((e) => e['status'] == status).toList();
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _namaPelaporCtrl.dispose();
    _unitCtrl.dispose();
    _namaAsetCtrl.dispose();
    _kodeAsetCtrl.dispose();
    _lokasiCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Proses':
        return AppColors.warning;
      case 'Selesai':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _tingkatColor(String tingkat) {
    switch (tingkat) {
      case 'Ringan':
        return AppColors.success;
      case 'Sedang':
        return AppColors.warning;
      case 'Berat':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _jenisAsetIcon(String jenis) {
    switch (jenis) {
      case 'Gedung':
        return Icons.domain;
      case 'Kendaraan':
        return Icons.directions_car;
      case 'Elektronik':
        return Icons.devices;
      case 'Furnitur':
        return Icons.chair;
      default:
        return Icons.inventory_2;
    }
  }

  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _jenisAsetIcon(item['jenisAset']),
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['namaAset'],
                          style: AppTextStyles.h3.copyWith(fontSize: 15),
                        ),
                        Text(
                          item['kode'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                      color: _statusColor(item['status']).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(item['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              _detailRow('No. Laporan', item['id']),
              _detailRow('Pelapor', item['pelapor']),
              _detailRow('Unit / Divisi', item['unit']),
              _detailRow('Jenis Aset', item['jenisAset']),
              _detailRow('Lokasi', item['lokasi']),
              _detailRow('Tanggal', item['tanggal']),
              _detailRow(
                'Tingkat Kerusakan',
                item['tingkat'],
                valueColor: _tingkatColor(item['tingkat']),
              ),
              const SizedBox(height: 12),
              Text(
                'Deskripsi Kerusakan',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item['deskripsi'],
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitLaporan() {
    if (_formKey.currentState!.validate()) {
      if (_tanggalKejadian == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal kejadian wajib diisi')),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Laporan Terkirim',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Laporan kerusakan berhasil dikirim dan akan segera ditindaklanjuti oleh tim teknis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
                _tab.animateTo(0);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaPelaporCtrl.clear();
    _unitCtrl.clear();
    _namaAsetCtrl.clear();
    _kodeAsetCtrl.clear();
    _lokasiCtrl.clear();
    _deskripsiCtrl.clear();
    setState(() {
      _tanggalKejadian = null;
      _jenisAset = 'Gedung';
      _tingkatKerusakan = 'Ringan';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Kerusakan'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Daftar Laporan'),
            Tab(text: 'Buat Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildDaftarTab(), _buildFormTab()],
      ),
    );
  }

  // ─── Tab 1: Daftar Laporan ───────────────────────────────────────────────
  Widget _buildDaftarTab() {
    final list = _filteredList;
    return Column(
      children: [
        // Filter chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = _filterIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filters[i]),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    onSelected: (_) => setState(() => _filterIndex = i),
                  ),
                );
              }),
            ),
          ),
        ),
        // Summary row
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              _summaryChip(
                'Total',
                _laporanList.length.toString(),
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                'Proses',
                _laporanList
                    .where((e) => e['status'] == 'Proses')
                    .length
                    .toString(),
                AppColors.warning,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                'Selesai',
                _laporanList
                    .where((e) => e['status'] == 'Selesai')
                    .length
                    .toString(),
                AppColors.success,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        // List
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tidak ada laporan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _laporanTile(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _laporanTile(Map<String, dynamic> item) {
    final statusColor = _statusColor(item['status']);
    final tingkatColor = _tingkatColor(item['tingkat']);
    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _jenisAsetIcon(item['jenisAset']),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['namaAset'],
                      style: AppTextStyles.h4.copyWith(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['id']} · ${item['lokasi']}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(item['tingkat'], tingkatColor),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.person_outline,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${item['pelapor']} · ${item['tanggal']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badge(item['status'], statusColor),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ─── Tab 2: Buat Laporan ─────────────────────────────────────────────────
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, Color(0xFF5C4000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.report_problem,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buat Laporan Kerusakan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Laporkan kerusakan aset untuk segera ditindaklanjuti',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Data Pelapor'),
            const SizedBox(height: 12),
            _formField(
              controller: _namaPelaporCtrl,
              label: 'Nama Pelapor',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama pelapor wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _unitCtrl,
              label: 'Unit / Divisi',
              hint: 'Contoh: Bagian Umum',
              icon: Icons.business_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Unit wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            _sectionTitle('Data Aset'),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Jenis Aset',
              value: _jenisAset,
              items: _jenisAsetOptions,
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _jenisAset = v!),
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _namaAsetCtrl,
              label: 'Nama Aset',
              hint: 'Contoh: AC Ruang Rapat Lt. 1',
              icon: Icons.widgets_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nama aset wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _kodeAsetCtrl,
              label: 'Kode Aset',
              hint: 'Contoh: IT-E-012',
              icon: Icons.qr_code_outlined,
            ),
            const SizedBox(height: 12),
            _formField(
              controller: _lokasiCtrl,
              label: 'Lokasi Aset',
              hint: 'Contoh: Gedung Utama Lt. 1',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            _sectionTitle('Detail Kerusakan'),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Tingkat Kerusakan',
              value: _tingkatKerusakan,
              items: _tingkatOptions,
              icon: Icons.warning_amber_outlined,
              onChanged: (v) => setState(() => _tingkatKerusakan = v!),
              itemColors: {
                'Ringan': AppColors.success,
                'Sedang': AppColors.warning,
                'Berat': AppColors.error,
              },
            ),
            const SizedBox(height: 12),
            // Tanggal Kejadian
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
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
                if (picked != null) {
                  setState(() => _tanggalKejadian = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _tanggalKejadian == null
                            ? 'Pilih Tanggal Kejadian'
                            : '${_tanggalKejadian!.day.toString().padLeft(2, '0')}/${_tanggalKejadian!.month.toString().padLeft(2, '0')}/${_tanggalKejadian!.year}',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _tanggalKejadian == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Deskripsi
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Deskripsikan kerusakan secara detail...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textHint,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8, top: 12),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  label: const Text('Deskripsi Kerusakan'),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitLaporan,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Kirim Laporan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _resetForm,
                child: const Text(
                  'Reset Form',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textHint),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          label: Text(label),
          labelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    Map<String, Color>? itemColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          label: Text(label),
          labelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: itemColors != null
                            ? (itemColors[e] ?? AppColors.textPrimary)
                            : AppColors.textPrimary,
                        fontWeight: itemColors != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
