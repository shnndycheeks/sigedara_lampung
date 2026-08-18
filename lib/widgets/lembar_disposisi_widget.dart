import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/arsip_surat_model.dart';
import '../models/disposisi_model.dart';

String _formatTanggalIndo(DateTime? dt) {
  if (dt == null) return '-';
  const bulan = [
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
    'Desember'
  ];
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}';
}

String _formatDisplayJabatan(String raw) {
  final clean = raw.trim();
  if (clean == 'karo' || clean == 'kepala_biro') return 'Bapak Kepala Biro Umum';
  if (clean == 'kabag_rt_jab' || clean == 'kabag_rt') return 'Kabag. Rumah Tangga';
  if (clean == 'kabag_tu_jab' || clean == 'kabag_tu') return 'Kabag. Tata Usaha';
  if (clean == 'kabag_asset_jab' || clean == 'kabag_aset' || clean == 'kabag_keuangan') return 'Kabag. Keuangan dan Aset';
  if (clean == 'katim_ud_jab') return 'Ka. Tim Kerja . Urusan Dalam';
  if (clean == 'katim_gd_jab') return 'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung';
  if (clean == 'katim_kd_jab') return 'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan';

  return raw
      .replaceAll('Kepala Bagian Rumah Tangga', 'Kabag. Rumah Tangga')
      .replaceAll('Kepala Bagian Tata Usaha', 'Kabag. Tata Usaha')
      .replaceAll('Kepala Bagian Administrasi dan Aset', 'Kabag. Keuangan dan Aset')
      .replaceAll('Kepala Bagian Keuangan dan Aset', 'Kabag. Keuangan dan Aset')
      .replaceAll('Kabag. Administrasi dan Aset', 'Kabag. Keuangan dan Aset')
      .replaceAll('kabag_rt_jab', 'Kabag. Rumah Tangga')
      .replaceAll('kabag_tu_jab', 'Kabag. Tata Usaha')
      .replaceAll('kabag_asset_jab', 'Kabag. Keuangan dan Aset');
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
  } else if (jabatan.contains('administrasi') ||
      jabatan.contains('aset') ||
      jabatan.contains('keuangan')) {
    return {
      'title': 'KABAG. KEUANGAN DAN ASET',
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
    return {
      'title': 'KEPALA BIRO UMUM',
      'nama': 'MUHAMMAD YULIARDI, S.STP., M.Si.',
      'pangkat': 'Pembina Utama Muda',
      'nip': 'NIP. 198007201999121002',
      'ttd_asset': 'assets/signatures/ttd_karo.png',
    };
  }
}

bool _isMatch(String opt, DisposisiModel d) {
  final cleanOpt = opt
      .toLowerCase()
      .replaceAll('kepala bagian', 'kabag')
      .replaceAll('katim', 'ka tim kerja')
      .replaceAll('.', '')
      .replaceAll(' ', '')
      .trim();

  final cleanJabatan = d.kepadaJabatan
      .toLowerCase()
      .replaceAll('kepala bagian', 'kabag')
      .replaceAll('katim', 'ka tim kerja')
      .replaceAll('.', '')
      .replaceAll(' ', '')
      .trim();

  final cleanRole = d.kepadaRole
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('.', '')
      .replaceAll(' ', '')
      .trim();

  if (cleanJabatan == cleanOpt) return true;
  if (cleanJabatan.contains(cleanOpt) || cleanOpt.contains(cleanJabatan)) {
    return true;
  }

  if (cleanOpt.contains('kabagrumahtangga') && cleanRole.contains('kabagrt')) {
    return true;
  }
  if (cleanOpt.contains('kabagtatausaha') && cleanRole.contains('kabagtu')) {
    return true;
  }
  if (cleanOpt.contains('kabagkeuangandanaset') &&
      cleanRole.contains('kabagaset')) {
    return true;
  }
  if (cleanOpt.contains('kabagadministrasidanaset') &&
      cleanRole.contains('kabagaset')) {
    return true;
  }

  if (cleanOpt.contains('urusandalam') &&
      (cleanRole.contains('katimud') || cleanRole.contains('ud'))) {
    return true;
  }
  if (cleanOpt.contains('gedung1') &&
      (cleanRole.contains('katimgd1') ||
          cleanRole.contains('gd1') ||
          cleanRole.contains('gedung1'))) {
    return true;
  }
  if (cleanOpt.contains('gedung2') &&
      (cleanRole.contains('katimgd2') ||
          cleanRole.contains('gd2') ||
          cleanRole.contains('gedung2'))) {
    return true;
  }
  if (cleanOpt.contains('kendaraan') &&
      (cleanRole.contains('katimkd') ||
          cleanRole.contains('kd') ||
          cleanRole.contains('kendaraan'))) {
    return true;
  }

  return false;
}

class LembarDisposisiWidget extends StatelessWidget {
  final ArsipSurat surat;
  final VoidCallback? onIsiDisposisiKaro;
  final VoidCallback? onIsiDisposisiKabag;
  final VoidCallback? onCetak;
  final bool isKaroActionEnabled;
  final bool isKabagActionEnabled;
  final bool isSubmitting;
  final bool isEditable;

  const LembarDisposisiWidget({
    super.key,
    required this.surat,
    this.onIsiDisposisiKaro,
    this.onIsiDisposisiKabag,
    this.onCetak,
    this.isKaroActionEnabled = true,
    this.isKabagActionEnabled = true,
    this.isSubmitting = false,
    this.isEditable = false,
  });

  static const optionsKaro = [
    'Kabag. Tata Usaha',
    'Kabag. Rumah Tangga',
    'Kabag. Keuangan dan Aset',
  ];

  static const optionsKabag = [
    'Ka. Tim Kerja . Urusan Dalam',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 1',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 2',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
  ];

  Widget _buildSheetHeader({
    required String title,
    required bool canAct,
    required VoidCallback? onIsi,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: (isSubmitting || !canAct) ? null : onIsi,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                isSubmitting ? 'Memproses...' : 'Isi Disposisi',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canAct ? const Color(0xFFF59E0B) : Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onCetak,
              icon: const Icon(
                Icons.print_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
              label: const Text(
                'Cetak',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFF59E0B),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final listKaro = surat.listKaroDisposisi;
    final listKabag = surat.listKabagDisposisi;

    final karoSig = getSignatureDetailsFor('karo');
    final kabagSenderJabatan = listKabag.isNotEmpty
        ? listKabag.first.dariJabatan
        : (surat.listKabagTarget.isNotEmpty
            ? surat.listKabagTarget.first
            : 'kabag_rt');
    final kabagSig = getSignatureDetailsFor(kabagSenderJabatan);

    final kabagHeaderTitle = listKabag.isNotEmpty
        ? _formatDisplayJabatan(listKabag.first.dariJabatan)
        : (surat.listKabagTarget.isNotEmpty
            ? _formatDisplayJabatan(surat.listKabagTarget.first)
            : 'Kabag. Rumah Tangga');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 650;

        final stackedSheets = Column(
          children: [
            // HEADER 1: LEMBAR DISPOSISI KARO
            _buildSheetHeader(
              title: 'Lembar Disposisi Karo',
              canAct: isKaroActionEnabled,
              onIsi: onIsiDisposisiKaro,
            ),
            const SizedBox(height: 8),

            // SHEET 1: DISPOSISI KARO (Form Mendagri No. 69 Thn 2000)
            _SingleLembarDisposisiSheet(
              surat: surat,
              legalTitle: 'Berdasarkan Keputusan Mendagri Nomor 69 Tahun 2000',
              levelHeader: 'Bapak Kepala Biro Umum',
              options: optionsKaro,
              disposisiList: listKaro,
              signatureDetails: karoSig,
              fallbackInstruction: listKaro.isNotEmpty
                  ? (listKaro.first.instruksi ?? '(Belum ada disposisi dari Karo)')
                  : '(Belum ada disposisi dari Karo)',
            ),
            const SizedBox(height: 24),

            // HEADER 2: LEMBAR DISPOSISI KABAG
            _buildSheetHeader(
              title: 'Lembar Disposisi Kabag',
              canAct: isKabagActionEnabled,
              onIsi: onIsiDisposisiKabag,
            ),
            const SizedBox(height: 8),

            // SHEET 2: DISPOSISI KABAG (Form Mendagri No. 47 Thn 2000)
            _SingleLembarDisposisiSheet(
              surat: surat,
              legalTitle: 'Berdasarkan Keputusan Mendagri Nomor 47 Tahun 2000',
              levelHeader: kabagHeaderTitle,
              options: optionsKabag,
              disposisiList: listKabag,
              signatureDetails: kabagSig,
              fallbackInstruction: listKabag.isNotEmpty
                  ? (listKabag.first.instruksi ?? '(Belum ada disposisi dari Kabag)')
                  : '(Belum ada disposisi dari Kabag)',
            ),
          ],
        );

        if (isDesktop) {
          return stackedSheets;
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
                  child: SizedBox(width: 650, child: stackedSheets),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class _SingleLembarDisposisiSheet extends StatelessWidget {
  final ArsipSurat surat;
  final String legalTitle;
  final String levelHeader;
  final List<String> options;
  final List<DisposisiModel> disposisiList;
  final Map<String, String> signatureDetails;
  final String fallbackInstruction;

  const _SingleLembarDisposisiSheet({
    required this.surat,
    required this.legalTitle,
    required this.levelHeader,
    required this.options,
    required this.disposisiList,
    required this.signatureDetails,
    required this.fallbackInstruction,
  });

  Widget _buildSignatureImage(
    String ttdPath, {
    double width = 95,
    double height = 48,
  }) {
    if (ttdPath.isEmpty) {
      return _buildFallbackSignature(width, height);
    }

    Widget childWidget;
    if (ttdPath.startsWith('http://') || ttdPath.startsWith('https://')) {
      childWidget = Image.network(
        ttdPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackSignature(width, height),
      );
    } else if (ttdPath.startsWith('assets/')) {
      childWidget = Image.asset(
        ttdPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackSignature(width, height),
      );
    } else {
      childWidget = FutureBuilder<String?>(
        future: _getSignedSignatureUrl(ttdPath),
        builder: (context, snapshot) {
          final signedUrl = snapshot.data;
          if (signedUrl != null && signedUrl.isNotEmpty) {
            return Transform.rotate(
              angle: -0.04,
              child: Image.network(
                signedUrl,
                width: width,
                height: height,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => _buildFallbackSignature(width, height),
              ),
            );
          }
          return _buildFallbackSignature(width, height);
        },
      );
      return childWidget;
    }

    return Transform.rotate(
      angle: -0.04, // Slight angle to make signature look natural and hand-signed
      child: childWidget,
    );
  }

  Future<String?> _getSignedSignatureUrl(String path) async {
    try {
      final cleanPath = path.startsWith('signatures/')
          ? path.replaceFirst('signatures/', '')
          : path;
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
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status.toLowerCase().trim()) {
      case 'pending':
        bg = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
      case 'dibaca':
      case 'proses':
        bg = Colors.blue;
        label = 'Proses';
        break;
      case 'diproses':
        bg = const Color(0xFFF59E0B);
        label = 'Diproses';
        break;
      case 'selesai':
      case 'diselesaikan':
        bg = Colors.green;
        label = 'Selesai';
        break;
      case 'ditarik':
      case 'telah selesai':
      case 'telah_selesai':
        bg = Colors.grey;
        label = 'Telah Selesai';
        break;
      default:
        bg = const Color(0xFFF59E0B);
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
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableRow(
    String label1,
    String val1,
    String label2,
    String val2,
  ) {
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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

  @override
  Widget build(BuildContext context) {
    final lastDisp = disposisiList.isNotEmpty ? disposisiList.last : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF4),
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
                'assets/images/logo_lampung.png',
                width: 55,
                height: 65,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 55,
                      height: 65,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'LAMPUNG',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  children: [
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(width: 55), // Symmetric spacer to center text
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
            legalTitle,
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
          _buildTableRow(
            'Surat dari :',
            surat.dari,
            'Diterima :',
            surat.noAgenda != '-' ? surat.noAgenda : ' ',
          ),
          Container(height: 1, color: Colors.black),
          _buildTableRow(
            'Tanggal Surat :',
            _formatTanggalIndo(surat.tanggalSurat),
            'Tanggal :',
            _formatTanggalIndo(surat.tanggalDiterima ?? surat.createdAt),
          ),
          Container(height: 1, color: Colors.black),
          _buildTableRow('Nomor Surat :', surat.nomorSurat, '', ''),
          Container(height: 1, color: Colors.black),
          _buildSingleRow('Perihal / Isi ringkas :', surat.judul),
          Container(height: 1.5, color: Colors.black),

          // MIDDLE SECTION: 2 COLUMNS
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT COLUMN: DISPOSISI / INSTRUKSI
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 6),
                        if (disposisiList.isNotEmpty)
                          ...disposisiList.map((disp) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        '${_formatDisplayJabatan(disp.dariJabatan)} ➔ ${_formatDisplayJabatan(disp.kepadaJabatan)}',
                                        style: const TextStyle(
                                          fontFamily: 'Serif',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                      _buildStatusBadge(disp.statusDisposisi),
                                    ],
                                  ),
                                  if (disp.instruksi != null &&
                                      disp.instruksi!.isNotEmpty)
                                    Text(
                                      disp.instruksi!,
                                      style: const TextStyle(
                                        fontFamily: 'Serif',
                                        fontSize: 11.5,
                                        color: Colors.black,
                                        height: 1.3,
                                      ),
                                    ),
                                  if (disp.catatan != null &&
                                      disp.catatan!.isNotEmpty)
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
                                  const Divider(
                                    height: 8,
                                    thickness: 0.5,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          Text(
                            fallbackInstruction,
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // VERTICAL DIVIDER
                Container(width: 1.5, color: Colors.black),

                // RIGHT COLUMN: DITERUSKAN KEPADA YTH
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
                        Text(
                          levelHeader,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...options.map((opt) {
                          final isChecked = disposisiList.any(
                            (d) => _isMatch(opt, d),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(
                                    top: 2,
                                    right: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                    color:
                                        isChecked
                                            ? Colors.black
                                            : Colors.transparent,
                                  ),
                                  child:
                                      isChecked
                                          ? const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                                Expanded(
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          isChecked
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
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
                    signatureDetails['title']!,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  _buildSignatureImage(
                    lastDisp?.ttdPng ?? signatureDetails['ttd_asset'] ?? '',
                    width: signatureDetails['title']!.contains('KEPALA BIRO') ? 110 : 95,
                    height: signatureDetails['title']!.contains('KEPALA BIRO') ? 60 : 48,
                  ),

                  const SizedBox(height: 6),
                  if ((signatureDetails['nama'] ?? '').isNotEmpty)
                    Text(
                      signatureDetails['nama']!,
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
                    signatureDetails['pangkat']!,
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    signatureDetails['nip']!,
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
}

/// Helper function to generate PDF bytes for printing or downloading Lembar Disposisi
Future<Uint8List> generateLembarDisposisiPdf(ArsipSurat surat) async {
  final pdf = pw.Document();

  final listKaro = surat.listKaroDisposisi;
  final listKabag = surat.listKabagDisposisi;

  final karoSig = getSignatureDetailsFor('karo');
  final kabagSenderJabatan =
      listKabag.isNotEmpty ? listKabag.first.dariJabatan : 'kabag_rt';
  final kabagSig = getSignatureDetailsFor(kabagSenderJabatan);

  final optionsKaro = [
    'Kabag. Tata Usaha',
    'Kabag. Rumah Tangga',
    'Kabag. Keuangan dan Aset',
  ];

  final optionsKabag = [
    'Ka. Tim Kerja . Urusan Dalam',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 1',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 2',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
  ];

  // Preload signature images asynchronously
  pw.MemoryImage? karoImage;
  try {
    karoImage = pw.MemoryImage(
      (await rootBundle.load(karoSig['ttd_asset']!)).buffer.asUint8List(),
    );
  } catch (_) {}

  pw.MemoryImage? kabagImage;
  try {
    kabagImage = pw.MemoryImage(
      (await rootBundle.load(kabagSig['ttd_asset']!)).buffer.asUint8List(),
    );
  } catch (_) {}

  // Sheet 1: KARO PDF Page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return _buildPdfPageSheet(
          surat: surat,
          legalTitle: 'Berdasarkan Keputusan Mendagri Nomor 69 Tahun 2000',
          levelHeader: 'Bapak Kepala Biro Umum',
          options: optionsKaro,
          disposisiList: listKaro,
          sigPdf: karoSig,
          ttdImage: karoImage,
        );
      },
    ),
  );

  // Sheet 2: KABAG PDF Page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return _buildPdfPageSheet(
          surat: surat,
          legalTitle: 'Berdasarkan Keputusan Mendagri Nomor 47 Tahun 2000',
          levelHeader:
              listKabag.isNotEmpty
                  ? listKabag.first.dariJabatan
                  : 'Kabag. Rumah Tangga',
          options: optionsKabag,
          disposisiList: listKabag,
          sigPdf: kabagSig,
          ttdImage: kabagImage,
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildPdfPageSheet({
  required ArsipSurat surat,
  required String legalTitle,
  required String levelHeader,
  required List<String> options,
  required List<DisposisiModel> disposisiList,
  required Map<String, String> sigPdf,
  pw.MemoryImage? ttdImage,
}) {
  final instruksi =
      disposisiList.isNotEmpty
          ? (disposisiList.first.instruksi ?? '(Belum ada instruksi)')
          : '(Belum ada instruksi)';

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
          legalTitle,
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1.5, color: PdfColors.black),

        // META TABLE
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Surat dari : ${surat.dari}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Diterima : ${surat.noAgenda}\nTanggal : ${_formatTanggalIndo(surat.tanggalDiterima ?? surat.createdAt)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Tanggal Surat : ${_formatTanggalIndo(surat.tanggalSurat)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Nomor Surat : ${surat.nomorSurat}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Perihal / Isi ringkas : ${surat.judul}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),

        // DISPOSISI & DITERUSKAN 2 COLUMNS TABLE
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Disposisi / Instruksi :',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(instruksi, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      pw.Text(
                        'Diteruskan Kepada Yth. :',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        levelHeader,
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                      pw.SizedBox(height: 6),
                      ...options.map((opt) {
                        final checked = disposisiList.any((d) => _isMatch(opt, d));
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 10,
                                height: 10,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                  color:
                                      checked
                                          ? PdfColors.black
                                          : PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Expanded(
                                child: pw.Text(
                                  opt,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight:
                                        checked
                                            ? pw.FontWeight.bold
                                            : pw.FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
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
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (ttdImage != null)
                  pw.Container(
                    height: sigPdf['title']!.contains('KEPALA BIRO') ? 55 : 45,
                    width: sigPdf['title']!.contains('KEPALA BIRO') ? 105 : 90,
                    child: pw.Image(ttdImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 45),
                if ((sigPdf['nama'] ?? '').isNotEmpty)
                  pw.Text(
                    sigPdf['nama']!,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
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
}
