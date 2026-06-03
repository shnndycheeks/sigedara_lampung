import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class AdminKendaraanScreen extends StatefulWidget {
  const AdminKendaraanScreen({super.key});

  @override
  State<AdminKendaraanScreen> createState() => _AdminKendaraanScreenState();
}

class _AdminKendaraanScreenState extends State<AdminKendaraanScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0;
  final List<String> _filters = ['Semua', 'Tersedia', 'Digunakan', 'Perawatan'];

  final List<Map<String, dynamic>> _kendaraanList = [
    {
      'nama': 'Toyota Innova',
      'plat': 'B 1234 XY',
      'jenis': 'MPV',
      'tahun': '2022',
      'warna': 'Hitam',
      'status': 'Tersedia',
      'peminjam': '',
      'bbm': 'Solar',
    },
    {
      'nama': 'Toyota Avanza',
      'plat': 'BE 5555 AA',
      'jenis': 'MPV',
      'tahun': '2021',
      'warna': 'Putih',
      'status': 'Digunakan',
      'peminjam': 'Hj. Ratna W.',
      'bbm': 'Bensin',
    },
    {
      'nama': 'Mitsubishi Pajero',
      'plat': 'BE 9999 ZZ',
      'jenis': 'SUV',
      'tahun': '2023',
      'warna': 'Silver',
      'status': 'Tersedia',
      'peminjam': '',
      'bbm': 'Solar',
    },
    {
      'nama': 'Honda Jazz',
      'plat': 'BE 2222 BB',
      'jenis': 'Hatchback',
      'tahun': '2020',
      'warna': 'Merah',
      'status': 'Perawatan',
      'peminjam': '',
      'bbm': 'Bensin',
    },
    {
      'nama': 'Isuzu Elf',
      'plat': 'BE 7777 MC',
      'jenis': 'Minibus',
      'tahun': '2019',
      'warna': 'Putih',
      'status': 'Tersedia',
      'peminjam': '',
      'bbm': 'Solar',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _kendaraanList.where((k) {
      final matchSearch =
          _searchQuery.isEmpty ||
          (k['nama'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (k['plat'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchFilter =
          _filterIndex == 0 || k['status'].toString() == _filters[_filterIndex];
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int? _parseValidYear(String raw) {
    final value = int.tryParse(raw);
    if (value == null) return null;
    final maxYear = DateTime.now().year + 1;
    if (value < 1980 || value > maxYear) return null;
    return value;
  }

  String? _validateKendaraanForm({
    required String nama,
    required String plat,
    required String tahun,
    required String warna,
  }) {
    if (nama.isEmpty) return 'Nama kendaraan wajib diisi.';
    if (plat.isEmpty) return 'Nomor plat wajib diisi.';
    if (warna.isEmpty) return 'Warna kendaraan wajib diisi.';
    if (_parseValidYear(tahun) == null) {
      return 'Tahun kendaraan tidak valid (contoh: 2024).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Kendaraan'),
        backgroundColor: AppColors.primaryDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        automaticallyImplyLeading: false,
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
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _showAddEditDialog(context, null),
            tooltip: 'Tambah Kendaraan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, null),
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Laporan Kerusakan',
                  child: InkWell(
                    onTap: () => NavigationService.goToTabAdmin?.call(4),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          ? AppColors.primaryDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filterIndex == i
                            ? AppColors.primaryDark
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
          const SizedBox(height: 10),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'Kendaraan tidak ditemukan',
                    subtitle: 'Coba gunakan kata kunci lain',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _AdminKendaraanTile(
                      data: _filtered[i],
                      onEdit: () => _showAddEditDialog(context, _filtered[i]),
                      onDelete: () => _showDeleteDialog(context, _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) {
    final namaCtrl = TextEditingController(
      text: existing?['nama'] as String? ?? '',
    );
    final platCtrl = TextEditingController(
      text: existing?['plat'] as String? ?? '',
    );
    final tahunCtrl = TextEditingController(
      text: existing?['tahun'] as String? ?? '',
    );
    final warnaCtrl = TextEditingController(
      text: existing?['warna'] as String? ?? '',
    );
    String selectedJenis = existing?['jenis'] as String? ?? 'MPV';
    String selectedStatus = existing?['status'] as String? ?? 'Tersedia';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing == null ? 'Tambah Kendaraan' : 'Edit Kendaraan',
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogField(label: 'Nama Kendaraan', controller: namaCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Nomor Plat', controller: platCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Tahun', controller: tahunCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Warna', controller: warnaCtrl),
                const SizedBox(height: 12),
                const Text('Jenis', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedJenis,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: ['MPV', 'SUV', 'Sedan', 'Hatchback', 'Minibus', 'Truk']
                      .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                      .toList(),
                  onChanged: (v) =>
                      setStateD(() => selectedJenis = v ?? selectedJenis),
                ),
                const SizedBox(height: 12),
                const Text('Status', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: ['Tersedia', 'Digunakan', 'Perawatan']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setStateD(() => selectedStatus = v ?? selectedStatus),
                ),
              ],
            ),
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
                final nama = namaCtrl.text.trim();
                final plat = platCtrl.text.trim().toUpperCase();
                final tahun = tahunCtrl.text.trim();
                final warna = warnaCtrl.text.trim();

                final validationMessage = _validateKendaraanForm(
                  nama: nama,
                  plat: plat,
                  tahun: tahun,
                  warna: warna,
                );

                if (validationMessage != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(validationMessage)));
                  return;
                }

                setState(() {
                  if (existing == null) {
                    _kendaraanList.add({
                      'nama': nama,
                      'plat': plat,
                      'jenis': selectedJenis,
                      'tahun': tahun,
                      'warna': warna,
                      'status': selectedStatus,
                      'peminjam': '',
                      'bbm': 'Bensin',
                    });
                  } else {
                    existing['nama'] = nama;
                    existing['plat'] = plat;
                    existing['jenis'] = selectedJenis;
                    existing['tahun'] = tahun;
                    existing['warna'] = warna;
                    existing['status'] = selectedStatus;
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(existing == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kendaraan', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['nama']} — ${item['plat']}"?',
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
              setState(() => _kendaraanList.remove(item));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _AdminKendaraanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminKendaraanTile({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Tersedia':
        return AppColors.success;
      case 'Digunakan':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_car,
              color: _statusColor(status),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['nama'] as String, style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(
                  '${data['plat']} • ${data['jenis']} • ${data['tahun']}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(label: status, color: _statusColor(status)),
                    if ((data['peminjam'] as String).isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• ${data['peminjam']}',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.error,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dialog Field ──────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _DialogField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
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
