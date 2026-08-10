import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../models/arsip_surat_model.dart';
import '../models/disposisi_model.dart';
import '../models/surat_progress_model.dart';
import '../services/arsip_surat_service.dart';
import '../services/disposisi_service.dart';
import '../services/progress_service.dart';
import '../services/activity_log_service.dart';
import '../services/reference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'tambah_edit_surat_screen.dart';
import 'full_screen_image_screen.dart';
import '../widgets/lembar_disposisi_widget.dart';

class SuratDetailScreen extends StatefulWidget {
  final ArsipSurat surat;
  const SuratDetailScreen({super.key, required this.surat});

  @override
  State<SuratDetailScreen> createState() => _SuratDetailScreenState();
}

class _SuratDetailScreenState extends State<SuratDetailScreen> {
  late ArsipSurat _arsip;
  SuratProgressModel? _progress;
  bool _loading = false;
  bool _isSubmitting = false; // Anti-Spam Guard Flag
  String? _signedUrl;
  Uint8List? _pdfBytes;
  File? _tempPdfFile;
  bool _anyEdit = false;

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _arsip = widget.surat;
    _refreshData();
    ActivityLogService.logActivity(
      action: 'PREVIEW_SURAT',
      suratId: _arsip.id,
      details: {'judul': _arsip.judul, 'nomor_surat': _arsip.nomorSurat},
    );
  }

  Future<void> _refreshData({bool showLoading = true}) async {
    if (_loading) return;
    if (showLoading) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final updated = await ArsipSuratService.getArsipById(_arsip.id);
      final progressData = await ProgressService.getProgressSurat(_arsip.id);
      
      debugPrint('=== DEBUG PREVIEW STEP 1: METADATA SURAT ===');
      debugPrint('filePath   : ${updated.filePath}');
      debugPrint('fileUrl    : ${updated.fileUrl}');
      debugPrint('mimeType   : ${updated.mimeType}');
      debugPrint('extension  : ${updated.extension}');
      debugPrint('fileSize   : ${updated.fileSize}');
      debugPrint('isPdfResult: ${_isPdf(updated.fileUrl)}');
      debugPrint('===========================================');

      String? signedUrl;
      Uint8List? pdfBytes;
      File? tempPdfFile;

      if (updated.filePath.isNotEmpty) {
        try {
          signedUrl = await Supabase.instance.client.storage
              .from('arsip-surat')
              .createSignedUrl(updated.filePath, 3600);
        } catch (e) {
          debugPrint('Error creating signed URL: $e');
          signedUrl = updated.fileUrl;
        }

        if (_isPdf(updated.fileUrl)) {
          try {
            pdfBytes = await Supabase.instance.client.storage
                .from('arsip-surat')
                .download(updated.filePath);

            if (pdfBytes.isNotEmpty) {
              debugPrint("===== PDF DEBUG =====");
              debugPrint("PDF Length = ${pdfBytes.length}");
              debugPrint("Header = ${pdfBytes[0]} ${pdfBytes[1]} ${pdfBytes[2]} ${pdfBytes[3]}");
              debugPrint("Last Byte = ${pdfBytes.last}");
              debugPrint("=====================");

              final tail = String.fromCharCodes(
                pdfBytes.sublist(
                  pdfBytes.length > 30 ? pdfBytes.length - 30 : 0,
                ),
              );

              debugPrint("===== PDF TAIL =====");
              debugPrint(tail);
              debugPrint("====================");
            }
          } catch (e) {
            debugPrint('Error downloading PDF bytes for preview: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _arsip = updated;
          _progress = progressData;
          _signedUrl = signedUrl ?? updated.fileUrl;
          _pdfBytes = pdfBytes;
          _tempPdfFile = tempPdfFile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing detail: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _kirimKeWhatsAppKepalaBiro() async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    setState(() {
      _isSubmitting = true;
      _loading = true;
    });

    final nomor = _arsip.nomorSurat;
    final tanggal = _formatTanggal(_arsip.tanggalSurat);
    final perihal = _arsip.judul;
    final dari = _arsip.dari;

    String fileUrl = _arsip.fileUrl;
    if (_arsip.filePath.isNotEmpty) {
      try {
        final freshSignedUrl = await Supabase.instance.client.storage
            .from('arsip-surat')
            .createSignedUrl(_arsip.filePath, 604800);
        fileUrl = freshSignedUrl;
      } catch (e) {
        debugPrint('Error generating fresh signed URL for WhatsApp: $e');
        fileUrl = _signedUrl ?? _arsip.fileUrl;
      }
    }
    
    final message = "Assalamu'alaikum Wr. Wb.\n\n"
        "Yth. Kepala Biro,\n\n"
        "Terdapat surat masuk baru yang memerlukan disposisi.\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Nomor Surat:\n$nomor\n\n"
        "Perihal:\n$perihal\n\n"
        "Asal Surat:\n$dari\n\n"
        "Tanggal Surat:\n$tanggal\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "📄 Surat:\n$fileUrl\n\n"
        "Silakan membaca surat terlebih dahulu, kemudian lakukan disposisi melalui aplikasi Sigedara Lampung.\n\n"
        "Terima kasih.";

    final encodedMessage = Uri.encodeComponent(message);
    const phone = "62887437216916";
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
        await ArsipSuratService.updateStatusPengiriman(
          id: _arsip.id,
          status: 'sudah_dikirim_karo',
          existingDeskripsi: _arsip.deskripsi,
        );

        await ActivityLogService.logActivity(
          action: 'SEND_WHATSAPP_KARO',
          suratId: _arsip.id,
        );
        
        await _refreshData();
        
        if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _kirimKeWhatsAppKabag() async {
    if (_isSubmitting || _loading) return;
    setState(() {
      _isSubmitting = true;
      _loading = true;
    });

    final nomor = _arsip.nomorSurat;
    final tanggal = _formatTanggal(_arsip.tanggalSurat);
    final perihal = _arsip.judul;
    final dari = _arsip.dari;

    String fileUrl = _arsip.fileUrl;
    if (_arsip.filePath.isNotEmpty) {
      try {
        final freshSignedUrl = await Supabase.instance.client.storage
            .from('arsip-surat')
            .createSignedUrl(_arsip.filePath, 604800);
        fileUrl = freshSignedUrl;
      } catch (e) {
        debugPrint('Error generating fresh signed URL for WhatsApp Kabag: $e');
        fileUrl = _signedUrl ?? _arsip.fileUrl;
      }
    }
    
    final message = "Assalamu'alaikum Wr. Wb.\n\n"
        "Yth. Kepala Bagian,\n\n"
        "Terdapat surat masuk baru yang memerlukan disposisi.\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Nomor Surat:\n$nomor\n\n"
        "Perihal:\n$perihal\n\n"
        "Asal Surat:\n$dari\n\n"
        "Tanggal Surat:\n$tanggal\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "📄 Surat:\n$fileUrl\n\n"
        "Silakan membaca surat terlebih dahulu, kemudian lakukan disposisi melalui aplikasi Sigedara Lampung.\n\n"
        "Terima kasih.";

    final encodedMessage = Uri.encodeComponent(message);
    const phone = "6282377190673";
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
        await ActivityLogService.logActivity(
          action: 'SEND_WHATSAPP_KABAG',
          suratId: _arsip.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ WhatsApp Kabag berhasil dibuka.'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _kirimKeWhatsAppKatim() async {
    if (_isSubmitting || _loading) return;
    setState(() {
      _isSubmitting = true;
      _loading = true;
    });

    final nomor = _arsip.nomorSurat;
    final tanggal = _formatTanggal(_arsip.tanggalSurat);
    final perihal = _arsip.judul;
    final dari = _arsip.dari;

    String fileUrl = _arsip.fileUrl;
    if (_arsip.filePath.isNotEmpty) {
      try {
        final freshSignedUrl = await Supabase.instance.client.storage
            .from('arsip-surat')
            .createSignedUrl(_arsip.filePath, 604800);
        fileUrl = freshSignedUrl;
      } catch (e) {
        debugPrint('Error generating fresh signed URL for WhatsApp Katim: $e');
        fileUrl = _signedUrl ?? _arsip.fileUrl;
      }
    }
    
    final message = "Assalamu'alaikum Wr. Wb.\n\n"
        "Yth. Ketua Tim Kerja,\n\n"
        "Terdapat tugas disposisi baru yang memerlukan persetujuan/catatan Anda.\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Nomor Surat:\n$nomor\n\n"
        "Perihal:\n$perihal\n\n"
        "Asal Surat:\n$dari\n\n"
        "Tanggal Surat:\n$tanggal\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "📄 Surat:\n$fileUrl\n\n"
        "Silakan lakukan persetujuan tugas melalui aplikasi Sigedara Lampung.\n\n"
        "Terima kasih.";

    final encodedMessage = Uri.encodeComponent(message);
    const phone = "6285658861810";
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
        await ActivityLogService.logActivity(
          action: 'SEND_WHATSAPP_KATIM',
          suratId: _arsip.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ WhatsApp Katim berhasil dibuka.'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
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

  bool _isPdf(String url) {
    // Priority 1: mimeType
    final mime = (_arsip.mimeType ?? '').toLowerCase().trim();
    if (mime == 'application/pdf' || mime.contains('pdf')) {
      return true;
    }

    // Priority 2: extension
    final ext = (_arsip.extension ?? '').toLowerCase().trim();
    if (ext == 'pdf' || ext == '.pdf') {
      return true;
    }

    // Priority 3: filePath
    final path = _arsip.filePath.toLowerCase().trim();
    if (path.endsWith('.pdf') || path.contains('.pdf')) {
      return true;
    }

    // Priority 4: URL
    final lowerUrl = url.toLowerCase().trim();
    return lowerUrl.contains('.pdf') || lowerUrl.contains('/pdf');
  }

  String _formatDisplayJabatan(String raw) {
    return raw
        .replaceAll('Kepala Bagian Rumah Tangga', 'Kabag. Rumah Tangga')
        .replaceAll('Kepala Bagian Tata Usaha', 'Kabag. Tata Usaha')
        .replaceAll('Kepala Bagian Administrasi dan Aset', 'Kabag. Keuangan dan Aset')
        .replaceAll('Kepala Bagian Keuangan dan Aset', 'Kabag. Keuangan dan Aset')
        .replaceAll('Kabag. Administrasi dan Aset', 'Kabag. Keuangan dan Aset');
  }

  Future<void> _editArsip() async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahEditSuratScreen(existing: _arsip),
      ),
    );

    if (result == true) {
      try {
        await _refreshData();
        setState(() {
          _anyEdit = true;
        });
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
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Arsip Surat', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus arsip "${_arsip.judul}"?\n\nSurat akan dipindahkan ke folder sampah (Soft Delete).',
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
      _isSubmitting = true;
      _loading = true;
    });

    try {
      await ArsipSuratService.hapusArsip(id: _arsip.id, filePath: _arsip.filePath);
      await ActivityLogService.logActivity(
        action: 'DELETE_SURAT',
        suratId: _arsip.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arsip surat berhasil dihapus (Soft Delete).'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus arsip: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _unduhDanCetak() async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    setState(() {
      _isSubmitting = true;
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

      await ActivityLogService.logActivity(
        action: 'DOWNLOAD_SURAT',
        suratId: _arsip.id,
      );

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
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _cetakLembarDisposisi() async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    setState(() {
      _isSubmitting = true;
      _loading = true;
    });
    try {
      final pdfBytes = await generateLembarDisposisiPdf(_arsip);
      await ActivityLogService.logActivity(
        action: 'PRINT_DISPOSISI',
        suratId: _arsip.id,
      );
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak lembar disposisi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  /// Tarik Disposisi oleh Pengirim (Karo / Kabag) dengan Anti-Spam Guard
  Future<void> _tarikDisposisi(DisposisiModel disp) async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tarik Disposisi', style: AppTextStyles.h3),
        content: Text(
          'Apakah Anda yakin ingin menarik disposisi yang ditujukan ke "${disp.kepadaJabatan}"?\n\nRecord akan ditandai "DITARIK" pada audit trail dan hilang dari Inbox penerima.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tarik Disposisi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
      _loading = true;
    });

    try {
      final userId = currentUser?.id ?? disp.dariUserId;
      await DisposisiService.tarikDisposisi(
        disposisiId: disp.id,
        userId: userId,
      );

      await ActivityLogService.logActivity(
        action: 'RECALL_DISPOSISI',
        suratId: _arsip.id,
        details: {'disposisi_id': disp.id, 'kepada': disp.kepadaJabatan},
      );

      await _refreshData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Disposisi berhasil ditarik.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menarik disposisi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loading = false;
        });
      }
    }
  }

  /// Form Modal pengisian Catatan Selesai oleh Katim/Penerima dengan Anti-Spam Guard
  Future<void> _showModalCatatanSelesai(DisposisiModel disp) async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check

    final catatanResult = await showDialog<String>(
      context: context,
      builder: (ctx) => _ModalCatatanSelesaiDialog(disposisi: disp),
    );

    if (catatanResult != null && catatanResult.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        await DisposisiService.selesaikanDisposisi(
          disposisiId: disp.id,
          catatan: catatanResult,
        );

        await ActivityLogService.logActivity(
          action: 'COMPLETE_DISPOSISI',
          suratId: _arsip.id,
          details: {'disposisi_id': disp.id, 'catatan': catatanResult},
        );

        // Silent refresh so timeline, progress, and stepper update in place
        await _refreshData(showLoading: false);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Disposisi berhasil diselesaikan!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyelesaikan disposisi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  /// Modal Kirim Disposisi Multi-Tujuan (Karo / Kabag) dengan Anti-Spam Guard
  Future<void> _showModalIsiDisposisi() async {
    if (_isSubmitting || _loading) return; // Anti-Spam Check

    final activeUser = currentUser;
    final activeUserEmail = activeUser?.email ?? '';

    // Check if there is an active (non-completed) disposition created by Karo
    final hasActiveKaroDisposisi = _arsip.listDisposisi.any((d) =>
        (d.statusDisposisi == 'pending' || d.statusDisposisi == 'dibaca' || d.statusDisposisi == 'diproses') &&
        (d.dariJabatan.toLowerCase().contains('karo') || d.dariJabatan.toLowerCase().contains('biro'))
    );

    final isUserKaro = activeUserEmail.contains('karo') || _arsip.penerimaLevel.toLowerCase().contains('biro') || _arsip.penerimaLevel.toLowerCase().contains('karo');

    if (isUserKaro && hasActiveKaroDisposisi) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('⚠️ Disposisi Aktif Sudah Ada', style: AppTextStyles.h3),
          content: const Text(
            'Surat ini sudah memiliki alur disposisi aktif dari Karo.\n\nJika ingin mengubah alur disposisi, silakan melakukan "Tarik Disposisi" terlebih dahulu pada disposisi yang ada.',
            style: AppTextStyles.body,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    debugPrint('===== DISPOSISI FLOW =====');
    debugPrint('STEP 1: OPEN FORM MODAL');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModalIsiDisposisiSheet(
        surat: _arsip,
        isSubmitting: _isSubmitting,
      ),
    );

    if (result != null) {
      debugPrint('STEP 2: SUBMITTED FORM WITH DATA: $result');
      final selectedLevel = result['level'] as String;
      final selectedDiteruskan = result['diteruskan'] as List<String>;
      final instruksiText = result['instruksi'] as String;

      setState(() {
        _isSubmitting = true;
      });

      try {
        if (activeUser == null) {
          throw Exception('Sesi login telah berakhir. Silakan login kembali.');
        }

        String dariRole = 'kabag_rt';
        String dariJabatan = selectedLevel;

        if (selectedLevel.toLowerCase().contains('biro') || selectedLevel.toLowerCase().contains('karo')) {
          dariRole = 'kepala_biro';
          dariJabatan = 'Kepala Biro Umum';
        } else if (selectedLevel.toLowerCase().contains('tata usaha') || selectedLevel.toLowerCase().contains('tu')) {
          dariRole = 'kabag_tu';
          dariJabatan = 'Kabag. Tata Usaha';
        } else if (selectedLevel.toLowerCase().contains('rumah tangga') || selectedLevel.toLowerCase().contains('rt')) {
          dariRole = 'kabag_rt';
          dariJabatan = 'Kepala Bagian Rumah Tangga';
        } else if (selectedLevel.toLowerCase().contains('administrasi') || selectedLevel.toLowerCase().contains('aset') || selectedLevel.toLowerCase().contains('keuangan')) {
          dariRole = 'kabag_aset';
          dariJabatan = 'Kabag. Keuangan dan Aset';
        } else if (selectedLevel.toLowerCase().contains('sespri')) {
          dariRole = 'sespri';
          dariJabatan = 'Sespri';
        }

        debugPrint('STEP 3: RESOLVING TARGET PEGAWAI FOR ${selectedDiteruskan.length} RECIPIENTS...');
        final activePegawai = await ReferenceService.getPegawaiAktif();

        final List<Map<String, String>> penerimaList = [];
        for (final targetJabatan in selectedDiteruskan) {
          final matched = activePegawai.where((p) {
            final jName = (p.jabatan?.namaJabatan ?? '').toLowerCase()
                .replaceAll('kepala bagian', 'kabag')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final rName = (p.role?.namaRole ?? '').toLowerCase()
                .replaceAll('_', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final search = targetJabatan.toLowerCase()
                .replaceAll('kepala bagian', 'kabag')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final cleanRole = p.roleId.toLowerCase()
                .replaceAll('_', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();

            if (jName == search) return true;
            if (jName.contains(search) || search.contains(jName)) return true;
            if (rName.contains(search) || search.contains(rName)) return true;

            // Role mapping checks
            if (search.contains('kabagrumahtangga') && cleanRole.contains('kabagrt')) return true;
            if (search.contains('kabagtatausaha') && cleanRole.contains('kabagtu')) return true;
            if (search.contains('kabagkeuangandanaset') && cleanRole.contains('kabagaset')) return true;
            if (search.contains('kabagadministrasidanaset') && cleanRole.contains('kabagaset')) return true;

            return false;
          });

          if (matched.isNotEmpty) {
            penerimaList.add({
              'user_id': matched.first.id,
              'role': matched.first.roleId,
              'jabatan': targetJabatan,
            });
          } else if (activePegawai.isNotEmpty) {
            penerimaList.add({
              'user_id': activePegawai.first.id,
              'role': activePegawai.first.roleId,
              'jabatan': targetJabatan,
            });
          } else {
            throw Exception('Tidak ada pegawai aktif di database untuk menerima disposisi ($targetJabatan)');
          }
        }

        String? parentId;
        if (_arsip.listDisposisi.isNotEmpty) {
          parentId = _arsip.listDisposisi.last.id;
        }

        debugPrint('STEP 4: INSERTING DISPOSISI TO DATABASE...');
        await DisposisiService.kirimDisposisiMulti(
          suratId: _arsip.id,
          parentDisposisiId: parentId,
          dariUserId: activeUser.id,
          dariRole: dariRole,
          dariJabatan: dariJabatan,
          penerimaList: penerimaList,
          instruksi: instruksiText,
          ttdPng: 'signatures/default/ttd_karo.png',
        );
        debugPrint('STEP 5: INSERT SUCCESSFUL');

        await ActivityLogService.logActivity(
          action: 'DISPOSISI_KIRIM',
          suratId: _arsip.id,
          details: {
            'penerima': selectedDiteruskan,
            'instruksi': instruksiText,
          },
        );

        debugPrint('STEP 6: RELOADING SURAT DATA SILENTLY...');
        await _refreshData(showLoading: false);
        debugPrint('STEP 7: LOADED ${_arsip.listDisposisi.length} DISPOSISI RECORDS');
        debugPrint('STEP 8: UI UPDATED SUCCESSFULLY');
        debugPrint('==========================');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Disposisi berhasil dikirim ke ${selectedDiteruskan.length} penerima!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        debugPrint('===== DISPOSISI ERROR =====');
        debugPrint(e.toString());
        debugPrint('===========================');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan disposisi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _arsip.fileUrl.isNotEmpty;
    final isPdfFile = _isPdf(_arsip.fileUrl);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _anyEdit);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Detail Arsip Surat'),
          backgroundColor: AppColors.primaryDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, _anyEdit),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: (_loading || _isSubmitting) ? null : _editArsip,
              tooltip: 'Edit Arsip',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: (_loading || _isSubmitting) ? null : _hapusArsip,
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
                  // PROGRESS BADGE MONITORING VIEW
                  if (_progress != null) ...[
                    _buildProgressCard(_progress!),
                    const SizedBox(height: 16),
                  ],

                  // LEMBAR DISPOSISI DIGITAL
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text('Lembar Disposisi Digital', style: AppTextStyles.h3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_loading || _isSubmitting) ? null : _showModalIsiDisposisi,
                            icon: _isSubmitting 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                            label: Text(_isSubmitting ? 'Memproses...' : 'Isi Disposisi', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: (_loading || _isSubmitting) ? null : _cetakLembarDisposisi,
                            icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFFD97706)),
                            label: const Text('Cetak', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LembarDisposisiWidget(
                    surat: _arsip,
                    isEditable: true,
                    onUpdateDisposisi: (newDiteruskan, newInstruksi, newLevel) {
                      _onDirectDisposisiChanged(newDiteruskan, newInstruksi, newLevel);
                    },
                  ),
                  const SizedBox(height: 20),

                  // VISUAL STEPPER TIMELINE ALUR DISPOSISI
                  _buildAlurDisposisiTimeline(),
                  const SizedBox(height: 16),

                  // RIWAYAT AUDIT TRANSPARAN DISPOSISI
                  _buildRiwayatDisposisiCard(),
                  const SizedBox(height: 24),

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
                          'Status Global Surat',
                          _arsip.statusGlobal.toUpperCase(),
                          isStatus: true,
                        ),
                        if (_arsip.fileSize != null)
                          _buildInfoRow('Ukuran Berkas', '${(_arsip.fileSize! / 1024).toStringAsFixed(1)} KB'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TINDAKAN ALUR DISPOSISI
                  const Text('Tindakan Alur Disposisi & Persetujuan', style: AppTextStyles.h3),
                  const SizedBox(height: 12),

                  // Button 1: Kirim WA ke Karo (TU)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _isSubmitting) ? null : _kirimKeWhatsAppKepalaBiro,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _arsip.statusPengiriman == 'belum_dikirim_karo'
                            ? '1. Kirim WA ke Karo (Bapak Kepala Biro)'
                            : '1. Kirim Ulang WA ke Karo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 1B: Kirim WA ke Kabag
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _isSubmitting) ? null : _kirimKeWhatsAppKabag,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        'Kirim WA ke Kabag',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 1C: Kirim WA ke Katim
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _isSubmitting) ? null : _kirimKeWhatsAppKatim,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        'Kirim WA ke Katim',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 2: Disposisi Multi-Tujuan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _isSubmitting) ? null : _showModalIsiDisposisi,
                      icon: const Icon(Icons.forward_to_inbox_rounded, color: Colors.white),
                      label: const Text(
                        '2. Buat & Kirim Disposisi Multi-Tujuan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File Preview Area
                  const Text('Lampiran Surat', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (hasFile) ...[
                    Container(
                      key: ValueKey(_signedUrl ?? _arsip.fileUrl),
                      height: 380,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: isPdfFile
                             ? (_pdfBytes != null
                                  ? Builder(
                                      builder: (context) {
                                        debugPrint("PDF bytes = ${_pdfBytes!.length}");
                                        return SfPdfViewer.memory(
                                          _pdfBytes!,
                                          key: ValueKey(_pdfBytes),
                                          onDocumentLoaded: (details) {
                                            debugPrint("===== PDF LOADED =====");
                                            debugPrint("Pages : ${details.document.pages.count}");
                                            debugPrint("======================");
                                          },
                                          onDocumentLoadFailed: (details) {
                                            debugPrint("===== PDF FAILED =====");
                                            debugPrint("Error : ${details.error}");
                                            debugPrint("Description : ${details.description}");
                                            debugPrint("======================");
                                          },
                                        );
                                      },
                                    )
                                  : (_tempPdfFile != null && _tempPdfFile!.existsSync()
                                      ? Builder(
                                          builder: (context) {
                                            debugPrint('=== DEBUG PREVIEW STEP 6: Rendering PDF FILE FALLBACK ===');
                                            return SfPdfViewer.file(
                                              _tempPdfFile!,
                                              key: ValueKey(_tempPdfFile!.path),
                                              onDocumentLoaded: (details) => debugPrint('=== STEP 6 PDF FILE BERHASIL DIMUAT (Pages: ${details.document.pages.count}) ==='),
                                              onDocumentLoadFailed: (details) => debugPrint('=== STEP 6 PDF FILE GAGAL DIMUAT: ${details.description} ==='),
                                            );
                                          },
                                        )
                                      : const Center(child: CircularProgressIndicator())))
                             : Builder(
                                 builder: (context) {
                                   debugPrint('=== DEBUG PREVIEW STEP 4: Rendering IMAGE NETWORK ===');
                                   return GestureDetector(
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
                                         key: ValueKey(_signedUrl ?? _arsip.fileUrl),
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
                                   );
                                 },
                               ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'Cetak / Unduh Berkas',
                        icon: Icons.print_rounded,
                        isLoading: _loading || _isSubmitting,
                        onPressed: () => _unduhDanCetak(),
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
      ),
    );
  }

  Widget _buildProgressCard(SuratProgressModel progress) {
    final double percent = progress.progressPercent;
    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: percent / 100.0,
                  strokeWidth: 4.5,
                  backgroundColor: Colors.grey.shade200,
                  color: percent == 100.0 ? AppColors.success : const Color(0xFFF59E0B),
                ),
              ),
              Text(
                '${percent.toInt()}%',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Disposisi: ${progress.totalSelesai} dari ${progress.totalDisposisi} Selesai',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status Global: ${progress.statusGlobal.toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDirectDisposisiChanged(List<String> newDiteruskan, String newInstruksi, String newLevel) async {
    try {
      final updatedMap = Map<String, dynamic>.from(_arsip.deskripsi);
      updatedMap['penerima_level'] = newLevel;
      updatedMap['diteruskan_kepada'] = newDiteruskan;
      updatedMap['instruksi_disposisi'] = newInstruksi;

      await ArsipSuratService.updateArsip(
        id: _arsip.id,
        judul: _arsip.judul,
        kategori: _arsip.kategori,
        deskripsi: updatedMap,
        fileUrl: _arsip.fileUrl,
        filePath: _arsip.filePath,
        fileSize: _arsip.fileSize,
      );

      await _refreshData(showLoading: false);
    } catch (e) {
      debugPrint('Error updating direct disposisi: $e');
    }
  }

  Widget _buildAlurDisposisiTimeline() {
    final list = _arsip.listDisposisi;

    // STEP 1: TU Scan (True once letter exists)
    final bool isTuDone = true;

    // STEP 2: Karo (True once Karo sends initial disposition)
    final bool isKaroDone = list.any((d) => 
        d.dariJabatan.toLowerCase().contains('biro') || 
        d.dariJabatan.toLowerCase().contains('karo')
    );

    // STEP 3: Kabag / Sespri (True ONLY when BOTH Condition A and Condition B are met)
    // Kondisi A: Task assigned to Kabag/Sespri is completed ('selesai' + Catatan filled)
    final bool hasKabagSespriTaskCompleted = list.any((d) {
      final isTargetKabagSespri = d.kepadaJabatan.toLowerCase().contains('bagian') ||
          d.kepadaJabatan.toLowerCase().contains('kabag') ||
          d.kepadaJabatan.toLowerCase().contains('sespri');
      final isSelesai = d.statusDisposisi.toLowerCase() == 'selesai';
      final hasCatatan = (d.catatan ?? '').trim().isNotEmpty;
      return isTargetKabagSespri && isSelesai && hasCatatan;
    });

    // Kondisi B: Kabag/Sespri has created/forwarded a child disposition to Katim/Tim Kerja
    final bool hasKabagSespriForwardedToKatim = list.any((d) {
      final isSenderKabagSespri = d.dariJabatan.toLowerCase().contains('bagian') ||
          d.dariJabatan.toLowerCase().contains('kabag') ||
          d.dariJabatan.toLowerCase().contains('sespri');
      final isTargetKatim = d.kepadaJabatan.toLowerCase().contains('tim kerja') ||
          d.kepadaJabatan.toLowerCase().contains('katim');
      return isSenderKabagSespri && isTargetKatim;
    });

    final bool isKabagSespriDone = hasKabagSespriTaskCompleted && hasKabagSespriForwardedToKatim;

    // STEP 4: Katim (True ONLY when Katim task has status_disposisi == 'selesai' AND has Catatan)
    final bool isKatimDone = list.any((d) {
      final isKatim = d.kepadaJabatan.toLowerCase().contains('tim kerja') ||
          d.kepadaJabatan.toLowerCase().contains('katim') ||
          d.dariJabatan.toLowerCase().contains('tim kerja') ||
          d.dariJabatan.toLowerCase().contains('katim');
      final isSelesai = d.statusDisposisi.toLowerCase() == 'selesai';
      final hasCatatan = (d.catatan ?? '').trim().isNotEmpty;

      return isKatim && isSelesai && hasCatatan;
    });

    int currentStep = 1;
    if (isKaroDone) currentStep = 2;
    if (isKabagSespriDone) currentStep = 3;
    if (isKatimDone) currentStep = 4;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text('Alur Disposisi & Persetujuan', style: AppTextStyles.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  isKatimDone ? 'Selesai' : (list.isEmpty ? 'Menunggu Disposisi' : 'Dalam Proses'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Alur: TU Scan ➔ Karo (Biro) ➔ Kabag ➔ Katim (Persetujuan)',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepItem(1, 'TU Scan', isTuDone, currentStep == 1),
                _buildStepLine(isKaroDone),
                _buildStepItem(2, 'Karo', isKaroDone, currentStep == 2),
                _buildStepLine(isKabagSespriDone),
                _buildStepItem(3, 'Kabag', isKabagSespriDone, currentStep == 3),
                _buildStepLine(isKatimDone),
                _buildStepItem(4, 'Katim', isKatimDone, currentStep == 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNum, String title, bool isDone, bool isCurrent) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFFF59E0B) : Colors.grey.shade200,
              border: isCurrent
                  ? Border.all(color: const Color(0xFF0F172A), width: 2.5)
                  : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      '$stepNum',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? AppColors.textPrimary : AppColors.textHint,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Container(
      width: 16,
      height: 2,
      color: isDone ? const Color(0xFFF59E0B) : Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 18),
    );
  }

  Widget _buildRiwayatDisposisiCard() {
    final historyList = _arsip.listDisposisi;
    if (historyList.isEmpty) return const SizedBox.shrink();

    final activeUserId = currentUser?.id ?? '';

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📜 Timeline Disposisi Bertingkat', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          const Text(
            'Catatan riwayat audit waktu, pengirim, penerima, instruksi, dan catatan pelaksanaan.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...historyList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;

            final isSender = activeUserId.isNotEmpty && item.dariUserId == activeUserId;
            final isRecipient = activeUserId.isNotEmpty && (
                item.kepadaUserId == activeUserId ||
                item.kepadaUserId.isEmpty
            );

            final isCanBeRecalled = isSender && (item.statusDisposisi == 'pending' || item.statusDisposisi == 'dibaca');
            final isCanBeCompleted = isRecipient && (item.statusDisposisi == 'pending' || item.statusDisposisi == 'dibaca' || item.statusDisposisi == 'diproses');

            String dua(int n) => n.toString().padLeft(2, '0');
            final dt = item.assignedAt;
            final waktuFormatted = '${dua(dt.day)}/${dua(dt.month)}/${dt.year} ${dua(dt.hour)}:${dua(dt.minute)} WIB';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.statusDisposisi == 'selesai' ? AppColors.success : const Color(0xFFF59E0B),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_formatDisplayJabatan(item.dariJabatan)} ➔ ${_formatDisplayJabatan(item.kepadaJabatan)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            Text(
                              waktuFormatted,
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(item.statusDisposisi),
                            if (isCanBeRecalled) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: (_loading || _isSubmitting) ? null : () => _tarikDisposisi(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    border: Border.all(color: Colors.orange.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.undo_rounded, size: 10, color: Colors.orange),
                                      SizedBox(width: 2),
                                      Text(
                                        'Tarik Disposisi',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.orange),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (isCanBeCompleted) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: (_loading || _isSubmitting) ? null : () => _showModalCatatanSelesai(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 10, color: Colors.green),
                                      SizedBox(width: 2),
                                      Text(
                                        'Selesaikan Tugas',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.instruksi != null && item.instruksi!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Instruksi: "${item.instruksi}"',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
                          ),
                        ],
                        if (item.catatan != null && item.catatan!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan Pelaksanaan: "${item.catatan}"',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                        if (item.completedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Waktu Selesai: ${dua(item.completedAt!.day)}/${dua(item.completedAt!.month)}/${item.completedAt!.year} ${dua(item.completedAt!.hour)}:${dua(item.completedAt!.minute)} WIB',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                          color: value.toLowerCase().contains('selesai')
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: value.toLowerCase().contains('selesai')
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
                                color: value.toLowerCase().contains('selesai')
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              value,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: value.toLowerCase().contains('selesai')
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

class _ModalIsiDisposisiSheet extends StatefulWidget {
  final ArsipSurat surat;
  final bool isSubmitting;

  const _ModalIsiDisposisiSheet({
    required this.surat,
    required this.isSubmitting,
  });

  @override
  State<_ModalIsiDisposisiSheet> createState() => _ModalIsiDisposisiSheetState();
}

class _ModalIsiDisposisiSheetState extends State<_ModalIsiDisposisiSheet> {
  static const List<String> _pejabatOptions = [
    'Bapak Kepala Biro Umum',
    'Kabag. Tata Usaha',
    'Kepala Bagian Rumah Tangga',
    'Kabag. Keuangan dan Aset',
  ];

  static const List<String> _karoTargetOptions = [
    'Kabag. Tata Usaha',
    'Kabag. Rumah Tangga',
    'Kabag. Keuangan dan Aset',
  ];

  static const List<String> _kabagTargetOptions = [
    'Ka. Tim Kerja . Urusan Dalam',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 1',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 2',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
  ];

  late String _selectedLevel;
  late List<String> _selectedDiteruskan;
  late TextEditingController _instruksiCtrl;
  late FocusNode _instruksiFocusNode;

  @override
  void initState() {
    super.initState();

    String initialLevel = widget.surat.penerimaLevel;
    if (!_pejabatOptions.contains(initialLevel)) {
      if (initialLevel.toLowerCase().contains('biro') || initialLevel.toLowerCase().contains('karo')) {
        initialLevel = 'Bapak Kepala Biro Umum';
      } else if (initialLevel.toLowerCase().contains('tata usaha') || initialLevel.toLowerCase().contains('tu')) {
        initialLevel = 'Kabag. Tata Usaha';
      } else if (initialLevel.toLowerCase().contains('rumah tangga') || initialLevel.toLowerCase().contains('rt')) {
        initialLevel = 'Kepala Bagian Rumah Tangga';
      } else if (initialLevel.toLowerCase().contains('administrasi') || initialLevel.toLowerCase().contains('aset') || initialLevel.toLowerCase().contains('keuangan')) {
        initialLevel = 'Kabag. Keuangan dan Aset';
      } else if (initialLevel.toLowerCase().contains('sespri')) {
        initialLevel = 'Sespri';
      } else {
        initialLevel = 'Kepala Bagian Rumah Tangga';
      }
    }
    _selectedLevel = initialLevel;

    _selectedDiteruskan = [];
    _instruksiCtrl = TextEditingController(text: '');
    _instruksiFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _instruksiCtrl.dispose();
    _instruksiFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedDiteruskan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Pilih minimal 1 penerima disposisi')),
      );
      return;
    }
    if (_instruksiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Catatan instruksi tidak boleh kosong')),
      );
      return;
    }
    Navigator.pop(context, {
      'level': _selectedLevel,
      'diteruskan': _selectedDiteruskan,
      'instruksi': _instruksiCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKaro = _selectedLevel == 'Bapak Kepala Biro Umum';
    final currentOptions = isKaro ? _karoTargetOptions : _kabagTargetOptions;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📝 Disposisi Multi-Tujuan', style: AppTextStyles.h3),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Level Penandatangan Disposisi
            const Text('Pejabat Yang Mendisposisi', style: AppTextStyles.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _pejabatOptions.contains(_selectedLevel) ? _selectedLevel : _pejabatOptions.first,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _pejabatOptions.map((pejabat) {
                String label = pejabat;
                if (pejabat == 'Bapak Kepala Biro Umum') {
                  label = 'Bapak Kepala Biro Umum';
                } else if (pejabat == 'Kepala Bagian Rumah Tangga') {
                  label = 'Kabag. Rumah Tangga';
                }
                return DropdownMenuItem<String>(
                  value: pejabat,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLevel = val;
                    final isKaroNow = val == 'Bapak Kepala Biro Umum';
                    final availableTargets = isKaroNow ? _karoTargetOptions : _kabagTargetOptions;

                    _selectedDiteruskan = _selectedDiteruskan.where((t) => availableTargets.contains(t)).toList();
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Checkboxes Diteruskan Kepada Yth Multi Tujuan
            const Text('Diteruskan Kepada Yth. (Minimal 1) :', style: AppTextStyles.label),
            const SizedBox(height: 6),
            ...currentOptions.map((opt) {
              final isChecked = _selectedDiteruskan.contains(opt);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFF59E0B),
                title: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                value: isChecked,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      if (!_selectedDiteruskan.contains(opt)) _selectedDiteruskan.add(opt);
                    } else {
                      _selectedDiteruskan.remove(opt);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 14),

            // Catatan / Instruksi Disposisi
            const Text('Catatan / Instruksi Disposisi', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _instruksiCtrl,
              focusNode: _instruksiFocusNode,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan instruksi pimpinan di sini...',
              ),
            ),
            const SizedBox(height: 20),

            // Simpan Button dengan Anti-Spam Guard
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: widget.isSubmitting 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
                label: Text(
                  widget.isSubmitting ? 'Mengirim...' : 'Kirim Disposisi (Batch Insert)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ModalCatatanSelesaiDialog extends StatefulWidget {
  final DisposisiModel disposisi;

  const _ModalCatatanSelesaiDialog({required this.disposisi});

  @override
  State<_ModalCatatanSelesaiDialog> createState() => _ModalCatatanSelesaiDialogState();
}

class _ModalCatatanSelesaiDialogState extends State<_ModalCatatanSelesaiDialog> {
  late TextEditingController _catatanCtrl;
  late FocusNode _catatanFocusNode;

  @override
  void initState() {
    super.initState();
    _catatanCtrl = TextEditingController();
    _catatanFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _catatanFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _catatanCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Catatan pelaksanaan wajib diisi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('✅ CATATAN PELAKSANAAN TUGAS', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disposisi dari: ${widget.disposisi.dariJabatan}', style: AppTextStyles.caption),
            if (widget.disposisi.instruksi != null && widget.disposisi.instruksi!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instruksi:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${widget.disposisi.instruksi}"',
                      style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text('Catatan Pelaksanaan / Hasil Tugas:', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _catatanCtrl,
              focusNode: _catatanFocusNode,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan hasil pelaksanaan tugas di sini...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.check_circle_rounded, size: 16),
          label: const Text('Selesaikan Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
