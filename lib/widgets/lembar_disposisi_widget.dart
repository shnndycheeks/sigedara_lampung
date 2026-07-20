import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/arsip_surat_model.dart';

String _formatTanggalIndo(DateTime? dt) {
  if (dt == null) return '-';
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
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
    _diteruskan = List<String>.from(widget.surat.diteruskanKepada);
    _instruksiCtrl = TextEditingController(text: widget.surat.instruksiDisposisi);
    _penerimaLevel = widget.surat.penerimaLevel;
  }

  @override
  void didUpdateWidget(covariant LembarDisposisiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surat != widget.surat) {
      _diteruskan = List<String>.from(widget.surat.diteruskanKepada);
      _instruksiCtrl.text = widget.surat.instruksiDisposisi;
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

    return Container(
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
                // LEFT COLUMN: DISPOSISI / INSTRUKSI (Direct Typing Area)
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
                            onChanged: (_) => _notifyChanges(),
                          )
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
                                  isKaro ? 'Bapak Kepala Biro Umum' : 'Kepala Bagian Rumah Tangga',
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
                          final isChecked = _diteruskan.contains(opt);
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

          // FOOTER / SIGNATURE SECTION
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 240,
              child: Column(
                children: [
                  Text(
                    isKaro ? 'KEPALA BIRO UMUM' : 'KEPALA BAGIAN RUMAH TANGGA',
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isKaro ? 'MUHAMMAD YULIARDI, S.STP., M.Si.' : 'ALVIRDIAN OKTAFIANUS, S.E., S.T., M.M.',
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isKaro ? 'Pembina Utama Muda' : 'Pembina',
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    isKaro ? 'NIP. 198007201999121002' : 'NIP. 19751004 201001 1 002',
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
  final isKaro = !surat.penerimaLevel.toLowerCase().contains('rumah tangga');
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
                          pw.Text(isKaro ? 'Bapak Kepala Biro Umum' : 'Kepala Bagian Rumah Tangga', style: const pw.TextStyle(fontSize: 9.5)),
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
                        isKaro ? 'KEPALA BIRO UMUM' : 'KEPALA BAGIAN RUMAH TANGGA',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 45),
                      pw.Text(
                        isKaro ? 'MUHAMMAD YULIARDI, S.STP., M.Si.' : 'ALVIRDIAN OKTAFIANUS, S.E., S.T., M.M.',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        isKaro ? 'Pembina Utama Muda' : 'Pembina',
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        isKaro ? 'NIP. 198007201999121002' : 'NIP. 19751004 201001 1 002',
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
