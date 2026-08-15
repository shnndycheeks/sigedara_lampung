import 'package:flutter/material.dart';
import '../models/arsip_surat_model.dart';
import '../models/surat_progress_model.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/arsip_surat_service.dart';
import 'tambah_edit_surat_screen.dart';
import 'surat_detail_screen.dart';
import '../services/navigation_service.dart';
import '../services/permission_service.dart';

class AdminSuratScreen extends StatefulWidget {
  const AdminSuratScreen({super.key});

  @override
  State<AdminSuratScreen> createState() => _AdminSuratScreenState();
}

class _AdminSuratScreenState extends State<AdminSuratScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<ArsipSurat> _allArsip = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  final List<String> _kategoriFilters = ['Semua', 'Keuangan', 'Rumah Tangga', 'Tata Usaha'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _kategoriFilters.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        setState(() {});
      }
    });
    _loadArsip();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadArsip() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ArsipSuratService.getSemuaArsip();
      if (!mounted) return;
      setState(() {
        _allArsip = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ArsipSurat> _getFilteredArsip(String filterKategori) {
    List<ArsipSurat> temp = _allArsip;

    // Filter by kategori tab
    if (filterKategori != 'Semua') {
      temp = temp.where((s) => s.kategori.toLowerCase() == filterKategori.toLowerCase()).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((s) {
        final nomor = s.nomorSurat.toLowerCase();
        final judul = s.judul.toLowerCase();
        final dari = s.dari.toLowerCase();
        final kepada = s.kepada.toLowerCase();
        final urgensi = s.tingkatUrgensi.toLowerCase();
        return nomor.contains(q) || judul.contains(q) || dari.contains(q) || kepada.contains(q) || urgensi.contains(q);
      }).toList();
    }

    return temp;
  }

  Color _getUrgensiColor(String urgensi) {
    switch (urgensi.toLowerCase()) {
      case 'sangat segera':
        return AppColors.error;
      case 'segera':
        return AppColors.warning;
      case 'biasa':
      default:
        return AppColors.success;
    }
  }

  String _formatTanggal(DateTime? dt) {
    if (dt == null) return '-';
    String dua(int n) => n.toString().padLeft(2, '0');
    return '${dua(dt.day)}/${dua(dt.month)}/${dt.year}';
  }

  Future<void> _tambahArsip(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahEditSuratScreen(),
      ),
    );

    if (result == true) {
      _loadArsip();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Arsip surat berhasil disimpan.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Arsip Surat Masuk',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF475569),
            size: 20,
          ),
          onPressed: () {
            NavigationService.goHomeAdmin?.call();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: _kategoriFilters.map((f) => Tab(text: f)).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Cari nomor surat, perihal, asal, atau penerima...',
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

          // Main List View Area
          Expanded(
            child: _buildListContent(),
          ),
        ],
      ),
      floatingActionButton: PermissionService.isTu
          ? FloatingActionButton.extended(
              onPressed: () => _tambahArsip(context),
              backgroundColor: const Color(0xFFF59E0B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Arsip',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildListContent() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 120, radius: 16),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadArsip,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal Memuat Data',
              subtitle: _error!,
            ),
          ],
        ),
      );
    }

    final filtered = _getFilteredArsip(_kategoriFilters[_tabCtrl.index]);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadArsip,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            EmptyState(
              icon: Icons.drafts_outlined,
              title: _searchQuery.isEmpty ? 'Belum ada arsip surat.' : 'Belum Ada Arsip',
              subtitle: _searchQuery.isEmpty
                  ? (PermissionService.isTu
                      ? 'Tekan tombol Tambah Arsip untuk mengunggah surat pertama.'
                      : 'Belum ada arsip surat.')
                  : 'Tidak ditemukan arsip surat cocok dengan kueri pencarian.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArsip,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final arsip = filtered[index];
          return _buildArsipTile(arsip);
        },
      ),
    );
  }

  Widget _buildArsipTile(ArsipSurat arsip) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        final refresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuratDetailScreen(surat: arsip),
          ),
        );
        if (refresh == true) {
          _loadArsip();
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arsip.judul,
                  style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'No: ${arsip.nomorSurat}',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dari: ${arsip.dari}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: arsip.tingkatUrgensi.toUpperCase(),
                          color: _getUrgensiColor(arsip.tingkatUrgensi),
                        ),
                        const SizedBox(width: 6),
                        FutureBuilder<SuratProgressModel?>(
                          future: ProgressService.getProgressSurat(arsip.id),
                          builder: (context, snapshot) {
                            final percent = snapshot.data?.progressPercent ?? 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${percent.toStringAsFixed(0)}% Selesai',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      _formatTanggal(arsip.tanggalSurat),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Chevron
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 24,
          ),
        ],
      ),
    );
  }
}
