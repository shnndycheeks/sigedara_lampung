import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_config.dart';
import '../models/arsip_surat_model.dart';
import '../services/arsip_surat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'tambah_edit_surat_screen.dart';
import 'full_screen_image_screen.dart';

class SuratDetailScreen extends StatefulWidget {
  final ArsipSurat surat;
  const SuratDetailScreen({super.key, required this.surat});

  @override
  State<SuratDetailScreen> createState() => _SuratDetailScreenState();
}

class _SuratDetailScreenState extends State<SuratDetailScreen> {
  late ArsipSurat _arsip;
  bool _loading = false;
  String? _signedUrl;

  @override
  void initState() {
    super.initState();
    _arsip = widget.surat;
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    if (_arsip.filePath.isEmpty) return;
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('arsip-surat')
          .createSignedUrl(_arsip.filePath, 3600);
      if (mounted) {
        setState(() {
          _signedUrl = signedUrl;
        });
      }
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      if (mounted) {
        setState(() {
          _signedUrl = _arsip.fileUrl;
        });
      }
    }
  }

  Future<void> _kirimKeWhatsAppKepalaBiro() async {
    final nomor = _arsip.nomorSurat;
    final tanggal = _formatTanggal(_arsip.tanggalSurat);
    final perihal = _arsip.judul;
    final dari = _arsip.dari;
    
    final message = "Assalamu'alaikum Wr. Wb.\n\n"
        "Yth. Kepala Biro\n\n"
        "Terdapat surat masuk baru yang memerlukan disposisi.\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Nomor Surat:\n$nomor\n\n"
        "Perihal:\n$perihal\n\n"
        "Asal Surat:\n$dari\n\n"
        "Tanggal Surat:\n$tanggal\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Silakan melakukan disposisi melalui Google Form berikut:\n\n"
        "${SupabaseConfig.googleFormUrl}\n\n"
        "Terima kasih.";

    final encodedMessage = Uri.encodeComponent(message);
    final phone = "62887437216916";
    final whatsappAppUri = Uri.parse("whatsapp://send?phone=$phone&text=$encodedMessage");
    final whatsappWebUri = Uri.parse("https://wa.me/$phone?text=$encodedMessage");
    
    try {
      bool launched = false;
      try {
        if (await canLaunchUrl(whatsappAppUri)) {
          launched = await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
      
      if (!launched) {
        try {
          if (await canLaunchUrl(whatsappWebUri)) {
            launched = await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      if (launched) {
        setState(() {
          _loading = true;
        });
        
        await ArsipSuratService.updateStatusPengiriman(
          id: _arsip.id,
          status: 'sudah_dikirim_karo',
          existingDeskripsi: _arsip.deskripsi,
        );
        
        final data = await ArsipSuratService.getSemuaArsip();
        final updated = data.firstWhere((s) => s.id == _arsip.id);
        
        if (mounted) {
          setState(() {
            _arsip = updated;
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ WhatsApp Kepala Biro berhasil dibuka.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw 'WhatsApp tidak ditemukan pada perangkat.';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('tidak ditemukan')
                ? '❌ WhatsApp tidak ditemukan pada perangkat.'
                : '❌ Gagal memicu WhatsApp: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Uint8List> _konversiGambarKePdf(Uint8List imageBytes) async {
    final pdfDocument = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    pdfDocument.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    return pdfDocument.save();
  }

  Color _getUrgensiColor(String urgensi) {
    switch (urgensi.toLowerCase()) {
      case 'segera':
        return AppColors.error;
      case 'penting':
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

  bool _isPdf(String url) {
    return url.toLowerCase().contains('.pdf') || url.toLowerCase().contains('/pdf');
  }

  Future<void> _editArsip() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahEditSuratScreen(existing: _arsip),
      ),
    );

    if (result == true) {
      setState(() {
        _loading = true;
      });
      try {
        // Fetch updated list and find this item
        final data = await ArsipSuratService.getSemuaArsip();
        final updated = data.firstWhere((s) => s.id == _arsip.id);
        setState(() {
          _arsip = updated;
          _loading = false;
        });
        await _loadSignedUrl();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Arsip surat berhasil disimpan.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyegarkan data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _hapusArsip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Arsip Surat', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus arsip "${_arsip.judul}"?\n\nBerkas fisik di Storage juga akan terhapus permanen.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
    });

    try {
      await ArsipSuratService.hapusArsip(id: _arsip.id, filePath: _arsip.filePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arsip surat berhasil dihapus.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus arsip: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _unduhDanCetak() async {
    setState(() {
      _loading = true;
    });
    try {
      final bytes = await Supabase.instance.client.storage
          .from('arsip-surat')
          .download(_arsip.filePath);

      final isActualPdf = bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;

      Uint8List pdfBytes;
      if (isActualPdf) {
        pdfBytes = bytes;
      } else {
        pdfBytes = await _konversiGambarKePdf(bytes);
      }

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses dokumen untuk cetak: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _arsip.fileUrl.isNotEmpty;
    final isPdfFile = _isPdf(_arsip.fileUrl);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Arsip Surat'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _loading ? null : _editArsip,
            tooltip: 'Edit Arsip',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _loading ? null : _hapusArsip,
            tooltip: 'Hapus Arsip',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Card
                  NeuCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _arsip.judul,
                                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: _arsip.tingkatUrgensi.toUpperCase(),
                              color: _getUrgensiColor(_arsip.tingkatUrgensi),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Nomor Surat', _arsip.nomorSurat),
                        _buildInfoRow('Asal Surat (Dari)', _arsip.dari),
                        _buildInfoRow('Tanggal Surat', _formatTanggal(_arsip.tanggalSurat)),
                        _buildInfoRow('Kategori', _arsip.kategori),
                        if (_arsip.kepada.isNotEmpty)
                          _buildInfoRow('Penerima Disposisi', _arsip.kepada),
                        if (_arsip.instruksiDisposisi.isNotEmpty)
                          _buildInfoRow('Instruksi Disposisi', _arsip.instruksiDisposisi),
                        _buildInfoRow(
                          'Status Pengiriman',
                          _arsip.statusPengiriman == 'sudah_dikirim_karo'
                              ? 'Sudah Dikirim ke Kepala Biro'
                              : 'Belum Dikirim ke Kepala Biro',
                          isStatus: true,
                        ),
                        if (_arsip.fileSize != null)
                          _buildInfoRow('Ukuran Berkas', '${(_arsip.fileSize! / 1024).toStringAsFixed(1)} KB'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Catatan Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Setelah tombol Kirim ke WhatsApp Kepala Biro ditekan, proses disposisi selanjutnya dilakukan melalui WhatsApp dan Google Form.\n\nSistem SIGEDARA hanya digunakan sebagai media pengarsipan surat masuk.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // WhatsApp Disposisi Action Button
                  if (_arsip.statusPengiriman == 'sudah_dikirim_karo') ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.success),
                            SizedBox(width: 6),
                            Text(
                              'Sudah dikirim ke Kepala Biro',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _kirimKeWhatsAppKepalaBiro,
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: Text(
                        _arsip.statusPengiriman == 'sudah_dikirim_karo'
                            ? 'Kirim Ulang ke WhatsApp Kepala Biro'
                            : 'Kirim ke WhatsApp Kepala Biro',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WA Green
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'WhatsApp akan terbuka otomatis beserta pesan dan tautan Google Form.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File Preview Area
                  const Text('Lampiran Surat', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (hasFile) ...[
                    Container(
                      height: 380,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: isPdfFile
                             ? (_signedUrl != null
                                 ? SfPdfViewer.network(
                                     _signedUrl!,
                                     key: ValueKey(_signedUrl),
                                   )
                                 : const Center(child: CircularProgressIndicator()))
                            : GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => FullScreenImageScreen(
                                      imageUrl: _signedUrl ?? _arsip.fileUrl,
                                      heroTag: 'arsip_image_${_arsip.id}',
                                    ),
                                  ));
                                },
                                child: Hero(
                                  tag: 'arsip_image_${_arsip.id}',
                                  child: Image.network(
                                    _signedUrl ?? _arsip.fileUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textHint),
                                            SizedBox(height: 8),
                                            Text('Gagal memuat gambar preview'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'Cetak / Unduh Berkas',
                        icon: Icons.print_rounded,
                        onPressed: _unduhDanCetak,
                      ),
                    ),
                  ] else ...[
                    const EmptyState(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Berkas Belum Diunggah',
                      subtitle: 'Harap sunting arsip untuk mengunggah berkas surat.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: isStatus
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: value.contains('Sudah Dikirim')
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: value.contains('Sudah Dikirim')
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: value.contains('Sudah Dikirim')
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              value,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: value.contains('Sudah Dikirim')
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
