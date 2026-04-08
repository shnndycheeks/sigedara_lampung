import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import 'pengingat_screen.dart';

class AsetScreen extends StatefulWidget {
  const AsetScreen({super.key});

  @override
  State<AsetScreen> createState() => _AsetScreenState();
}

class _AsetScreenState extends State<AsetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
            NavigationService.goHomeUser?.call();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAsetDialog(context),
        backgroundColor: AppColors.primary,
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
    );
  }

  Widget _buildInventarisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            _SummaryCard(
              value: '47',
              label: 'Total Ruangan',
              icon: Icons.meeting_room_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _SummaryCard(
              value: '312',
              label: 'Total Aset',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 10),
            _SummaryCard(
              value: '8',
              label: 'Perlu Servis',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Inventaris Ruangan'),
        const SizedBox(height: 12),
        ..._inventarisData.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InventarisTile(data: d),
          ),
        ),
      ],
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

  void _showAddAsetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormTambahAset(),
    );
  }

  final List<Map<String, dynamic>> _inventarisData = [
    {
      'nama': 'Ruang Rapat A',
      'kode': 'GD-RA-001',
      'kondisi': 0.92,
      'lastServis': '15 Mar 2026',
      'nextServis': '15 Jun 2026',
      'aset': 12,
      'kondisiLabel': 'Sangat Baik',
      'kondisiColor': AppColors.success,
    },
    {
      'nama': 'Aula Utama',
      'kode': 'GD-AU-001',
      'kondisi': 0.78,
      'lastServis': '20 Feb 2026',
      'nextServis': '20 Mei 2026',
      'aset': 34,
      'kondisiLabel': 'Baik',
      'kondisiColor': AppColors.info,
    },
    {
      'nama': 'Ruang Serbaguna',
      'kode': 'GD-RS-001',
      'kondisi': 0.55,
      'lastServis': '10 Jan 2026',
      'nextServis': '10 Apr 2026',
      'aset': 28,
      'kondisiLabel': 'Cukup',
      'kondisiColor': AppColors.warning,
    },
    {
      'nama': 'Lobby Utama',
      'kode': 'GD-LB-001',
      'kondisi': 0.88,
      'lastServis': '5 Mar 2026',
      'nextServis': '5 Jun 2026',
      'aset': 15,
      'kondisiLabel': 'Baik',
      'kondisiColor': AppColors.success,
    },
    {
      'nama': 'Ruang Server',
      'kode': 'GD-SV-001',
      'kondisi': 0.96,
      'lastServis': '1 Apr 2026',
      'nextServis': '1 Jul 2026',
      'aset': 8,
      'kondisiLabel': 'Sangat Baik',
      'kondisiColor': AppColors.success,
    },
  ];

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
                  Icons.meeting_room_outlined,
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
                      'Kode: ${data['kode']} • ${data['aset']} aset',
                      style: AppTextStyles.caption,
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
                Icons.build_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Servis: ${data['nextServis']}',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kondisi circle
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
                    label: 'Total Aset',
                    value: '${data['aset']} item',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _Row(
                    label: 'Servis Terakhir',
                    value: data['lastServis'] as String,
                    icon: Icons.history,
                  ),
                  _Row(
                    label: 'Servis Berikut',
                    value: data['nextServis'] as String,
                    icon: Icons.schedule,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Daftar aset dummy
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Daftar Perabot & Aset'),
                  const SizedBox(height: 12),
                  ..._asetItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
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

  static const List<String> _asetItems = [
    'Meja Rapat (8 unit)',
    'Kursi (24 unit)',
    'AC Split 1.5 PK (2 unit)',
    'LCD Proyektor (1 unit)',
    'Whiteboard (1 unit)',
    'Telepon PABX (1 unit)',
  ];
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

class _FormTambahAset extends StatelessWidget {
  const _FormTambahAset();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text('Tambah Aset Baru', style: AppTextStyles.h2),
            const SizedBox(height: 20),
            const AppTextField(
              hint: 'Nama aset',
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 12),
            const AppTextField(
              hint: 'Kode / nomor aset',
              prefixIcon: Icons.qr_code_outlined,
            ),
            const SizedBox(height: 12),
            const AppTextField(
              hint: 'Lokasi / ruangan',
              prefixIcon: Icons.place_outlined,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Simpan Aset',
                icon: Icons.save_outlined,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
