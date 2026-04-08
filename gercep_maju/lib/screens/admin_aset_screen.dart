import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';

class AdminAsetScreen extends StatefulWidget {
  const AdminAsetScreen({super.key});

  @override
  State<AdminAsetScreen> createState() => _AdminAsetScreenState();
}

class _AdminAsetScreenState extends State<AdminAsetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _inventarisList = [
    {
      'nama': 'Ruang Rapat Lt. 1',
      'kode': 'GDG-001',
      'kategori': 'Gedung',
      'kondisi': 'Baik',
      'lokasi': 'Gedung Utama',
      'tahun': '2018',
    },
    {
      'nama': 'Ruang Rapat Lt. 2',
      'kode': 'GDG-002',
      'kategori': 'Gedung',
      'kondisi': 'Baik',
      'lokasi': 'Gedung Utama',
      'tahun': '2018',
    },
    {
      'nama': 'Aula Utama',
      'kode': 'GDG-003',
      'kategori': 'Gedung',
      'kondisi': 'Baik',
      'lokasi': 'Gedung Utama',
      'tahun': '2015',
    },
    {
      'nama': 'Laptop Dell XPS',
      'kode': 'IT-0041',
      'kategori': 'Elektronik',
      'kondisi': 'Baik',
      'lokasi': 'Ruang IT',
      'tahun': '2024',
    },
    {
      'nama': 'Printer HP LaserJet',
      'kode': 'IT-0042',
      'kategori': 'Elektronik',
      'kondisi': 'Rusak Ringan',
      'lokasi': 'Ruang Sekretariat',
      'tahun': '2021',
    },
    {
      'nama': 'AC Split 2 PK',
      'kode': 'EL-0023',
      'kategori': 'Elektronik',
      'kondisi': 'Baik',
      'lokasi': 'Ruang Rapat Lt. 1',
      'tahun': '2022',
    },
    {
      'nama': 'Meja Rapat 10 Orang',
      'kode': 'FRN-011',
      'kategori': 'Furnitur',
      'kondisi': 'Baik',
      'lokasi': 'Aula Utama',
      'tahun': '2019',
    },
    {
      'nama': 'Proyektor Epson',
      'kode': 'IT-0015',
      'kategori': 'Elektronik',
      'kondisi': 'Baik',
      'lokasi': 'Aula Utama',
      'tahun': '2023',
    },
  ];

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

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _inventarisList;
    return _inventarisList.where((a) {
      return (a['nama'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (a['kode'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Aset'),
        backgroundColor: AppColors.primaryDark,
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
            Tab(text: 'Inventaris'),
            Tab(text: 'Ringkasan'),
            Tab(text: 'Laporan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, null),
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Aset',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildInventarisTab(),
          _buildRingkasanTab(),
          _buildLaporanTab(),
        ],
      ),
    );
  }

  // ── Inventaris Tab ──────────────────────────────────────────────────────────
  Widget _buildInventarisTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Cari nama aset atau kode...',
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
          child: _filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aset tidak ditemukan',
                  subtitle: 'Coba gunakan kata kunci lain',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AdminAsetTile(
                    data: _filtered[i],
                    onEdit: () => _showAddEditDialog(context, _filtered[i]),
                    onDelete: () => _showDeleteDialog(context, _filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Ringkasan Tab ───────────────────────────────────────────────────────────
  Widget _buildRingkasanTab() {
    final Map<String, int> byKategori = {};
    final Map<String, int> byKondisi = {};
    for (final a in _inventarisList) {
      final k = a['kategori'] as String;
      final c = a['kondisi'] as String;
      byKategori[k] = (byKategori[k] ?? 0) + 1;
      byKondisi[c] = (byKondisi[c] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NeuCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  value: '${_inventarisList.length}',
                  label: 'Total Aset',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _SummaryCell(
                  value: '${byKondisi['Baik'] ?? 0}',
                  label: 'Kondisi Baik',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _SummaryCell(
                  value: '${byKondisi['Rusak Ringan'] ?? 0}',
                  label: 'Rusak Ringan',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Distribusi Kategori', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...byKategori.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryBar(
              kategori: e.key,
              count: e.value,
              total: _inventarisList.length,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Distribusi Kondisi', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...byKondisi.entries.map((e) {
          Color c;
          switch (e.key) {
            case 'Baik':
              c = AppColors.success;
              break;
            case 'Rusak Ringan':
              c = AppColors.warning;
              break;
            default:
              c = AppColors.error;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryBar(
              kategori: e.key,
              count: e.value,
              total: _inventarisList.length,
              color: c,
            ),
          );
        }),
      ],
    );
  }

  // ── Laporan Tab ─────────────────────────────────────────────────────────────
  Widget _buildLaporanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LaporanTile(
          icon: Icons.picture_as_pdf,
          label: 'Laporan Inventaris Lengkap',
          subtitle: 'Semua data aset dalam format PDF',
          color: AppColors.error,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.table_chart_outlined,
          label: 'Ekspor Data ke Excel',
          subtitle: 'Download spreadsheet inventaris',
          color: AppColors.success,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.bar_chart,
          label: 'Rekap Peminjaman Aset',
          subtitle: 'Statistik penggunaan aset per bulan',
          color: AppColors.info,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.warning_amber_outlined,
          label: 'Laporan Aset Bermasalah',
          subtitle: 'Aset dengan kondisi rusak atau hilang',
          color: AppColors.warning,
          onTap: () {},
        ),
      ],
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) {
    final namaCtrl = TextEditingController(
      text: existing?['nama'] as String? ?? '',
    );
    final kodeCtrl = TextEditingController(
      text: existing?['kode'] as String? ?? '',
    );
    final lokasiCtrl = TextEditingController(
      text: existing?['lokasi'] as String? ?? '',
    );
    final tahunCtrl = TextEditingController(
      text: existing?['tahun'] as String? ?? '',
    );
    String selectedKategori = existing?['kategori'] as String? ?? 'Gedung';
    String selectedKondisi = existing?['kondisi'] as String? ?? 'Baik';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing == null ? 'Tambah Aset' : 'Edit Aset',
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogField(label: 'Nama Aset', controller: namaCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Kode Aset', controller: kodeCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Lokasi', controller: lokasiCtrl),
                const SizedBox(height: 12),
                _DialogField(label: 'Tahun Pengadaan', controller: tahunCtrl),
                const SizedBox(height: 12),
                const Text('Kategori', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedKategori,
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
                  items:
                      [
                            'Gedung',
                            'Elektronik',
                            'Furnitur',
                            'Kendaraan',
                            'Lainnya',
                          ]
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                  onChanged: (v) =>
                      setStateD(() => selectedKategori = v ?? selectedKategori),
                ),
                const SizedBox(height: 12),
                const Text('Kondisi', style: AppTextStyles.label),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedKondisi,
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
                  items: ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Hilang']
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) =>
                      setStateD(() => selectedKondisi = v ?? selectedKondisi),
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
                setState(() {
                  if (existing == null) {
                    _inventarisList.add({
                      'nama': namaCtrl.text,
                      'kode': kodeCtrl.text,
                      'kategori': selectedKategori,
                      'kondisi': selectedKondisi,
                      'lokasi': lokasiCtrl.text,
                      'tahun': tahunCtrl.text,
                    });
                  } else {
                    existing['nama'] = namaCtrl.text;
                    existing['kode'] = kodeCtrl.text;
                    existing['kategori'] = selectedKategori;
                    existing['kondisi'] = selectedKondisi;
                    existing['lokasi'] = lokasiCtrl.text;
                    existing['tahun'] = tahunCtrl.text;
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
        title: const Text('Hapus Aset', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['nama']}"?',
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
              setState(() => _inventarisList.remove(item));
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

// ── Admin Aset Tile ───────────────────────────────────────────────────────────
class _AdminAsetTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminAsetTile({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  Color _kondisiColor(String c) {
    switch (c) {
      case 'Baik':
        return AppColors.success;
      case 'Rusak Ringan':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  IconData _kategoriIcon(String k) {
    switch (k) {
      case 'Gedung':
        return Icons.business;
      case 'Elektronik':
        return Icons.computer;
      case 'Furnitur':
        return Icons.chair;
      case 'Kendaraan':
        return Icons.directions_car;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kondisi = data['kondisi'] as String;
    final kategori = data['kategori'] as String;
    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _kategoriIcon(kategori),
              color: AppColors.primary,
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
                  '${data['kode']} • ${data['lokasi']}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(label: kondisi, color: _kondisiColor(kondisi)),
                    const SizedBox(width: 6),
                    Text(
                      data['kategori'] as String,
                      style: AppTextStyles.caption,
                    ),
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

// ── Summary Cell ──────────────────────────────────────────────────────────────
class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Category Bar ──────────────────────────────────────────────────────────────
class _CategoryBar extends StatelessWidget {
  final String kategori;
  final int count;
  final int total;
  final Color color;
  const _CategoryBar({
    required this.kategori,
    required this.count,
    required this.total,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return NeuCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kategori, style: AppTextStyles.h4),
              Text(
                '$count item${count > 1 ? 's' : ''}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Laporan Tile ──────────────────────────────────────────────────────────────
class _LaporanTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _LaporanTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.h4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
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
