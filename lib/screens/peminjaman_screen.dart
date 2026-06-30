import 'package:flutter/material.dart';
import 'package:sigedara_lampung/screens/edit_peminjaman_gedung_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/navigation_service.dart';
import '../services/database_service.dart';

// ─── Data Info Ruangan ──────────────────────────────────────────────────────
// ─── Data Info Ruangan ──────────────────────────────────────────────────────
const Map<String, Map<String, dynamic>> kRuanganInfo = {
  'Ruang Abung': {
    'deskripsi':
        'Ruang rapat representatif untuk kegiatan koordinasi dan rapat internal.',
    'kapasitas': '30 orang',

    'fasilitas': <String>['Proyektor', 'AC', 'Whiteboard', 'Sound System'],

    'peraturan': <String>[
      'Dilarang merokok di dalam ruangan',
      'Tidak membuang sampah sembarangan',
      'Menjaga kebersihan ruangan',
      'Mengembalikan fasilitas seperti semula',
    ],

    'icon': Icons.meeting_room_rounded,
    'color': Color(0xFF1A2B5A),
  },

  'Ruang Sungkai': {
    'deskripsi':
        'Ruang pertemuan menengah untuk diskusi dan presentasi internal.',

    'kapasitas': '25 orang',

    'fasilitas': <String>['Proyektor', 'AC', 'LCD TV', 'Whiteboard'],

    'peraturan': <String>[
      'Tidak mencoret fasilitas ruangan',
      'Menjaga ketenangan ruangan',
      'Dilarang membawa benda berbahaya',
    ],

    'icon': Icons.groups_rounded,
    'color': Color(0xFF0D6B6B),
  },

  'Balai Keratun Lt. 3': {
    'deskripsi': 'Gedung aula besar untuk seminar dan kegiatan pemerintahan.',

    'kapasitas': '100 orang',

    'fasilitas': <String>[
      'Sound System',
      'AC Sentral',
      'Podium',
      'Mic Wireless',
    ],

    'peraturan': <String>[
      'Tidak merusak fasilitas aula',
      'Menjaga kebersihan area',
      'Menggunakan ruangan sesuai jadwal',
    ],

    'icon': Icons.domain_rounded,
    'color': Color(0xFF7B3F00),
  },

  'Green Arena': {
    'deskripsi': 'Area outdoor multifungsi untuk acara besar dan gathering.',

    'kapasitas': '500 orang',

    'fasilitas': <String>['Area Parkir', 'Toilet', 'Sound System Outdoor'],

    'peraturan': <String>[
      'Tidak membuang sampah sembarangan',
      'Menjaga tanaman dan area hijau',
      'Tidak merusak fasilitas umum',
    ],

    'icon': Icons.grass_rounded,
    'color': Color(0xFF1E6B2E),
  },
};

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({super.key});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _filterIndex = 0;

  bool _loadingList = true;
  String? _errorList;

  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  List<Map<String, dynamic>> _peminjamanData = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadPeminjamanSaya();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadPeminjamanSaya() async {
    setState(() {
      _loadingList = true;
      _errorList = null;
    });

    try {
      final peminjaman = await DatabaseService.getPeminjamanSaya();
      final ruangan = await DatabaseService.getRuangan();

      final Map<String, Map<String, dynamic>> ruanganById = {
        for (final r in ruangan) r['id'].toString(): r,
      };

      final List<Map<String, dynamic>> hasil = [];

      for (final item in peminjaman) {
        final tipe = (item['tipe_item'] ?? '').toString().toLowerCase();

        if (tipe != 'ruangan' && tipe != 'gedung') {
          continue;
        }

        final itemId = (item['item_id'] ?? '').toString();
        final ruang = ruanganById[itemId];

        if (ruang == null) {
          continue;
        }

        hasil.add({
          'id': item['id'],
          'item_id': item['item_id'],

          // DATA RUANGAN
          'ruangan': _namaRuangan(ruang, itemId),

          // TAMBAHAN INI
          'dataRuangan': ruang,

          'gambar_1': ruang['gambar_1'],
          'gambar_2': ruang['gambar_2'],
          'gambar_3': ruang['gambar_3'],
          'deskripsi': ruang['deskripsi'],
          'kapasitas': ruang['kapasitas'],
          'fasilitas': ruang['fasilitas'],
          'lokasi': ruang['lokasi'],

          // DATA PEMINJAMAN
          'peminjam': 'Saya',
          'tujuan': _ambilTujuan(item['keperluan']),
          'tanggal': _formatTanggal(item['tanggal_mulai']),
          'waktu': _formatWaktuRange(
            item['tanggal_mulai'],
            item['tanggal_selesai'],
          ),
          'peserta':
              int.tryParse((item['peserta'] ?? '').toString()) ??
              _ambilPeserta(item['keperluan']),
          'status': _formatStatus(item['status']),
          'statusColor': _statusColorStatic(_formatStatus(item['status'])),
          'catatan_admin': item['catatan_admin'],
          'created_at': item['created_at'],
          'tanggal_mulai': item['tanggal_mulai'],
          'tanggal_selesai': item['tanggal_selesai'],
        });
      }

      if (!mounted) return;

      setState(() {
        _peminjamanData = hasil;
        _loadingList = false;
        _errorList = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingList = false;
        _errorList = e.toString();
      });
    }
  }

  static String _namaRuangan(Map<String, dynamic>? data, String fallback) {
    if (data == null) return fallback;

    return (data['nama'] ??
            data['nama_ruangan'] ??
            data['ruangan'] ??
            data['name'] ??
            fallback)
        .toString();
  }

  static String _ambilTujuan(dynamic value) {
    final text = (value ?? '-').toString();

    if (text.contains('|')) {
      return text.split('|').first.trim();
    }

    return text.trim().isEmpty ? '-' : text.trim();
  }

  static int _ambilPeserta(dynamic value) {
    final text = (value ?? '').toString();

    final regex = RegExp(r'Peserta:\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(text);

    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? '0') ?? 0;
  }

  static String _formatStatus(dynamic value) {
    final status = (value ?? 'pending').toString().toLowerCase();

    if (status == 'disetujui' ||
        status == 'approved' ||
        status == 'approve' ||
        status == 'accepted') {
      return 'Disetujui';
    }

    if (status == 'ditolak' ||
        status == 'rejected' ||
        status == 'reject' ||
        status == 'declined') {
      return 'Ditolak';
    }

    return 'Menunggu';
  }

  static Color _statusColorStatic(String status) {
    switch (status) {
      case 'Disetujui':
        return AppColors.success;
      case 'Ditolak':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _formatTanggal(dynamic value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const bulan = [
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

    return '${hari[date.weekday - 1]}, ${date.day} ${bulan[date.month]} ${date.year}';
  }

  static String _formatJam(dynamic value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatWaktuRange(dynamic mulai, dynamic selesai) {
    return '${_formatJam(mulai)} - ${_formatJam(selesai)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Peminjaman Gedung',
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
            } else {
              NavigationService.goHomeUser?.call();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPeminjamanSaya,
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KalenderGedungScreen()),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Daftar Permintaan'),
            Tab(text: 'Ajukan Pinjam'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildListTab(), _buildFormTab()],
      ),
    );
  }

  Widget _buildListTab() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorList != null) {
      return RefreshIndicator(
        onRefresh: _loadPeminjamanSaya,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 120),
            EmptyState(
              icon: Icons.error_outline,
              title: 'Gagal memuat permintaan',
              subtitle: _errorList!,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterIndex == i
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    boxShadow: _filterIndex == i
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
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
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPeminjamanSaya,
            child: _filterIndex == 0
                ? _buildGroupedList()
                : _buildFilteredList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedList() {
    final groups = [
      {
        'label': 'Menunggu',
        'color': AppColors.warning,
        'icon': Icons.hourglass_top_rounded,
      },
      {
        'label': 'Disetujui',
        'color': AppColors.success,
        'icon': Icons.check_circle_rounded,
      },
      {
        'label': 'Ditolak',
        'color': AppColors.error,
        'icon': Icons.cancel_rounded,
      },
    ];

    final List<Widget> sections = [];

    for (final g in groups) {
      final items = _peminjamanData
          .where((d) => d['status'] == g['label'])
          .toList();

      if (items.isEmpty) continue;

      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              Icon(g['icon'] as IconData, size: 14, color: g['color'] as Color),
              const SizedBox(width: 6),
              Text(
                g['label'] as String,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: g['color'] as Color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: (g['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: g['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (int i = 0; i < items.length; i++) {
        sections.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              i < items.length - 1 ? 10 : 0,
            ),
            child: _PeminjamanTile(
              data: items[i],
              onRefresh: _loadPeminjamanSaya,
            ),
          ),
        );
      }

      sections.add(const SizedBox(height: 18));
    }

    if (sections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Belum ada permintaan',
            subtitle: 'Pengajuan peminjaman gedung akan muncul di sini',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 24),
      children: sections,
    );
  }

  Widget _buildFilteredList() {
    final filtered = _peminjamanData
        .where((d) => d['status'] == _filters[_filterIndex])
        .toList();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          EmptyState(
            icon: Icons.inbox_rounded,
            title: 'Tidak ada data ${_filters[_filterIndex]}',
            subtitle: 'Coba tarik ke bawah untuk refresh',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _PeminjamanTile(data: filtered[i], onRefresh: _loadPeminjamanSaya),
    );
  }

  Widget _buildFormTab() {
    return _FormPinjamanGedung(
      onSuccess: () async {
        await _loadPeminjamanSaya();
        _tab.animateTo(0);
      },
    );
  }
}

class _PeminjamanTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onRefresh;

  const _PeminjamanTile({required this.data, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPeminjamanScreen(data: data)),
        );

        if (result == true) {
          onRefresh?.call();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Data peminjaman berhasil diperbarui'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((data['gambar_1'] ?? '').toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data['gambar_1'].toString(),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          if ((data['gambar_1'] ?? '').toString().isNotEmpty)
            const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['ruangan'] as String, style: AppTextStyles.h4),
                    Text(
                      data['peminjam'] as String,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: data['status'] as String,
                color: data['statusColor'] as Color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Text(
            data['tujuan'] as String,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: data['tanggal'] as String,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.access_time,
                label: data['waktu'] as String,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoChip(
            icon: Icons.people_outline,
            label: '${data['peserta']} peserta',
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  Color _iconColor() {
    if (icon == Icons.calendar_today_outlined) {
      return AppColors.primary;
    }

    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _iconColor()),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _FormPinjamanGedung extends StatefulWidget {
  final Future<void> Function()? onSuccess;

  const _FormPinjamanGedung({this.onSuccess});

  @override
  State<_FormPinjamanGedung> createState() => _FormPinjamanGedungState();
}

class _FormPinjamanGedungState extends State<_FormPinjamanGedung> {
  String? _selectedRuanganId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _pesertaCtrl = TextEditingController();
  final _tujuanCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingRuangan = true;

  List<Map<String, dynamic>> _ruanganList = [];

  // Jadwal terpakai per ruangan (mock data)
  static const Map<String, List<Map<String, dynamic>>> _kJadwalTerpakai = {
    'Ruang Abung': [
      {
        'tanggal': '2026-04-14',
        'mulai': '09:00',
        'selesai': '11:00',
        'kegiatan': 'Rapat Koordinasi Bagian Umum',
        'peminjam': 'Ir. Siti Nurhaliza',
      },
      {
        'tanggal': '2026-04-14',
        'mulai': '13:00',
        'selesai': '15:30',
        'kegiatan': 'Pelatihan SDM',
        'peminjam': 'Budi Santoso',
      },
      {
        'tanggal': '2026-04-15',
        'mulai': '08:00',
        'selesai': '10:00',
        'kegiatan': 'Rapat Tim IT',
        'peminjam': 'Rendi Pratama',
      },
    ],
    'Ruang Sungkai': [
      {
        'tanggal': '2026-04-14',
        'mulai': '10:00',
        'selesai': '12:00',
        'kegiatan': 'Diskusi Anggaran',
        'peminjam': 'Hj. Ratna W.',
      },
      {
        'tanggal': '2026-04-15',
        'mulai': '13:00',
        'selesai': '16:00',
        'kegiatan': 'Evaluasi Kinerja',
        'peminjam': 'Dr. Ahmad F.',
      },
    ],
    'Balai Keratun Lt. 3': [
      {
        'tanggal': '2026-04-14',
        'mulai': '08:00',
        'selesai': '17:00',
        'kegiatan': 'Seminar Nasional Pemerintahan',
        'peminjam': 'Panitia Protokol',
      },
    ],
    'R. Rapat Utama': [
      {
        'tanggal': '2026-04-14',
        'mulai': '09:00',
        'selesai': '12:00',
        'kegiatan': 'Rapat Pimpinan',
        'peminjam': 'Sekretaris Biro',
      },
      {
        'tanggal': '2026-04-15',
        'mulai': '14:00',
        'selesai': '16:00',
        'kegiatan': 'Koordinasi Lintas Bidang',
        'peminjam': 'Kepala Bagian',
      },
    ],
  };

  Map<String, dynamic>? _konflik;
  List<Map<String, String>> _slotAlternatif = [];

  @override
  void initState() {
    super.initState();
    _loadRuangan();
  }

  Future<void> _loadRuangan() async {
    try {
      final data = await DatabaseService.getRuangan();

      if (!mounted) return;

      setState(() {
        _ruanganList = data;
        _loadingRuangan = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingRuangan = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat ruangan: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _namaRuangan(Map<String, dynamic> r) {
    return (r['nama'] ??
            r['nama_ruangan'] ??
            r['ruangan'] ??
            r['name'] ??
            'Tanpa Nama')
        .toString();
  }

  String? get _selectedRuanganName {
    if (_selectedRuanganId == null) return null;

    final found = _ruanganList.where((r) {
      return r['id'].toString() == _selectedRuanganId;
    }).toList();

    if (found.isEmpty) return null;

    return _namaRuangan(found.first);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  int _parseMinutes(String s) {
    final parts = s.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatDateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _minToStr(int m) {
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  DateTime _gabungTanggalJam(DateTime tanggal, TimeOfDay jam) {
    return DateTime(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      jam.hour,
      jam.minute,
    );
  }

  void _checkKonflik() {
    final namaRuangan = _selectedRuanganName;

    if (namaRuangan == null ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      setState(() {
        _konflik = null;
        _slotAlternatif = [];
      });
      return;
    }

    final key = _formatDateKey(_selectedDate!);
    final jadwal = _kJadwalTerpakai[namaRuangan] ?? [];
    final start = _toMinutes(_startTime!);
    final end = _toMinutes(_endTime!);

    Map<String, dynamic>? found;

    for (final j in jadwal) {
      if (j['tanggal'] != key) continue;

      final jStart = _parseMinutes(j['mulai'] as String);
      final jEnd = _parseMinutes(j['selesai'] as String);

      if (start < jEnd && end > jStart) {
        found = j;
        break;
      }
    }

    List<Map<String, String>> alternatif = [];

    if (found != null) {
      final List<Map<String, dynamic>> jadwalHari =
          jadwal.where((j) => j['tanggal'] == key).toList()..sort(
            (a, b) => _parseMinutes(
              a['mulai'] as String,
            ).compareTo(_parseMinutes(b['mulai'] as String)),
          );

      final durasi = end - start;

      if (jadwalHari.isNotEmpty &&
          _parseMinutes(jadwalHari.first['mulai'] as String) - 480 >= durasi) {
        final sEnd = _parseMinutes(jadwalHari.first['mulai'] as String) - 5;
        final sStart = sEnd - durasi;

        if (sStart >= 480) {
          alternatif.add({
            'mulai': _minToStr(sStart),
            'selesai': _minToStr(sEnd),
          });
        }
      }

      for (int i = 0; i < jadwalHari.length - 1; i++) {
        final gap =
            _parseMinutes(jadwalHari[i + 1]['mulai'] as String) -
            _parseMinutes(jadwalHari[i]['selesai'] as String);

        if (gap >= durasi) {
          final sStart = _parseMinutes(jadwalHari[i]['selesai'] as String) + 5;

          alternatif.add({
            'mulai': _minToStr(sStart),
            'selesai': _minToStr(sStart + durasi),
          });
        }
      }

      if (jadwalHari.isNotEmpty) {
        final sStart = _parseMinutes(jadwalHari.last['selesai'] as String) + 5;

        if (sStart + durasi <= 1200) {
          alternatif.add({
            'mulai': _minToStr(sStart),
            'selesai': _minToStr(sStart + durasi),
          });
        }
      }

      if (alternatif.isEmpty) {
        alternatif.add({
          'mulai': '08:00',
          'selesai': _minToStr(480 + durasi),
          'besok': 'true',
        });
      }
    }

    setState(() {
      _konflik = found;
      _slotAlternatif = alternatif.take(3).toList();
    });
  }

  Future<void> _ajukanPeminjaman() async {
    if (_loading) return;

    final namaRuangan = _selectedRuanganName;

    if (_selectedRuanganId == null ||
        namaRuangan == null ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        _pesertaCtrl.text.trim().isEmpty ||
        _tujuanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field bertanda * wajib diisi')),
      );
      return;
    }

    if (_konflik != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruangan sedang terpakai. Pilih slot waktu lain dulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final jumlahPeserta = int.tryParse(_pesertaCtrl.text.trim());

    if (jumlahPeserta == null || jumlahPeserta <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah peserta harus berupa angka')),
      );
      return;
    }

    final mulai = _gabungTanggalJam(_selectedDate!, _startTime!);
    final selesai = _gabungTanggalJam(_selectedDate!, _endTime!);

    if (!selesai.isAfter(mulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus lebih besar dari jam mulai'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final keperluanLengkap = [
        _tujuanCtrl.text.trim(),
        'Peserta: ${_pesertaCtrl.text.trim()}',
        'Ruangan: $namaRuangan',
        if (_keteranganCtrl.text.trim().isNotEmpty)
          'Keterangan: ${_keteranganCtrl.text.trim()}',
      ].join(' | ');

      await DatabaseService.ajukanPeminjamanGedung(
        ruanganId: _selectedRuanganId!,
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
        keperluan: keperluanLengkap,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _selectedRuanganId = null;
        _selectedDate = null;
        _startTime = null;
        _endTime = null;
        _konflik = null;
        _slotAlternatif = [];
      });

      _pesertaCtrl.clear();
      _tujuanCtrl.clear();
      _keteranganCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permintaan berhasil diajukan ke Supabase!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await widget.onSuccess?.call();
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
    _pesertaCtrl.dispose();
    _tujuanCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Form Pengajuan Peminjaman',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _FormLabel('Pilih Ruangan *'),
                const SizedBox(height: 6),

                if (_loadingRuangan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        SizedBox(width: 12),
                        Text('Memuat data ruangan...'),
                      ],
                    ),
                  )
                else if (_ruanganList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'Belum ada data ruangan di Supabase',
                      style: TextStyle(color: AppColors.error),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRuanganId,
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
                      prefixIcon: const Icon(
                        Icons.meeting_room_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    hint: Text(
                      'Pilih ruangan dari Supabase',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                    items: _ruanganList.map((r) {
                      final id = r['id'].toString();
                      final nama = _namaRuangan(r);

                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          nama,
                          style: AppTextStyles.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedRuanganId = v);
                      _checkKonflik();
                    },
                  ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _selectedRuanganId != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: RuanganInfoCard(
                            dataRuangan: _ruanganList.firstWhere(
                              (e) => e['id'].toString() == _selectedRuanganId,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                _FormLabel('Tanggal Kegiatan *'),
                const SizedBox(height: 6),
                GestureDetector(
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

                    if (d != null) {
                      setState(() => _selectedDate = d);
                      _checkKonflik();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Pilih tanggal kegiatan',
                          style: _selectedDate != null
                              ? AppTextStyles.body
                              : AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel('Jam Mulai *'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 8,
                                  minute: 0,
                                ),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );

                              if (t != null) {
                                setState(() => _startTime = t);
                                _checkKonflik();
                              }
                            },
                            child: _TimeField(time: _startTime),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel('Jam Selesai *'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 10,
                                  minute: 0,
                                ),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );

                              if (t != null) {
                                setState(() => _endTime = t);
                                _checkKonflik();
                              }
                            },
                            child: _TimeField(time: _endTime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: _konflik != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _KonflikBanner(
                            konflik: _konflik!,
                            slotAlternatif: _slotAlternatif,
                            onPilihSlot: (mulai, selesai) {
                              final mParts = mulai.split(':');
                              final sParts = selesai.split(':');

                              setState(() {
                                _startTime = TimeOfDay(
                                  hour: int.parse(mParts[0]),
                                  minute: int.parse(mParts[1]),
                                );
                                _endTime = TimeOfDay(
                                  hour: int.parse(sParts[0]),
                                  minute: int.parse(sParts[1]),
                                );
                              });

                              _checkKonflik();
                            },
                          ),
                        )
                      : (_startTime != null &&
                                _endTime != null &&
                                _selectedRuanganId != null &&
                                _selectedDate != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.success.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ruangan tersedia pada waktu yang dipilih',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                ),

                const SizedBox(height: 16),

                _FormLabel('Jumlah Peserta *'),
                const SizedBox(height: 6),
                AppTextField(
                  hint: 'Masukkan jumlah peserta',
                  prefixIcon: Icons.people_outline,
                  controller: _pesertaCtrl,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                _FormLabel('Tujuan / Nama Kegiatan *'),
                const SizedBox(height: 6),
                AppTextField(
                  hint: 'Tulis tujuan penggunaan ruangan',
                  prefixIcon: Icons.description_outlined,
                  controller: _tujuanCtrl,
                ),

                const SizedBox(height: 16),

                _FormLabel('Keterangan Tambahan'),
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
                    label: 'Ajukan Permintaan',
                    icon: Icons.send_outlined,
                    isLoading: _loading,
                    onPressed: _ajukanPeminjaman,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
  );
}

class _TimeField extends StatelessWidget {
  final TimeOfDay? time;
  const _TimeField({this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            time != null
                ? '${time!.hour.toString().padLeft(2, '0')}.${time!.minute.toString().padLeft(2, '0')}'
                : 'Pilih jam',
            style: time != null
                ? AppTextStyles.body.copyWith(fontSize: 13)
                : AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Detail Peminjaman Screen ---
class DetailPeminjamanScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailPeminjamanScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = data['statusColor'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Peminjaman',
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
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data['status'] == 'Disetujui'
                          ? Icons.check_circle_rounded
                          : data['status'] == 'Ditolak'
                          ? Icons.cancel_rounded
                          : Icons.pending_rounded,
                      color: statusColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['status'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nomor: PMJ-2026-0${DateTime.now().millisecond % 99 + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Room photo + description
            if (data['dataRuangan'] != null)
              RuanganInfoCard(
                dataRuangan: Map<String, dynamic>.from(data['dataRuangan']),
              ),

            const SizedBox(height: 16),

            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Peminjaman', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Ruangan',
                    value: data['ruangan'] as String,
                    icon: Icons.meeting_room_outlined,
                  ),
                  _DetailRow(
                    label: 'Peminjam',
                    value: data['peminjam'] as String,
                    icon: Icons.person_outline,
                  ),
                  _DetailRow(
                    label: 'Tujuan',
                    value: data['tujuan'] as String,
                    icon: Icons.description_outlined,
                  ),
                  _DetailRow(
                    label: 'Tanggal',
                    value: data['tanggal'] as String,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _DetailRow(
                    label: 'Waktu',
                    value: data['waktu'] as String,
                    icon: Icons.access_time,
                  ),
                  _DetailRow(
                    label: 'Peserta',
                    value: '${data['peserta']} orang',
                    icon: Icons.people_outline,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timeline approval
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riwayat Persetujuan', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _ApprovalStep(
                    label: 'Diajukan',
                    time: '07 Apr 2026 08:30',
                    done: true,
                    isFirst: true,
                  ),
                  _ApprovalStep(
                    label: 'Diterima Staf Rumah Tangga',
                    time: '07 Apr 2026 09:15',
                    done: data['status'] != 'Menunggu',
                  ),
                  _ApprovalStep(
                    label: 'Disetujui Kepala Biro',
                    time: data['status'] == 'Disetujui'
                        ? '07 Apr 2026 10:00'
                        : '—',
                    done: data['status'] == 'Disetujui',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (data['status'] == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Cabut Permintaan',
                      onPressed: () => Navigator.pop(context),
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: 'Edit',
                      icon: Icons.edit,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditPeminjamanGedungScreen(data: data),
                          ),
                        );

                        if (result == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ),
                ],
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
    this.isLast = false,
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
                width: 90,
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

class _ApprovalStep extends StatelessWidget {
  final String label, time;
  final bool done;
  final bool isFirst;
  final bool isLast;
  const _ApprovalStep({
    required this.label,
    required this.time,
    required this.done,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: done ? AppColors.success : AppColors.divider,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: done
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 12),
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: done
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.h4.copyWith(
                  color: done ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
              Text(time, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Kalender Gedung Screen ---
class KalenderGedungScreen extends StatefulWidget {
  const KalenderGedungScreen({super.key});

  @override
  State<KalenderGedungScreen> createState() => _KalenderGedungScreenState();
}

class _KalenderGedungScreenState extends State<KalenderGedungScreen> {
  DateTime _month = DateTime(2026, 4);
  String _selectedRoom = 'Ruang Abung';
  final List<String> _rooms = [
    'Ruang Abung',
    'Ruang Sungkai',
    'Balai Keratun Lt. 3',
    'Ruang Sakai',
    'R. Rapat Utama',
  ];

  // Mock booked dates
  final Map<String, List<int>> _booked = {
    'Ruang Abung': [8, 9, 12, 15, 16, 21, 22],
    'Ruang Sungkai': [7, 8, 10, 14, 17, 23],
    'Balai Keratun Lt. 3': [9, 11, 13, 18, 19, 24, 25],
    'Ruang Sakai': [8, 12, 16, 20, 26, 27, 28],
  };

  // Detail data per room per day
  final Map<String, Map<int, Map<String, String>>> _bookingDetails = {
    'Ruang Abung': {
      8: {
        'pemakai': 'Budi Santoso',
        'keperluan': 'Rapat Koordinasi',
        'durasi': '08:00 – 12:00 (4 jam)',
      },
      9: {
        'pemakai': 'Sari Dewi',
        'keperluan': 'Pelatihan Staf',
        'durasi': '09:00 – 16:00 (7 jam)',
      },
      12: {
        'pemakai': 'Rendi Pratama',
        'keperluan': 'Seminar Tahunan',
        'durasi': '08:00 – 17:00 (9 jam)',
      },
      15: {
        'pemakai': 'Hendra Putra',
        'keperluan': 'Sidang Kepegawaian',
        'durasi': '10:00 – 13:00 (3 jam)',
      },
      16: {
        'pemakai': 'Andi Wijaya',
        'keperluan': 'Workshop K3',
        'durasi': '09:00 – 15:00 (6 jam)',
      },
      21: {
        'pemakai': 'Dewi Lestari',
        'keperluan': 'Rapat Evaluasi',
        'durasi': '08:00 – 11:00 (3 jam)',
      },
      22: {
        'pemakai': 'Fajar Nugroho',
        'keperluan': 'Presentasi Proyek',
        'durasi': '13:00 – 16:00 (3 jam)',
      },
    },
    'Ruang Sungkai': {
      7: {
        'pemakai': 'Maya Putri',
        'keperluan': 'Rapat Tim IT',
        'durasi': '09:00 – 11:00 (2 jam)',
      },
      8: {
        'pemakai': 'Tono Basuki',
        'keperluan': 'Diskusi Anggaran',
        'durasi': '10:00 – 12:00 (2 jam)',
      },
      10: {
        'pemakai': 'Lina Susanti',
        'keperluan': 'Koordinasi Unit',
        'durasi': '08:00 – 10:00 (2 jam)',
      },
      14: {
        'pemakai': 'Budi Santoso',
        'keperluan': 'Review Laporan',
        'durasi': '13:00 – 15:00 (2 jam)',
      },
      17: {
        'pemakai': 'Sari Dewi',
        'keperluan': 'Rapat Mingguan',
        'durasi': '09:00 – 11:00 (2 jam)',
      },
      23: {
        'pemakai': 'Hendra Putra',
        'keperluan': 'Evaluasi Kinerja',
        'durasi': '10:00 – 13:00 (3 jam)',
      },
    },
    'Balai Keratun Lt. 3': {
      9: {
        'pemakai': 'Andi Wijaya',
        'keperluan': 'Rapat Teknis',
        'durasi': '08:00 – 10:00 (2 jam)',
      },
      11: {
        'pemakai': 'Rendi Pratama',
        'keperluan': 'Briefing Tim',
        'durasi': '09:00 – 10:30 (1.5 jam)',
      },
      13: {
        'pemakai': 'Maya Putri',
        'keperluan': 'Diskusi Perencanaan',
        'durasi': '13:00 – 15:00 (2 jam)',
      },
      18: {
        'pemakai': 'Fajar Nugroho',
        'keperluan': 'Rapat Koordinasi',
        'durasi': '10:00 – 12:00 (2 jam)',
      },
      19: {
        'pemakai': 'Dewi Lestari',
        'keperluan': 'Forum Pegawai',
        'durasi': '09:00 – 12:00 (3 jam)',
      },
      24: {
        'pemakai': 'Tono Basuki',
        'keperluan': 'Review Kontrak',
        'durasi': '13:00 – 15:00 (2 jam)',
      },
      25: {
        'pemakai': 'Lina Susanti',
        'keperluan': 'Rapat Akhir Bulan',
        'durasi': '09:00 – 11:00 (2 jam)',
      },
    },
    'Ruang Sakai': {
      8: {
        'pemakai': 'Budi Santoso',
        'keperluan': 'Pameran Produk',
        'durasi': '08:00 – 17:00 (9 jam)',
      },
      12: {
        'pemakai': 'Hendra Putra',
        'keperluan': 'Olahraga Bersama',
        'durasi': '07:00 – 09:00 (2 jam)',
      },
      16: {
        'pemakai': 'Sari Dewi',
        'keperluan': 'Acara HUT Kantor',
        'durasi': '10:00 – 15:00 (5 jam)',
      },
      20: {
        'pemakai': 'Rendi Pratama',
        'keperluan': 'Lomba Antar Unit',
        'durasi': '08:00 – 14:00 (6 jam)',
      },
      26: {
        'pemakai': 'Andi Wijaya',
        'keperluan': 'Rekreasi Pegawai',
        'durasi': '09:00 – 12:00 (3 jam)',
      },
      27: {
        'pemakai': 'Maya Putri',
        'keperluan': 'Sosialisasi Program',
        'durasi': '13:00 – 15:30 (2.5 jam)',
      },
      28: {
        'pemakai': 'Fajar Nugroho',
        'keperluan': 'Pelatihan Internal',
        'durasi': '09:00 – 16:00 (7 jam)',
      },
    },
  };

  void _showDayDetail(BuildContext context, int day, bool isBooked) {
    final Map<String, String>? detail = isBooked
        ? (_bookingDetails[_selectedRoom]?[day])
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
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBooked ? Icons.event_busy : Icons.event_available,
                color: isBooked ? AppColors.success : AppColors.info,
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
                    _selectedRoom,
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
                    'Pemakai',
                    detail['pemakai']!,
                  ),
                  const SizedBox(height: 10),
                  _dialogRow(
                    Icons.work_outline,
                    'Keperluan',
                    detail['keperluan']!,
                  ),
                  const SizedBox(height: 10),
                  _dialogRow(Icons.access_time, 'Durasi', detail['durasi']!),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ruangan sudah diboking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
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
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ruangan tersedia untuk digunakan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
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

  @override
  Widget build(BuildContext context) {
    final booked = _booked[_selectedRoom] ?? [];
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ketersediaan Ruangan',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room selector
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _rooms[i] == _selectedRoom;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoom = _rooms[i]),
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
                        _rooms[i],
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
              child: Column(
                children: [
                  // Month nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        ),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_monthName(_month.month)} ${_month.year}',
                        style: AppTextStyles.h3,
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month + 1),
                        ),
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Day headers
                  Row(
                    children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      const _LegendItem(
                        color: Colors.white,
                        borderColor: Color(0xFFE2E8F0),
                        label: 'Tersedia',
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        color: AppColors.primary,
                        borderColor: Colors.transparent,
                        label: 'Hari ini',
                      ),
                      const SizedBox(width: 16),
                      const _LegendItem(
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
      ),
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
}

// ─── Ruangan Info Card ───────────────────────────────────────────────────────
class RuanganInfoCard extends StatelessWidget {
  final Map<String, dynamic> dataRuangan;

  const RuanganInfoCard({super.key, required this.dataRuangan});

  @override
  Widget build(BuildContext context) {
    final String deskripsi = (dataRuangan['deskripsi'] ?? '').toString();

    final String gambar1 = (dataRuangan['gambar_1'] ?? '').toString();

    final String gambar2 = (dataRuangan['gambar_2'] ?? '').toString();

    final String gambar3 = (dataRuangan['gambar_3'] ?? '').toString();

    final List<String> fasilitas = (dataRuangan['fasilitas'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final List<String> peraturan = (dataRuangan['peraturan'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final Color color = AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo / Banner ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 220,
              child: PageView(
                children: [
                  if (gambar1.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Image.network(gambar1, fit: BoxFit.cover),
                    ),

                  if (gambar2.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Image.network(gambar2, fit: BoxFit.cover),
                    ),

                  if (gambar3.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Image.network(gambar3, fit: BoxFit.cover),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe_left_alt_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Geser foto',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swipe_right_alt_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // ── Description + Facilities ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deskripsi,
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.55,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fasilitas',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: fasilitas
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Peraturan',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: peraturan.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                p,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendItem({
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

// ── Konflik Banner ─────────────────────────────────────────────────────────────
class _KonflikBanner extends StatelessWidget {
  final Map<String, dynamic> konflik;
  final List<Map<String, String>> slotAlternatif;
  final void Function(String mulai, String selesai) onPilihSlot;

  const _KonflikBanner({
    required this.konflik,
    required this.slotAlternatif,
    required this.onPilihSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ruangan Sedang Terpakai!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Booking info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _KonflikRow(
                    icon: Icons.event_busy_rounded,
                    label: 'Dipakai oleh',
                    value: konflik['peminjam'] as String,
                  ),
                  const Divider(height: 12, color: AppColors.divider),
                  _KonflikRow(
                    icon: Icons.description_outlined,
                    label: 'Kegiatan',
                    value: konflik['kegiatan'] as String,
                  ),
                  const Divider(height: 12, color: AppColors.divider),
                  _KonflikRow(
                    icon: Icons.access_time,
                    label: 'Jam pakai',
                    value: '${konflik['mulai']} – ${konflik['selesai']} WIB',
                  ),
                ],
              ),
            ),
          ),
          // Slot suggestion
          if (slotAlternatif.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pilih slot waktu lain yang tersedia:',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slotAlternatif.map((slot) {
                  final isBesok = slot['besok'] == 'true';
                  return GestureDetector(
                    onTap: () => onPilihSlot(slot['mulai']!, slot['selesai']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBesok
                                ? Icons.calendar_today_outlined
                                : Icons.schedule,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isBesok
                                ? 'Besok ${slot['mulai']}–${slot['selesai']}'
                                : '${slot['mulai']} – ${slot['selesai']}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Text(
                'Tidak ada slot tersedia di hari ini. Silakan pilih tanggal lain.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _KonflikRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _KonflikRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
