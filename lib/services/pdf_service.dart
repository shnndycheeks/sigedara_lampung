
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<Uint8List> generateSurat({
    required String nomorSurat,
    required String nama,
    required String nip,
    required String ruangan,
    required String tanggal,
    required String jam,
    required String keperluan,
  }) async {
    final pdf = pw.Document();

    // Load Logo Lampung
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo_lampung.png'))
          .buffer
          .asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              /// ================= HEADER =================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(
                    logo,
                    width: 70,
                    height: 70,
                  ),

                  pw.SizedBox(width: 15),

                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "PEMERINTAH PROVINSI LAMPUNG",
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 3),

                        pw.Text(
                          "SEKRETARIAT DAERAH",
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 2),

                        pw.Text(
                          "BIRO UMUM",
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        pw.Text(
                          "Jl. Wolter Monginsidi No.69 Bandar Lampung",
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              pw.Divider(
                thickness: 2,
              ),

              pw.SizedBox(height: 20),

              /// ================= JUDUL =================
              pw.Center(
                child: pw.Text(
                  "SURAT IZIN PEMINJAMAN GEDUNG",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.Text(
                  "Nomor : $nomorSurat",
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),

              pw.SizedBox(height: 25),

              pw.Text(
                "Yang bertanda tangan di bawah ini menerangkan bahwa:",
                style: const pw.TextStyle(fontSize: 11),
              ),

              pw.SizedBox(height: 18),

              /// ================= DATA =================
              _row("Nama", nama),
              _row("NIP", nip),
              _row("Ruangan", ruangan),
              _row("Tanggal", tanggal),
              _row("Jam", jam),
              _row("Keperluan", keperluan),

              pw.SizedBox(height: 25),

              pw.Text(
                "Dengan ini diberikan izin menggunakan fasilitas gedung sesuai data di atas. "
                "Surat ini dipergunakan sebagaimana mestinya.",
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 11),
              ),

              pw.Spacer(),

              /// ================= TTD =================
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [

                    pw.Text(
                      "Bandar Lampung, $tanggal",
                      style: const pw.TextStyle(fontSize: 11),
                    ),

                    pw.SizedBox(height: 10),

                    pw.Text(
                      "Kepala Biro Umum",
                      style: pw.TextStyle(fontSize: 11),
                    ),

                    pw.SizedBox(height: 70),

                    pw.Text(
                      "(....................................)",
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _row(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Text(": "),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}