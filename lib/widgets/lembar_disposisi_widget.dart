import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/arsip_surat_model.dart';
import '../models/disposisi_model.dart';

String _formatTanggalIndo(DateTime? dt) {
  if (dt == null) return '-';
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
}

Map<String, String> getSignatureDetailsFor(String? rawJabatan) {
  final jabatan = (rawJabatan ?? '').toLowerCase().trim();

  if (jabatan.contains('tata usaha') || jabatan.contains('tu')) {
    return {
      'title': 'KABAG. TATA USAHA',
      'nama': 'H. BENNY DARYALIS, S.H., M.H.',
      'pangkat': 'Pembina Tk. I',
      'nip': 'NIP. 19720315 199803 1 004',
      'ttd_asset': 'assets/signatures/ttd_kabag_tu.png',
    };
  } else if (jabatan.contains('rumah tangga') || jabatan.contains('rt')) {
    return {
      'title': 'KABAG. RUMAH TANGGA',
      'nama': 'ALVIRDIAN OKTAFIANUS, S.E., S.T., M.M.',
      'pangkat': 'Pembina',
      'nip': 'NIP. 19751004 201001 1 002',
      'ttd_asset': 'assets/signatures/ttd_kabag_rt.png',
    };
  } else if (jabatan.contains('administrasi') || jabatan.contains('aset')) {
    return {
      'title': 'KABAG. ADMINISTRASI DAN ASET',
      'nama': 'DEDI AFRIZAL, S.E., M.Si.',
      'pangkat': 'Pembina',
      'nip': 'NIP. 19780812 200501 1 008',
      'ttd_asset': 'assets/signatures/ttd_kabag_aset.png',
    };
  } else if (jabatan.contains('sespri')) {
    return {
      'title': 'SESPRI KEPALA BIRO UMUM',
      'nama': '',
      'pangkat': 'Penata',
      'nip': 'NIP. 19910520 201402 1 001',
      'ttd_asset': 'assets/signatures/ttd_sespri.png',
    };
  } else if (jabatan.contains('biro') || jabatan.contains('karo')) {
    return {
      'title': 'KEPALA BIRO UMUM',
      'nama': 'MUHAMMAD YULIARDI, S.STP., M.Si.',
      'pangkat': 'Pembina Utama Muda',
      'nip': 'NIP. 198007201999121002',
      'ttd_asset': 'assets/signatures/ttd_karo.png',
    };
  } else {
    debugPrint('[LOG WARNING] Unknown dariJabatan for signature: "$rawJabatan". Fallback to Karo.');
    return {
      'title': 'KEPALA BIRO UMUM',
      'nama': 'MUHAMMAD YULIARDI, S.STP., M.Si.',
      'pangkat': 'Pembina Utama Muda',
      'nip': 'NIP. 198007201999121002',
      'ttd_asset': 'assets/signatures/ttd_karo.png',
    };
  }
}

class LembarDisposisiWidget extends StatefulWidget {
  final ArsipSurat surat;
  final Function(List<String> newDiteruskan, String newInstruksi, String newLevel)? onUpdateDisposisi;
  final bool isEditable;

  const LembarDisposisiWidget({
    super.key,
    required this.surat,
    this.onUpdateDisposisi,
    this.isEditable = true,
  });

  @override
  State<LembarDisposisiWidget> createState() => _LembarDisposisiWidgetState();
}

class _LembarDisposisiWidgetState extends State<LembarDisposisiWidget> {
  late List<String> _diteruskan;
  late TextEditingController _instruksiCtrl;
  late String _penerimaLevel;

  @override
  void initState() {
    super.initState();
    final hasDisposisi = widget.surat.listDisposisi.isNotEmpty;
    _diteruskan = hasDisposisi ? List<String>.from(widget.surat.diteruskanKepada) : [];
    _instruksiCtrl = TextEditingController(text: hasDisposisi ? widget.surat.instruksiDisposisi : '');
    _penerimaLevel = hasDisposisi ? widget.surat.penerimaLevel : '';
  }

  @override
  void didUpdateWidget(covariant LembarDisposisiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasDisposisi = widget.surat.listDisposisi.isNotEmpty;
    if (!hasDisposisi) {
      _diteruskan = [];
      _instruksiCtrl.text = '';
      _penerimaLevel = '';
    } else if (oldWidget.surat.id != widget.surat.id ||
        oldWidget.surat.listDisposisi.length != widget.surat.listDisposisi.length ||
        oldWidget.surat.instruksiDisposisi != widget.surat.instruksiDisposisi) {
      _diteruskan = List<String>.from(widget.surat.diteruskanKepada);
      if (_instruksiCtrl.text != widget.surat.instruksiDisposisi) {
        _instruksiCtrl.text = widget.surat.instruksiDisposisi;
      }
      _penerimaLevel = widget.surat.penerimaLevel;
    }
  }

  @override
  void dispose() {
    _instruksiCtrl.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onUpdateDisposisi?.call(_diteruskan, _instruksiCtrl.text, _penerimaLevel);
  }

  bool _isKepalaBiroLevel(String level) {
    final l = level.toLowerCase();
    return l.contains('biro') || l.contains('karo') || l.contains('bapak kepala');
  }

  /// Helper untuk merender TTD PNG snapshot dari URL / Asset / Supabase Storage
  Widget _buildSignatureImage(String ttdPath, {double width = 90, double height = 45}) {
    if (ttdPath.isEmpty) {
      return _buildFallbackSignature(width, height);
    }

    if (ttdPath.startsWith('http://') || ttdPath.startsWith('https://')) {
      return Image.network(
        ttdPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackSignature(width, height),
      );
    } else if (ttdPath.startsWith('assets/')) {
      return Image.asset(
        ttdPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackSignature(width, height),
      );
    } else {
      // Path Supabase Storage (misal: 'signatures/default/ttd_karo.png')
      return FutureBuilder<String?>(
        future: _getSignedSignatureUrl(ttdPath),
        builder: (context, snapshot) {
          final signedUrl = snapshot.data;
          if (signedUrl != null && signedUrl.isNotEmpty) {
            return Image.network(
              signedUrl,
              width: width,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildFallbackSignature(width, height),
            );
          }
          return _buildFallbackSignature(width, height);
        },
      );
    }
  }

  Future<String?> _getSignedSignatureUrl(String path) async {
    try {
      final cleanPath = path.startsWith('signatures/') ? path.replaceFirst('signatures/', '') : path;
      return await Supabase.instance.client.storage
          .from('signatures')
          .createSignedUrl(cleanPath, 3600);
    } catch (_) {
      try {
        return await Supabase.instance.client.storage
            .from('arsip-surat')
            .createSignedUrl(path, 3600);
      } catch (_) {
        return null;
      }
    }
  }

  Widget _buildFallbackSignature(double width, double height) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.draw_rounded, size: 14, color: Colors.black54),
          SizedBox(width: 4),
          Text(
            '[ TTD Digital ]',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Dapatkan daftar disposisi terstruktur berdasarkan silsilah tree
  List<DisposisiModel> get _sortedDisposisiList {
    final list = List<DisposisiModel>.from(widget.surat.listDisposisi);
    list.sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isKaro = _isKepalaBiroLevel(_penerimaLevel);

    final optionsKaro = [
      'Kabag. Tata Usaha',
      'Kabag. Rumah Tangga',
      'Kabag. Administrasi dan Aset',
      'Sespri',
    ];

    final optionsKabag = [
      'Ka. Tim Kerja . Urusan Dalam',
      'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung/Kantor',
      'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
    ];

    final currentOptions = isKaro ? optionsKaro : optionsKabag;

    // Ambil disposisi aktif paling akhir untuk TTD
    final historyList = _sortedDisposisiList;
    final lastDisposisi = historyList.isNotEmpty ? historyList.last : null;

    final sig = getSignatureDetailsFor(lastDisposisi?.dariJabatan);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 650;
        final paperWidget = Container(
          width: isDesktop ? double.infinity : 650,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF4), // Authentic Cream Paper Color
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // KOP SURAT
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_biro_noBG.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Center(
                        child: Text('LAMPUNG', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          'PEMERINTAHAN PROVINSI LAMPUNG',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SEKRETARIAT DAERAH',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Jl. R.W. Monginsidi No. 69 Telp. (0721) 481166',
                          style: TextStyle(fontSize: 10, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'TELUKBETUNG 35215',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // DOUBLE LINE DIVIDER
              Column(
                children: [
                  Container(height: 2.5, color: Colors.black),
                  const SizedBox(height: 2),
                  Container(height: 1.0, color: Colors.black),
                ],
              ),

              const SizedBox(height: 10),

              // TITLE
              const Text(
                'LEMBAR DIPOSISI',
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                isKaro
                    ? 'Berdasarkan Keputusan Mendagri Nomor 69 Tahun 2000'
                    : 'Berdasarkan Keputusan Mendagri Nomor 47 Tahun 2000',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              Container(height: 1.5, color: Colors.black),

              // GRID META INFO TABLE
              _buildTableRow('Surat dari :', widget.surat.dari, 'Diterima :', widget.surat.noAgenda != '-' ? widget.surat.noAgenda : ' '),
              Container(height: 1, color: Colors.black),
              _buildTableRow(
                'Tanggal Surat :',
                _formatTanggalIndo(widget.surat.tanggalSurat),
                'Tanggal :',
                _formatTanggalIndo(widget.surat.tanggalDiterima ?? widget.surat.createdAt),
              ),
              Container(height: 1, color: Colors.black),
              _buildTableRow('Nomor Surat :', widget.surat.nomorSurat, '', ''),
              Container(height: 1, color: Colors.black),
              _buildSingleRow('Perihal / Isi ringkas :', widget.surat.judul),
              Container(height: 1.5, color: Colors.black),

              // MIDDLE SECTION: 2 COLUMNS (Interactive Typing & Checkbox Selection)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT COLUMN: DISPOSISI / INSTRUKSI (Direct Typing Area & Multi-Tier History)
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Disposisi / Instruksi :',
                                  style: TextStyle(
                                    fontFamily: 'Serif',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (widget.isEditable)
                                  const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFB45309)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (widget.isEditable)
                              TextField(
                                controller: _instruksiCtrl,
                                maxLines: 6,
                                style: const TextStyle(
                                  fontFamily: 'Serif',
                                  fontSize: 12,
                                  color: Colors.black,
                                  height: 1.4,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Klik di sini untuk mengetik catatan instruksi pimpinan...',
                                  hintStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black38),
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  // Keep typing state local without triggering parent full-screen reload per character
                                },
                                onEditingComplete: () => _notifyChanges(),
                              )
                            else if (historyList.isNotEmpty)
                              ...historyList.map((disp) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${disp.dariJabatan} ➔ ${disp.kepadaJabatan}',
                                            style: const TextStyle(
                                              fontFamily: 'Serif',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildStatusBadge(disp.statusDisposisi),
                                        ],
                                      ),
                                      if (disp.instruksi != null && disp.instruksi!.isNotEmpty)
                                        Text(
                                          disp.instruksi!,
                                          style: const TextStyle(
                                            fontFamily: 'Serif',
                                            fontSize: 11.5,
                                            color: Colors.black,
                                            height: 1.3,
                                          ),
                                        ),
                                      if (disp.catatan != null && disp.catatan!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            'Catatan: ${disp.catatan!}',
                                            style: const TextStyle(
                                              fontFamily: 'Serif',
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      const Divider(height: 8, thickness: 0.5, color: Colors.black26),
                                    ],
                                  ),
                                );
                              })
                            else
                              Text(
                                widget.surat.instruksiDisposisi.isNotEmpty
                                    ? widget.surat.instruksiDisposisi
                                    : '(Belum ada instruksi disposisi)',
                                style: TextStyle(
                                  fontFamily: 'Serif',
                                  fontSize: 12,
                                  fontStyle: widget.surat.instruksiDisposisi.isEmpty ? FontStyle.italic : FontStyle.normal,
                                  color: widget.surat.instruksiDisposisi.isEmpty ? Colors.black45 : Colors.black,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // VERTICAL DIVIDER
                    Container(width: 1.5, color: Colors.black),

                    // RIGHT COLUMN: DITERUSKAN KEPADA YTH (Direct Clickable Checkboxes)
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diteruskan Kepada Yth. :',
                              style: TextStyle(
                                fontFamily: 'Serif',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: widget.isEditable
                                  ? () {
                                      setState(() {
                                        if (_isKepalaBiroLevel(_penerimaLevel)) {
                                          _penerimaLevel = 'Kepala Bagian Rumah Tangga';
                                          _diteruskan = ['Ka. Tim Kerja . Urusan Dalam'];
                                        } else {
                                          _penerimaLevel = 'Bapak Kepala Biro Umum';
                                          _diteruskan = ['Kabag. Tata Usaha', 'Kabag. Rumah Tangga'];
                                        }
                                      });
                                      _notifyChanges();
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Text(
                                      isKaro ? 'Bapak Kepala Biro Umum' : 'Kabag. Rumah Tangga',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    if (widget.isEditable) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.sync_alt, size: 12, color: Color(0xFFB45309)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...currentOptions.map((opt) {
                              final isChecked = _diteruskan.contains(opt) || 
                                  historyList.any((d) => d.kepadaJabatan.toLowerCase().contains(opt.toLowerCase()) || d.kepadaRole.toLowerCase().contains(opt.toLowerCase()));

                          return InkWell(
                            onTap: widget.isEditable
                                ? () {
                                    setState(() {
                                      if (isChecked) {
                                        _diteruskan.remove(opt);
                                      } else {
                                        _diteruskan.add(opt);
                                      }
                                    });
                                    _notifyChanges();
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(top: 2, right: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 1.5),
                                      color: isChecked ? Colors.black : Colors.transparent,
                                    ),
                                    child: isChecked
                                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                                        : null,
                                  ),
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1.5, color: Colors.black),

          const SizedBox(height: 16),

          // FOOTER / SIGNATURE SECTION (SNAPSHOT TTD PNG RENDERING)
          // FOOTER / SIGNATURE SECTION (SNAPSHOT TTD PNG RENDERING)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 240,
              child: Column(
                children: [
                  Text(
                    sig['title']!,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  
                  // Render Snapshot TTD PNG
                  _buildSignatureImage(
                    lastDisposisi?.ttdPng ?? '',
                  ),

                  const SizedBox(height: 6),
                  if ((sig['nama'] ?? '').isNotEmpty)
                    Text(
                      sig['nama']!,
                      style: const TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 2),
                  Text(
                    sig['pangkat']!,
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    sig['nip']!,
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return paperWidget;
    } else {
      return ClipRect(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          clipBehavior: Clip.hardEdge,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 650,
                child: paperWidget,
              ),
            ),
          ),
        ),
      );
    }
  },
);
}

  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'pending':
        bg = Colors.orange;
        label = 'Pending';
        break;
      case 'dibaca':
        bg = Colors.blue;
        label = 'Dibaca';
        break;
      case 'diproses':
        bg = Colors.indigo;
        label = 'Diproses';
        break;
      case 'selesai':
        bg = Colors.green;
        label = 'Selesai';
        break;
      case 'ditarik':
        bg = Colors.grey;
        label = 'Ditarik';
        break;
      default:
        bg = Colors.orange;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildTableRow(String label1, String val1, String label2, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 95,
                  child: Text(
                    label1,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Expanded(
                  child: Text(
                    val1.isNotEmpty ? val1 : '-',
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          if (label2.isNotEmpty) ...[
            Container(width: 1, height: 20, color: Colors.black26),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      label2,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      val2.isNotEmpty ? val2 : '-',
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Expanded(
            child: Text(
              val.isNotEmpty ? val : '-',
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to generate PDF bytes for printing or downloading Lembar Disposisi
Future<Uint8List> generateLembarDisposisiPdf(ArsipSurat surat) async {
  final pdf = pw.Document();
  final historyList = List<DisposisiModel>.from(surat.listDisposisi);
  historyList.sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
  final lastDisposisi = historyList.isNotEmpty ? historyList.last : null;
  final sigPdf = getSignatureDetailsFor(lastDisposisi?.dariJabatan);

  final isKaro = lastDisposisi == null || lastDisposisi.dariJabatan.toLowerCase().contains('biro') || lastDisposisi.dariJabatan.toLowerCase().contains('karo');
  final diteruskanList = surat.diteruskanKepada;

  final optionsKaro = [
    'Kabag. Tata Usaha',
    'Kabag. Rumah Tangga',
    'Kabag. Administrasi dan Aset',
    'Sespri',
  ];

  final optionsKabag = [
    'Ka. Tim Kerja . Urusan Dalam',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung/Kantor',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
  ];

  final currentOptions = isKaro ? optionsKaro : optionsKabag;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER KOP
              pw.Column(
                children: [
                  pw.Text(
                    'PEMERINTAHAN PROVINSI LAMPUNG',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'SEKRETARIAT DAERAH',
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Jl. R.W. Monginsidi No. 69 Telp. (0721) 481166',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'TELUKBETUNG 35215',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2, color: PdfColors.black),
              pw.SizedBox(height: 2),
              pw.Container(height: 0.8, color: PdfColors.black),
              pw.SizedBox(height: 10),

              // TITLE
              pw.Text(
                'LEMBAR DIPOSISI',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                isKaro
                    ? 'Berdasarkan Keputusan Mendagri Nomor 69 Tahun 2000'
                    : 'Berdasarkan Keputusan Mendagri Nomor 47 Tahun 2000',
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 1.5, color: PdfColors.black),

              // META TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Surat dari : ${surat.dari}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Diterima : ${surat.noAgenda}\nTanggal : ${_formatTanggalIndo(surat.tanggalDiterima ?? surat.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Tanggal Surat : ${_formatTanggalIndo(surat.tanggalSurat)}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Nomor Surat : ${surat.nomorSurat}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Perihal / Isi ringkas : ${surat.judul}', style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 10),

              // DISPOSISI & DITERUSKAN 2 COLUMNS TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Disposisi / Instruksi :', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            surat.instruksiDisposisi.isNotEmpty ? surat.instruksiDisposisi : '(Belum ada instruksi)',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Diteruskan Kepada Yth. :', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(isKaro ? 'Bapak Kepala Biro Umum' : 'Kabag. Rumah Tangga', style: const pw.TextStyle(fontSize: 9.5)),
                          pw.SizedBox(height: 6),
                          ...currentOptions.map((opt) {
                            final checked = diteruskanList.contains(opt);
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(
                                children: [
                                  pw.Container(
                                    width: 10,
                                    height: 10,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.black, width: 1),
                                      color: checked ? PdfColors.black : PdfColors.white,
                                    ),
                                  ),
                                  pw.SizedBox(width: 6),
                                  pw.Expanded(
                                    child: pw.Text(opt, style: pw.TextStyle(fontSize: 9, fontWeight: checked ? pw.FontWeight.bold : pw.FontWeight.normal)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),

              pw.Spacer(),

              // FOOTER SIGNATURE
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        sigPdf['title']!,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 45),
                      if ((sigPdf['nama'] ?? '').isNotEmpty)
                        pw.Text(
                          sigPdf['nama']!,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                          textAlign: pw.TextAlign.center,
                        )
                      else
                        pw.SizedBox(height: 16),
                      pw.Text(
                        sigPdf['pangkat']!,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        sigPdf['nip']!,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
