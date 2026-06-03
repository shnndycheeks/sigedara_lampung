import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';

class AdminAsetScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AdminAsetScreen({super.key, this.onBack});

  @override
  State<AdminAsetScreen> createState() => _AdminAsetScreenState();
}

class _AdminAsetScreenState extends State<AdminAsetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _inventarisList = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAset();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAset() async {
    try {
      final data = await DatabaseService.getAssets();

      final mapped = data.map((a) {
        return {
          'id': a['id'],
          'nama': a['nama'] ?? '-',
          'kode': a['kode_asset'] ?? a['kode'] ?? '-',
          'kategori': _formatKategori(a['kategori']),
          'kondisi': _formatKondisi(a['kondisi']),
          'status': (a['status'] ?? 'tersedia').toString().toLowerCase(),
          'lokasi': a['lokasi'] ?? '-',
          'deskripsi': a['deskripsi'] ?? '-',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _inventarisList = mapped;
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

  String _formatKategori(dynamic value) {
    final text = (value ?? 'Elektronik').toString().trim();
    if (text.isEmpty) return 'Elektronik';

    final lower = text.toLowerCase();

    if (lower == 'furniture' || lower == 'furnitur') return 'Furnitur';
    if (lower == 'elektronik') return 'Elektronik';
    if (lower == 'kendaraan') return 'Kendaraan';
    if (lower == 'gedung') return 'Gedung';
    if (lower == 'peralatan') return 'Peralatan';
    if (lower == 'lainnya') return 'Lainnya';

    return text;
  }

  String _formatKondisi(dynamic value) {
    final text = (value ?? 'baik').toString().trim().toLowerCase();

    if (text == 'sangat baik') return 'Sangat Baik';
    if (text == 'baik') return 'Baik';
    if (text == 'cukup') return 'Cukup';
    if (text == 'rusak' || text == 'rusak berat') return 'Rusak';
    if (text == 'rusak ringan') return 'Rusak Ringan';
    if (text == 'hilang') return 'Hilang';

    return 'Baik';
  }

  String _kondisiToDb(String kondisi) {
    switch (kondisi) {
      case 'Sangat Baik':
        return 'sangat baik';
      case 'Baik':
        return 'baik';
      case 'Cukup':
        return 'cukup';
      case 'Rusak Ringan':
        return 'rusak ringan';
      case 'Rusak':
        return 'rusak';
      case 'Hilang':
        return 'hilang';
      default:
        return 'baik';
    }
  }

  String _kategoriToDb(String kategori) {
    switch (kategori) {
      case 'Furnitur':
        return 'Furniture';
      default:
        return kategori;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _inventarisList;

    final q = _searchQuery.toLowerCase();

    return _inventarisList.where((a) {
      return (a['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (a['kode'] ?? '').toString().toLowerCase().contains(q) ||
          (a['lokasi'] ?? '').toString().toLowerCase().contains(q) ||
          (a['kategori'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  int get _totalAset => _inventarisList.length;

  int get _asetBaik {
    return _inventarisList.where((a) {
      final kondisi = a['kondisi'].toString();
      return kondisi == 'Baik' || kondisi == 'Sangat Baik';
    }).length;
  }

  int get _asetBermasalah {
    return _inventarisList.where((a) {
      final kondisi = a['kondisi'].toString();
      return kondisi == 'Cukup' ||
          kondisi == 'Rusak Ringan' ||
          kondisi == 'Rusak' ||
          kondisi == 'Hilang';
    }).length;
  }

  int get _asetTersedia {
    return _inventarisList.where((a) => a['status'] == 'tersedia').length;
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            widget.onBack?.call();
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

  Widget _buildInventarisTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadAset,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            SizedBox(height: 120),
            EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal memuat aset',
              subtitle: 'Cek koneksi atau policy Supabase',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Cari nama aset, kode, lokasi...',
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
                      borderRadius: BorderRadius.circular(12),
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAset,
            child: _filtered.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aset tidak ditemukan',
                        subtitle: 'Coba gunakan kata kunci lain',
                      ),
                    ],
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
        ),
      ],
    );
  }

  Widget _buildRingkasanTab() {
    final Map<String, int> byKategori = {};
    final Map<String, int> byKondisi = {};

    for (final a in _inventarisList) {
      final k = a['kategori'].toString();
      final c = a['kondisi'].toString();
      byKategori[k] = (byKategori[k] ?? 0) + 1;
      byKondisi[c] = (byKondisi[c] ?? 0) + 1;
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAset,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeuCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCell(
                    value: '$_totalAset',
                    label: 'Total Aset',
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryCell(
                    value: '$_asetBaik',
                    label: 'Kondisi Baik',
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _SummaryCell(
                    value: '$_asetBermasalah',
                    label: 'Bermasalah',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeuCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCell(
                    value: '$_asetTersedia',
                    label: 'Tersedia',
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _SummaryCell(
                    value: '${_totalAset - _asetTersedia}',
                    label: 'Tidak Tersedia',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Distribusi Kategori', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          if (byKategori.isEmpty)
            const EmptyState(
              icon: Icons.category_outlined,
              title: 'Belum ada kategori',
              subtitle: 'Data kategori aset akan muncul di sini',
            )
          else
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
          if (byKondisi.isEmpty)
            const EmptyState(
              icon: Icons.health_and_safety_outlined,
              title: 'Belum ada kondisi',
              subtitle: 'Data kondisi aset akan muncul di sini',
            )
          else
            ...byKondisi.entries.map((e) {
              Color c;
              switch (e.key) {
                case 'Sangat Baik':
                case 'Baik':
                  c = AppColors.success;
                  break;
                case 'Cukup':
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
      ),
    );
  }

  Widget _buildLaporanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LaporanTile(
          icon: Icons.picture_as_pdf,
          label: 'Laporan Inventaris Lengkap',
          subtitle: 'Semua data aset dalam format PDF',
          color: AppColors.error,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur ekspor dalam pengembangan')),
          ),
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.table_chart_outlined,
          label: 'Ekspor Data ke Excel',
          subtitle: 'Download spreadsheet inventaris',
          color: AppColors.success,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur ekspor dalam pengembangan')),
          ),
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.bar_chart,
          label: 'Rekap Peminjaman Aset',
          subtitle: 'Statistik penggunaan aset per bulan',
          color: AppColors.info,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur ekspor dalam pengembangan')),
          ),
        ),
        const SizedBox(height: 10),
        _LaporanTile(
          icon: Icons.warning_amber_outlined,
          label: 'Laporan Aset Bermasalah',
          subtitle: 'Aset dengan kondisi rusak atau hilang',
          color: AppColors.warning,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur ekspor dalam pengembangan')),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    Map<String, dynamic>? existing,
  ) async {
    final namaCtrl = TextEditingController(
      text: existing?['nama']?.toString() ?? '',
    );
    final kodeCtrl = TextEditingController(
      text: existing?['kode']?.toString() ?? '',
    );
    final lokasiCtrl = TextEditingController(
      text: existing?['lokasi']?.toString() ?? '',
    );

    String selectedKategori = existing?['kategori']?.toString() ?? 'Elektronik';
    String selectedKondisi = existing?['kondisi']?.toString() ?? 'Baik';

    final kategoriList = [
      'Elektronik',
      'Furnitur',
      'Kendaraan',
      'Gedung',
      'Peralatan',
      'Lainnya',
    ];

    final kondisiList = [
      'Sangat Baik',
      'Baik',
      'Cukup',
      'Rusak Ringan',
      'Rusak',
      'Hilang',
    ];

    if (!kategoriList.contains(selectedKategori)) {
      selectedKategori = 'Elektronik';
    }

    if (!kondisiList.contains(selectedKondisi)) {
      selectedKondisi = 'Baik';
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateD) {
            return AlertDialog(
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
                    const Text('Kategori', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedKategori,
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
                      items: kategoriList
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(k),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setStateD(() {
                          selectedKategori = v ?? selectedKategori;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Kondisi', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedKondisi,
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
                      items: kondisiList
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(k),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setStateD(() {
                          selectedKondisi = v ?? selectedKondisi;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final nama = namaCtrl.text.trim();
                    final kode = kodeCtrl.text.trim();
                    final lokasi = lokasiCtrl.text.trim();

                    if (nama.isEmpty || kode.isEmpty || lokasi.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama, kode, dan lokasi aset wajib diisi',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop({
                      'nama': nama,
                      'kode': kode,
                      'lokasi': lokasi,
                      'kategori': selectedKategori,
                      'kondisi': selectedKondisi,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    existing == null ? Icons.add : Icons.save_outlined,
                  ),
                  label: Text(existing == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    namaCtrl.dispose();
    kodeCtrl.dispose();
    lokasiCtrl.dispose();

    if (result == null) return;

    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      if (existing == null) {
        await DatabaseService.tambahAset(
          nama: result['nama'].toString(),
          kodeAsset: result['kode'].toString(),
          lokasi: result['lokasi'].toString(),
          kategori: _kategoriToDb(result['kategori'].toString()),
          kondisi: _kondisiToDb(result['kondisi'].toString()),
        );
      } else {
        await DatabaseService.updateAset(
          id: existing['id'].toString(),
          nama: result['nama'].toString(),
          kodeAsset: result['kode'].toString(),
          lokasi: result['lokasi'].toString(),
          kategori: _kategoriToDb(result['kategori'].toString()),
          kondisi: _kondisiToDb(result['kondisi'].toString()),
          status: existing['status']?.toString() ?? 'tersedia',
        );
      }

      await _loadAset();

      if (!mounted) return;

      _showSuccessSnack(
        existing == null
            ? 'Aset berhasil ditambahkan'
            : 'Aset berhasil diperbarui',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showErrorSnack('Gagal menyimpan aset: $e');
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Aset', style: AppTextStyles.h3),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${item['nama']}"?\n\nData akan dihapus dari Supabase.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }

      await DatabaseService.hapusAset(item['id'].toString());

      await _loadAset();

      if (!mounted) return;

      _showSuccessSnack('Aset berhasil dihapus');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showErrorSnack('Gagal menghapus aset: $e');
    }
  }
}

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
      case 'Sangat Baik':
      case 'Baik':
        return AppColors.success;
      case 'Cukup':
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
      case 'Peralatan':
        return Icons.handyman_outlined;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kondisi = data['kondisi'].toString();
    final kategori = data['kategori'].toString();

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
                Text(data['nama'].toString(), style: AppTextStyles.h4),
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
                    Flexible(
                      child: Text(
                        kategori,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                '$count item',
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

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _DialogField({
    required this.label,
    required this.controller,
  });

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