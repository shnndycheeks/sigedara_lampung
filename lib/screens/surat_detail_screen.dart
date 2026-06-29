import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../models/arsip_surat_model.dart';
import '../services/arsip_surat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:photo_view/photo_view.dart';
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
            content: Text('Arsip berhasil diperbarui.'),
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
                        _buildInfoRow('Penerima Disposisi', _arsip.kepada),
                        _buildInfoRow('Instruksi Disposisi', _arsip.instruksiDisposisi),
                        if (_arsip.fileSize != null)
                          _buildInfoRow('Ukuran Berkas', '${(_arsip.fileSize! / 1024).toStringAsFixed(1)} KB'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timeline Status
                  const Text('Timeline Status Arsip', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  NeuCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        _buildTimelineNode(
                          title: 'Surat Masuk Diterima',
                          description: 'Tanggal surat tertulis: ${_formatTanggal(_arsip.tanggalSurat)}',
                          isDone: true,
                          isLast: false,
                        ),
                        _buildTimelineNode(
                          title: 'Selesai Diarsipkan',
                          description: 'Diunggah ke cloud storage sistem pada ${_formatTanggal(_arsip.createdAt)}',
                          isDone: true,
                          isLast: false,
                        ),
                        _buildTimelineNode(
                          title: 'Disposisi Ditugaskan',
                          description: 'Diinstruksikan kepada: ${_arsip.kepada}',
                          isDone: _arsip.kepada.isNotEmpty,
                          isLast: true,
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value) {
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
            child: Text(
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

  Widget _buildTimelineNode({
    required String title,
    required String description,
    required bool isDone,
    required bool isLast,
  }) {
    final activeColor = isDone ? AppColors.success : AppColors.divider;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                border: Border.all(color: activeColor, width: 2),
              ),
              child: isDone
                  ? Icon(Icons.check, size: 12, color: activeColor)
                  : const SizedBox.shrink(),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: activeColor,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDone ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDone ? AppColors.textSecondary : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
