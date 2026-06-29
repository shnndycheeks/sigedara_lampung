import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';

class AdminLaporanScreen extends StatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  State<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends State<AdminLaporanScreen> {
  int _filterIndex = 0;
  final List<String> _filters = ['Semua', 'Proses', 'Selesai', 'Ditolak'];

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

  void _showUpdateDialog(int realIndex, Map<String, dynamic> item) {
    String newStatus = item['status'];
    final catatan = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Status Laporan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item['id'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Status Baru',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Proses', 'Selesai', 'Ditolak'].map((s) {
                    final selected = newStatus == s;
                    final color = _statusColor(s);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDlg(() => newStatus = s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha:0.15)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? color
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: catatan,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Catatan admin (opsional)...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _laporanList[realIndex]['status'] = newStatus;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Status laporan ${item['id']} diubah ke "$newStatus"',
                      ),
                      backgroundColor: _statusColor(newStatus),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final realIndex = _laporanList.indexOf(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.70,
        maxChildSize: 0.92,
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
                      color: _statusColor(item['status']).withValues(alpha:0.12),
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
              _detailRow('Tanggal Laporan', item['tanggal']),
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
              if (item['status'] == 'Proses')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpdateDialog(realIndex, item);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Update Status',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showUpdateDialog(realIndex, item);
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    label: const Text(
                      'Ubah Status',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;
    final proses = _laporanList.where((e) => e['status'] == 'Proses').length;

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
            NavigationService.goHomeAdmin?.call();
          },
        ),
        actions: [
          if (proses > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$proses Proses',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _summaryCard(
                  'Total',
                  _laporanList.length.toString(),
                  AppColors.primary,
                  Icons.report_problem,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  'Proses',
                  _laporanList
                      .where((e) => e['status'] == 'Proses')
                      .length
                      .toString(),
                  AppColors.warning,
                  Icons.hourglass_top,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  'Selesai',
                  _laporanList
                      .where((e) => e['status'] == 'Selesai')
                      .length
                      .toString(),
                  AppColors.success,
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  'Ditolak',
                  _laporanList
                      .where((e) => e['status'] == 'Ditolak')
                      .length
                      .toString(),
                  AppColors.error,
                  Icons.cancel_outlined,
                ),
              ],
            ),
          ),
          // Filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _filterIndex = i),
                    ),
                  );
                }),
              ),
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
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _laporanTile(Map<String, dynamic> item) {
    final realIndex = _laporanList.indexOf(item);
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
                      '${item['id']} · ${item['pelapor']}',
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
                        Flexible(
                          child: Text(
                            item['tanggal'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
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
                  if (item['status'] == 'Proses') ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showUpdateDialog(realIndex, item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ],
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
        color: color.withValues(alpha:0.12),
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
}
