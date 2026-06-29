import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/database_service.dart';
import 'pengingat_screen.dart';

class AsetScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AsetScreen({super.key, this.onBack});

  @override
  State<AsetScreen> createState() => _AsetScreenState();
}

class _AsetScreenState extends State<AsetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool _loadingAset = true;
  String? _errorAset;
  List<Map<String, dynamic>> _inventarisData = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAset();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAset() async {
    try {
      final data = await DatabaseService.getAssets();

      final mapped = data.map((a) {
        final kondisiText = (a['kondisi'] ?? 'baik').toString().toLowerCase();
        final statusText = (a['status'] ?? 'tersedia').toString().toLowerCase();

        double kondisiValue;
        String kondisiLabel;
        Color kondisiColor;

        if (kondisiText == 'sangat baik') {
          kondisiValue = 0.96;
          kondisiLabel = 'Sangat Baik';
          kondisiColor = AppColors.success;
        } else if (kondisiText == 'baik') {
          kondisiValue = 0.85;
          kondisiLabel = 'Baik';
          kondisiColor = AppColors.success;
        } else if (kondisiText == 'cukup') {
          kondisiValue = 0.60;
          kondisiLabel = 'Cukup';
          kondisiColor = AppColors.warning;
        } else if (kondisiText == 'rusak' || kondisiText == 'rusak berat') {
          kondisiValue = 0.30;
          kondisiLabel = 'Rusak';
          kondisiColor = AppColors.error;
        } else if (kondisiText == 'rusak ringan') {
          kondisiValue = 0.45;
          kondisiLabel = 'Rusak Ringan';
          kondisiColor = AppColors.warning;
        } else if (kondisiText == 'hilang') {
          kondisiValue = 0.10;
          kondisiLabel = 'Hilang';
          kondisiColor = AppColors.error;
        } else {
          kondisiValue = 0.75;
          kondisiLabel = kondisiText.isEmpty ? 'Baik' : kondisiText;
          kondisiColor = AppColors.info;
        }

        return {
          'id': a['id'],
          'nama': a['nama'] ?? '-',
          'kode': a['kode_asset'] ?? a['kode'] ?? '-',
          'kategori': a['kategori'] ?? '-',
          'lokasi': a['lokasi'] ?? '-',
          'deskripsi': a['deskripsi'] ?? '-',
          'status': statusText,
          'kondisi': kondisiValue,
          'lastServis': '-',
          'nextServis': '-',
          'aset': 1,
          'kondisiLabel': kondisiLabel,
          'kondisiColor': kondisiColor,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _inventarisData = mapped;
        _loadingAset = false;
        _errorAset = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingAset = false;
        _errorAset = e.toString();
      });
    }
  }

  int get _totalAset => _inventarisData.length;

  int get _asetTersedia {
    return _inventarisData.where((a) => a['status'] == 'tersedia').length;
  }

  int get _asetPerluServis {
    return _inventarisData.where((a) {
      final kondisi = a['kondisi'] as double;
      return kondisi < 0.65;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Aset'),
        backgroundColor: AppColors.primary,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengingatScreen()),
            ),
            tooltip: 'Pengingat',
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
            Tab(text: 'Inventaris'),
            Tab(text: 'Kendaraan'),
            Tab(text: 'Pengingat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildInventarisTab(),
          _buildMaintenanceTab(),
          const PengingatScreen(),
        ],
      ),
    );
  }

  Widget _buildInventarisTab() {
    if (_loadingAset) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorAset != null) {
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

    return RefreshIndicator(
      onRefresh: _loadAset,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _SummaryCard(
                value: _asetTersedia.toString(),
                label: 'Tersedia',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                value: _totalAset.toString(),
                label: 'Total Aset',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                value: _asetPerluServis.toString(),
                label: 'Perlu Servis',
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Inventaris Aset'),
          const SizedBox(height: 12),
          if (_inventarisData.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Belum ada aset',
                subtitle: 'Data aset dari Supabase akan muncul di sini',
              ),
            )
          else
            ..._inventarisData.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InventarisTile(data: d),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Log Maintenance Kendaraan'),
        const SizedBox(height: 12),
        ..._maintenanceLog.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MaintenanceTile(data: d),
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _maintenanceLog = [
    {
      'kendaraan': 'Toyota Innova - B 1234 XY',
      'jenis': 'Ganti Oli & Filter',
      'tanggal': '5 Mar 2026',
      'km': '45.200 km',
      'biaya': 'Rp 850.000',
      'bengkel': 'Bengkel Resmi Auto2000',
      'status': 'Selesai',
      'statusColor': AppColors.success,
    },
    {
      'kendaraan': 'Honda CRV - B 5678 AB',
      'jenis': 'Servis Rutin 40.000 km',
      'tanggal': '12 Mar 2026',
      'km': '40.000 km',
      'biaya': 'Rp 2.100.000',
      'bengkel': 'AHASS Honda Lampung',
      'status': 'Selesai',
      'statusColor': AppColors.success,
    },
    {
      'kendaraan': 'Toyota Hiace - B 3456 CD',
      'jenis': 'Perbaikan Rem',
      'tanggal': '10 Apr 2026',
      'km': '58.700 km',
      'biaya': 'Rp 1.500.000',
      'bengkel': 'Bengkel Karya Mandiri',
      'status': 'Berlangsung',
      'statusColor': AppColors.warning,
    },
    {
      'kendaraan': 'Mitsubishi Pajero - B 9999 ZZ',
      'jenis': 'Ganti Ban Belakang',
      'tanggal': '28 Mar 2026',
      'km': '32.100 km',
      'biaya': 'Rp 3.200.000',
      'bengkel': 'Bridgestone Service',
      'status': 'Selesai',
      'statusColor': AppColors.success,
    },
  ];
}

class _SummaryCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventarisTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InventarisTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final double kondisi = data['kondisi'] as double;
    final Color kondisiColor = data['kondisiColor'] as Color;
    final String kategori = data['kategori']?.toString() ?? '-';
    final String lokasi = data['lokasi']?.toString() ?? '-';

    return NeuCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DetailInventarisScreen(data: data)),
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
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'] as String, style: AppTextStyles.h4),
                    Text(
                      'Kode: ${data['kode']} • $kategori',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      'Lokasi: $lokasi',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: data['kondisiLabel'] as String,
                color: kondisiColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Kondisi:', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: kondisi,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(kondisiColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(kondisi * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kondisiColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Status: ${data['status']}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailInventarisScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DetailInventarisScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final double kondisi = data['kondisi'] as double;
    final Color kondisiColor = data['kondisiColor'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(data['nama'] as String),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            NeuCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: kondisi,
                              strokeWidth: 8,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kondisiColor,
                              ),
                            ),
                            Text(
                              '${(kondisi * 100).round()}%',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kondisiColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nama'] as String,
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode: ${data['kode']}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 8),
                            StatusBadge(
                              label: data['kondisiLabel'] as String,
                              color: kondisiColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Aset', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _Row(
                    label: 'Kategori',
                    value: data['kategori'] as String,
                    icon: Icons.category_outlined,
                  ),
                  _Row(
                    label: 'Lokasi',
                    value: data['lokasi'] as String,
                    icon: Icons.place_outlined,
                  ),
                  _Row(
                    label: 'Status',
                    value: data['status'] as String,
                    icon: Icons.check_circle_outline,
                  ),
                  _Row(
                    label: 'Deskripsi',
                    value: data['deskripsi'] as String,
                    icon: Icons.notes_outlined,
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
                  const SectionHeader(title: 'Catatan'),
                  const SizedBox(height: 12),
                  Text(
                    'Data ini hanya dapat dilihat oleh pegawai. Perubahan data aset dilakukan oleh admin.',
                    style: AppTextStyles.bodySmall,
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

class _Row extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isLast;

  const _Row({
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
                width: 110,
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

class _MaintenanceTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MaintenanceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = data['statusColor'] as Color;

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.build_outlined, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['jenis'] as String, style: AppTextStyles.h4),
                    Text(
                      data['kendaraan'] as String,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: data['status'] as String, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                icon: Icons.calendar_today_outlined,
                label: data['tanggal'] as String,
              ),
              const SizedBox(width: 12),
              _Chip(icon: Icons.speed_outlined, label: data['km'] as String),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Chip(icon: Icons.attach_money, label: data['biaya'] as String),
              const SizedBox(width: 12),
              _Chip(
                icon: Icons.store_outlined,
                label: data['bengkel'] as String,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  Color _iconColor() {
    if (icon == Icons.calendar_today_outlined) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _iconColor()),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}