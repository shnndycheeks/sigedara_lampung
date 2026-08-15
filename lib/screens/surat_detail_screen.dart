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
import '../services/permission_service.dart';
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
  RealtimeChannel? _disposisiSubscription;

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _arsip = widget.surat;
    _refreshData();
    _setupRealtimeSubscription();
    ActivityLogService.logActivity(
      action: 'PREVIEW_SURAT',
      suratId: _arsip.id,
      details: {'judul': _arsip.judul, 'nomor_surat': _arsip.nomorSurat},
    );
  }

  void _setupRealtimeSubscription() {
    try {
      _disposisiSubscription = Supabase.instance.client
          .channel('realtime_disposisi_${_arsip.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'disposisi',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'surat_id',
              value: _arsip.id,
            ),
            callback: (payload) {
              debugPrint('REALTIME DISPOSISI EVENT: ${payload.eventType}');
              if (mounted) {
                _refreshData(showLoading: false);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'arsip_surat',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: _arsip.id,
            ),
            callback: (payload) {
              debugPrint('REALTIME ARSIP SURAT EVENT: ${payload.eventType}');
              if (mounted) {
                _refreshData(showLoading: false);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up realtime subscription: $e');
    }
  }

  @override
  void dispose() {
    _disposisiSubscription?.unsubscribe();
    super.dispose();
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
              debugPrint(
                "Header = ${pdfBytes[0]} ${pdfBytes[1]} ${pdfBytes[2]} ${pdfBytes[3]}",
              );
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

    final message =
        "Assalamu'alaikum Wr. Wb.\n\n"
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
    final whatsappAppUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=$encodedMessage",
    );
    final whatsappWebUri = Uri.parse(
      "https://wa.me/$phone?text=$encodedMessage",
    );

    try {
      bool launched = false;
      try {
        if (await canLaunchUrl(whatsappAppUri)) {
          launched = await launchUrl(
            whatsappAppUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {}

      if (!launched) {
        try {
          if (await canLaunchUrl(whatsappWebUri)) {
            launched = await launchUrl(
              whatsappWebUri,
              mode: LaunchMode.externalApplication,
            );
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
            content: Text(
              e.toString().contains('tidak ditemukan')
                  ? '❌ WhatsApp tidak ditemukan pada perangkat.'
                  : '❌ Gagal memicu WhatsApp: $e',
            ),
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

    final message =
        "Assalamu'alaikum Wr. Wb.\n\n"
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
    final whatsappAppUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=$encodedMessage",
    );
    final whatsappWebUri = Uri.parse(
      "https://wa.me/$phone?text=$encodedMessage",
    );

    try {
      bool launched = false;
      try {
        if (await canLaunchUrl(whatsappAppUri)) {
          launched = await launchUrl(
            whatsappAppUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {}

      if (!launched) {
        try {
          if (await canLaunchUrl(whatsappWebUri)) {
            launched = await launchUrl(
              whatsappWebUri,
              mode: LaunchMode.externalApplication,
            );
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
            content: Text(
              e.toString().contains('tidak ditemukan')
                  ? '❌ WhatsApp tidak ditemukan pada perangkat.'
                  : '❌ Gagal memicu WhatsApp: $e',
            ),
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

    final message =
        "Assalamu'alaikum Wr. Wb.\n\n"
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
    final whatsappAppUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=$encodedMessage",
    );
    final whatsappWebUri = Uri.parse(
      "https://wa.me/$phone?text=$encodedMessage",
    );

    try {
      bool launched = false;
      try {
        if (await canLaunchUrl(whatsappAppUri)) {
          launched = await launchUrl(
            whatsappAppUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {}

      if (!launched) {
        try {
          if (await canLaunchUrl(whatsappWebUri)) {
            launched = await launchUrl(
              whatsappWebUri,
              mode: LaunchMode.externalApplication,
            );
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
            content: Text(
              e.toString().contains('tidak ditemukan')
                  ? '❌ WhatsApp tidak ditemukan pada perangkat.'
                  : '❌ Gagal memicu WhatsApp: $e',
            ),
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
          return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
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
    final clean = raw.trim();
    if (clean == 'karo' || clean == 'kepala_biro') return 'Bapak Kepala Biro Umum';
    if (clean == 'kabag_rt_jab' || clean == 'kabag_rt') return 'Kabag. Rumah Tangga';
    if (clean == 'kabag_tu_jab' || clean == 'kabag_tu') return 'Kabag. Tata Usaha';
    if (clean == 'kabag_asset_jab' || clean == 'kabag_aset' || clean == 'kabag_keuangan') return 'Kabag. Keuangan dan Aset';
    if (clean == 'katim_ud_jab') return 'Ka. Tim Kerja . Urusan Dalam';
    if (clean == 'katim_gd_jab') return 'Ka. Tim Kerja . Pengelolaan & Pemeliharaan Gedung 1';
    if (clean == 'katim_kd_jab') return 'Ka. Tim Kerja . Pengelolaan & Pemeliharaan Kendaraan';

    return raw
        .replaceAll('Kepala Bagian Rumah Tangga', 'Kabag. Rumah Tangga')
        .replaceAll('Kepala Bagian Tata Usaha', 'Kabag. Tata Usaha')
        .replaceAll(
          'Kepala Bagian Administrasi dan Aset',
          'Kabag. Keuangan dan Aset',
        )
        .replaceAll(
          'Kepala Bagian Keuangan dan Aset',
          'Kabag. Keuangan dan Aset',
        )
        .replaceAll('Kabag. Administrasi dan Aset', 'Kabag. Keuangan dan Aset')
        .replaceAll('kabag_rt_jab', 'Kabag. Rumah Tangga')
        .replaceAll('kabag_tu_jab', 'Kabag. Tata Usaha')
        .replaceAll('kabag_asset_jab', 'Kabag. Keuangan dan Aset');
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
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
      await ArsipSuratService.hapusArsip(
        id: _arsip.id,
        filePath: _arsip.filePath,
      );
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

      final isActualPdf =
          bytes.length >= 4 &&
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

      await Printing.layoutPdf(onLayout: (format) => pdfBytes);
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
      await Printing.layoutPdf(onLayout: (format) => pdfBytes);
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
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
  Future<void> _showModalIsiDisposisi({bool isKaro = true}) async {
    debugPrint('===== DISPOSISI FLOW (isKaro: $isKaro) =====');
    debugPrint('STEP 1: OPEN FORM MODAL');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _ModalIsiDisposisiSheet(surat: _arsip, isKaro: isKaro, isSubmitting: _isSubmitting),
    );

    if (result != null) {
      debugPrint('STEP 2: SUBMITTED FORM WITH DATA: $result');
      final selectedDiteruskan = result['diteruskan'] as List<String>;
      final instruksiText = result['instruksi'] as String;

      setState(() {
        _isSubmitting = true;
      });

      try {
        if (currentUser == null) {
          throw Exception('Sesi login telah berakhir. Silakan login kembali.');
        }

        await PermissionService.loadPermissions();

        final rawJabatan = (PermissionService.jabatanId ?? '').toLowerCase();
        final rawRole = (PermissionService.roleId ?? '').toLowerCase();

        String dariRole;
        String dariJabatan;

        if (isKaro) {
          dariRole = 'kepala_biro';
          dariJabatan = 'karo';
        } else {
          if (rawJabatan.contains('tu') || rawRole.contains('tu')) {
            dariRole = 'kabag_tu';
            dariJabatan = 'kabag_tu_jab';
          } else if (rawJabatan.contains('rt') || rawRole.contains('rt')) {
            dariRole = 'kabag_rt';
            dariJabatan = 'kabag_rt_jab';
          } else {
            dariRole = 'kabag_aset';
            dariJabatan = 'kabag_asset_jab';
          }
        }

        debugPrint(
          'STEP 3: RESOLVING TARGET PEGAWAI FOR ${selectedDiteruskan.length} RECIPIENTS...',
        );
        final activePegawai = await ReferenceService.getPegawaiAktif();

        final List<Map<String, String>> penerimaList = [];
        for (final targetJabatan in selectedDiteruskan) {
          final matched = activePegawai.where((p) {
            final jName = (p.jabatan?.namaJabatan ?? '')
                .toLowerCase()
                .replaceAll('kepala bagian', 'kabag')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final rName = (p.role?.namaRole ?? '')
                .toLowerCase()
                .replaceAll('_', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final search = targetJabatan
                .toLowerCase()
                .replaceAll('kepala bagian', 'kabag')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();
            final cleanRole = p.roleId
                .toLowerCase()
                .replaceAll('_', '')
                .replaceAll('.', '')
                .replaceAll(' ', '')
                .trim();

            if (jName == search) return true;
            if (jName.contains(search) || search.contains(jName)) return true;
            if (rName.contains(search) || search.contains(rName)) return true;

            // Role mapping checks
            if (search.contains('kabagrumahtangga') &&
                cleanRole.contains('kabagrt')) {
              return true;
            }
            if (search.contains('kabagtatausaha') &&
                cleanRole.contains('kabagtu')) {
              return true;
            }
            if (search.contains('kabagkeuangandanaset') &&
                cleanRole.contains('kabagaset')) {
              return true;
            }
            if (search.contains('kabagadministrasidanaset') &&
                cleanRole.contains('kabagaset')) {
              return true;
            }
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
            throw Exception(
              'Tidak ada pegawai aktif di database untuk menerima disposisi ($targetJabatan)',
            );
          }
        }

        String? parentId;
        if (_arsip.listDisposisi.isNotEmpty) {
          parentId = _arsip.listDisposisi.last.id;
        }

        final ttdPath = PermissionService.isKaro
            ? 'signatures/default/ttd_karo.png'
            : dariRole == 'kabag_tu'
                ? 'signatures/default/ttd_kabag_tu.png'
                : dariRole == 'kabag_rt'
                    ? 'signatures/default/ttd_kabag_rt.png'
                    : 'signatures/default/ttd_kabag_aset.png';

        debugPrint('STEP 4: INSERTING DISPOSISI TO DATABASE...');
        await DisposisiService.kirimDisposisiMulti(
          suratId: _arsip.id,
          parentDisposisiId: parentId,
          dariUserId: currentUser!.id,
          dariRole: dariRole,
          dariJabatan: dariJabatan,
          penerimaList: penerimaList,
          instruksi: instruksiText,
          ttdPng: ttdPath,
        );
        debugPrint('STEP 5: INSERT SUCCESSFUL');

        await ActivityLogService.logActivity(
          action: 'DISPOSISI_KIRIM',
          suratId: _arsip.id,
          details: {'penerima': selectedDiteruskan, 'instruksi': instruksiText},
        );

        debugPrint('STEP 6: RELOADING SURAT DATA SILENTLY...');
        await _refreshData(showLoading: false);
        debugPrint(
          'STEP 7: LOADED ${_arsip.listDisposisi.length} DISPOSISI RECORDS',
        );
        debugPrint('STEP 8: UI UPDATED SUCCESSFULLY');
        debugPrint('==========================');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Disposisi berhasil dikirim ke ${selectedDiteruskan.length} penerima!',
            ),
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

  bool get _canEditDeleteSurat {
    if (PermissionService.isAdmin) return true;
    final isTu = PermissionService.isTu;
    final isUploader = currentUser != null && currentUser!.id == _arsip.uploadedBy;
    final isMenungguKaro = _arsip.statusGlobal.toLowerCase() == 'menunggu_karo';
    return isTu && isUploader && isMenungguKaro;
  }

  bool get _canUserDisposisi {
    if (PermissionService.isTu) return false;
    final status = _arsip.statusGlobal.toLowerCase();
    if (status == 'menunggu_karo' || _arsip.listDisposisi.isEmpty) {
      return PermissionService.isKaro;
    } else if (status == 'menunggu_kabag') {
      if (!PermissionService.isKabag) return false;
      final userJabatan = (PermissionService.jabatanId ?? '').toLowerCase();
      final targets = _arsip.listKabagTarget.map((t) => t.toLowerCase()).toList();
      if (targets.isEmpty) return true;
      return targets.any((t) => t.contains(userJabatan) || userJabatan.contains(t) || _isKabagJabatanMatch(t, userJabatan));
    }
    return false;
  }

  bool get _canUserComplete {
    final status = _arsip.statusGlobal.toLowerCase();
    if (status != 'menunggu_katim') return false;
    if (!PermissionService.isKatim) return false;
    final userJabatan = (PermissionService.jabatanId ?? '').toLowerCase();
    final targets = _arsip.listKatimTarget.map((t) => t.toLowerCase()).toList();
    if (targets.isEmpty) return true;
    return targets.any((t) => t.contains(userJabatan) || userJabatan.contains(t) || _isKatimJabatanMatch(t, userJabatan));
  }

  bool _isKabagJabatanMatch(String targetLabel, String userJabatanId) {
    final t = targetLabel.toLowerCase();
    final j = userJabatanId.toLowerCase();
    if (t.contains('tata usaha') && j.contains('tu')) {
      return true;
    }
    if (t.contains('rumah tangga') && j.contains('rt')) {
      return true;
    }
    if ((t.contains('keuangan') || t.contains('aset') || t.contains('administrasi')) &&
        (j.contains('asset') || j.contains('aset') || j.contains('keu'))) {
      return true;
    }
    return false;
  }

  bool _isKatimJabatanMatch(String targetLabel, String userJabatanId) {
    final t = targetLabel.toLowerCase();
    final j = userJabatanId.toLowerCase();
    if (t.contains('urusan dalam') && j.contains('ud')) return true;
    if (t.contains('gedung') && j.contains('gd')) return true;
    if (t.contains('kendaraan') && j.contains('kd')) return true;
    return false;
  }

  Widget _buildDynamicActionButton() {
    final status = _arsip.statusGlobal.toLowerCase();

    if (status == 'menunggu_karo') {
      final canAct = _canUserDisposisi;
      return ElevatedButton.icon(
        onPressed: (canAct && !_loading && !_isSubmitting) ? _showModalIsiDisposisi : null,
        icon: const Icon(Icons.forward_to_inbox_rounded, color: Colors.white),
        label: Text(
          canAct
              ? '2. Buat & Kirim Disposisi Multi-Tujuan (Karo ➔ Kabag)'
              : '2. Disposisi Surat (Hanya Kepala Biro)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canAct ? const Color(0xFFF59E0B) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (status == 'menunggu_kabag') {
      final canAct = _canUserDisposisi;
      return ElevatedButton.icon(
        onPressed: (canAct && !_loading && !_isSubmitting) ? _showModalIsiDisposisi : null,
        icon: const Icon(Icons.forward_to_inbox_rounded, color: Colors.white),
        label: Text(
          canAct
              ? '2. Buat & Kirim Disposisi Multi-Tujuan (Kabag ➔ Katim)'
              : '2. Disposisi Lanjutan (Hanya Kabag Dituju)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canAct ? const Color(0xFFF59E0B) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (status == 'menunggu_katim') {
      final canAct = _canUserComplete;
      DisposisiModel? pendingDisp;
      if (_arsip.listDisposisi.isNotEmpty) {
        pendingDisp = _arsip.listDisposisi.last;
      }
      return ElevatedButton.icon(
        onPressed: (canAct && !_loading && !_isSubmitting && pendingDisp != null)
            ? () => _showModalCatatanSelesai(pendingDisp!)
            : null,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: Text(
          canAct
              ? '2. Selesaikan Perintah & Isi Catatan (Katim)'
              : '2. Penyelesaian Perintah (Hanya Katim Dituju)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canAct ? AppColors.success : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (status == 'selesai') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text(
              'Alur Disposisi & Perintah Telah Selesai',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: (_canUserDisposisi && !_loading && !_isSubmitting) ? _showModalIsiDisposisi : null,
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
      );
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
            if (_canEditDeleteSurat) ...[
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

                    LembarDisposisiWidget(
                      surat: _arsip,
                      onIsiDisposisiKaro: () => _showModalIsiDisposisi(isKaro: true),
                      onIsiDisposisiKabag: () => _showModalIsiDisposisi(isKaro: false),
                      onCetak: _cetakLembarDisposisi,
                      isKaroActionEnabled: _canUserDisposisi &&
                          (_arsip.statusGlobal.toLowerCase() == 'menunggu_karo' ||
                              _arsip.listDisposisi.isEmpty),
                      isKabagActionEnabled: _canUserDisposisi &&
                          _arsip.statusGlobal.toLowerCase() == 'menunggu_kabag',
                      isSubmitting: _loading || _isSubmitting,
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
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
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
                          _buildInfoRow(
                            'Tanggal Surat',
                            _formatTanggal(_arsip.tanggalSurat),
                          ),
                          _buildInfoRow('Kategori', _arsip.kategori),
                          if (_arsip.kepada.isNotEmpty)
                            _buildInfoRow('Penerima Disposisi', _arsip.kepada),
                          if (_arsip.instruksiDisposisi.isNotEmpty)
                            _buildInfoRow(
                              'Instruksi Disposisi',
                              _arsip.instruksiDisposisi,
                            ),
                          _buildInfoRow(
                            'Status Global Surat',
                            _arsip.statusGlobal.toUpperCase(),
                            isStatus: true,
                          ),
                          if (_arsip.fileSize != null)
                            _buildInfoRow(
                              'Ukuran Berkas',
                              '${(_arsip.fileSize! / 1024).toStringAsFixed(1)} KB',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TINDAKAN ALUR DISPOSISI
                    const Text(
                      'Tindakan Alur Disposisi & Persetujuan',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 12),

                    // Button 1: Kirim WA ke Karo (TU)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _isSubmitting)
                            ? null
                            : _kirimKeWhatsAppKepalaBiro,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          _arsip.statusPengiriman == 'belum_dikirim_karo'
                              ? '1. Kirim WA ke Karo (Bapak Kepala Biro)'
                              : '1. Kirim Ulang WA ke Karo',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Button 1B: Kirim WA ke Kabag
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _isSubmitting)
                            ? null
                            : _kirimKeWhatsAppKabag,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Kirim WA ke Kabag',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Button 1C: Kirim WA ke Katim
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _isSubmitting)
                            ? null
                            : _kirimKeWhatsAppKatim,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Kirim WA ke Katim',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dynamic Action Button (Button 2)
                    SizedBox(
                      width: double.infinity,
                      child: _buildDynamicActionButton(),
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
                                          debugPrint(
                                            "PDF bytes = ${_pdfBytes!.length}",
                                          );
                                          return SfPdfViewer.memory(
                                            _pdfBytes!,
                                            key: ValueKey(_pdfBytes),
                                            onDocumentLoaded: (details) {
                                              debugPrint(
                                                "===== PDF LOADED =====",
                                              );
                                              debugPrint(
                                                "Pages : ${details.document.pages.count}",
                                              );
                                              debugPrint(
                                                "======================",
                                              );
                                            },
                                            onDocumentLoadFailed: (details) {
                                              debugPrint(
                                                "===== PDF FAILED =====",
                                              );
                                              debugPrint(
                                                "Error : ${details.error}",
                                              );
                                              debugPrint(
                                                "Description : ${details.description}",
                                              );
                                              debugPrint(
                                                "======================",
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : (_tempPdfFile != null &&
                                              _tempPdfFile!.existsSync()
                                          ? Builder(
                                              builder: (context) {
                                                debugPrint(
                                                  '=== DEBUG PREVIEW STEP 6: Rendering PDF FILE FALLBACK ===',
                                                );
                                                return SfPdfViewer.file(
                                                  _tempPdfFile!,
                                                  key: ValueKey(
                                                    _tempPdfFile!.path,
                                                  ),
                                                  onDocumentLoaded: (details) =>
                                                      debugPrint(
                                                        '=== STEP 6 PDF FILE BERHASIL DIMUAT (Pages: ${details.document.pages.count}) ===',
                                                      ),
                                                  onDocumentLoadFailed:
                                                      (details) => debugPrint(
                                                        '=== STEP 6 PDF FILE GAGAL DIMUAT: ${details.description} ===',
                                                      ),
                                                );
                                              },
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )))
                              : Builder(
                                  builder: (context) {
                                    debugPrint(
                                      '=== DEBUG PREVIEW STEP 4: Rendering IMAGE NETWORK ===',
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FullScreenImageScreen(
                                                  imageUrl:
                                                      _signedUrl ??
                                                      _arsip.fileUrl,
                                                  heroTag:
                                                      'arsip_image_${_arsip.id}',
                                                ),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'arsip_image_${_arsip.id}',
                                        child: Image.network(
                                          _signedUrl ?? _arsip.fileUrl,
                                          key: ValueKey(
                                            _signedUrl ?? _arsip.fileUrl,
                                          ),
                                          fit: BoxFit.contain,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 48,
                                                    color: AppColors.textHint,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Gagal memuat gambar preview',
                                                  ),
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
                        subtitle:
                            'Harap sunting arsip untuk mengunggah berkas surat.',
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
                  color: percent == 100.0
                      ? AppColors.success
                      : const Color(0xFFF59E0B),
                ),
              ),
              Text(
                '${percent.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildAlurDisposisiTimeline() {
    final list = _arsip.listDisposisi;

    // STEP 1: TU Scan (True once letter exists)
    final bool isTuDone = true;

    // STEP 2: Karo (True once Karo sends initial disposition or status is past Karo)
    final bool isKaroDone = _arsip.listKaroDisposisi.isNotEmpty ||
        list.any(
          (d) =>
              d.dariJabatan.toLowerCase().contains('biro') ||
              d.dariJabatan.toLowerCase().contains('karo') ||
              d.dariRole.toLowerCase().contains('karo') ||
              d.dariRole.toLowerCase().contains('kepala_biro'),
        ) ||
        _arsip.statusGlobal.toLowerCase() != 'menunggu_karo';

    // STEP 3: Kabag / Sespri (True once Kabag forwards disposition or status is past Kabag)
    final bool isKabagSespriDone = _arsip.listKabagDisposisi.isNotEmpty ||
        list.any(
          (d) =>
              d.dariJabatan.toLowerCase().contains('bagian') ||
              d.dariJabatan.toLowerCase().contains('kabag') ||
              d.dariJabatan.toLowerCase().contains('sespri') ||
              d.dariRole.toLowerCase().contains('kabag'),
        ) ||
        _arsip.statusGlobal.toLowerCase() == 'menunggu_katim' ||
        _arsip.statusGlobal.toLowerCase() == 'selesai';

    // STEP 4: Katim (True ONLY when Katim task has status_disposisi == 'selesai' OR has Catatan)
    final bool isKatimDone = _arsip.statusGlobal.toLowerCase() == 'selesai' ||
        list.any((d) {
          final isKatim =
              d.kepadaJabatan.toLowerCase().contains('tim kerja') ||
              d.kepadaJabatan.toLowerCase().contains('katim') ||
              d.dariJabatan.toLowerCase().contains('tim kerja') ||
              d.dariJabatan.toLowerCase().contains('katim');
          final isSelesai = d.statusDisposisi.toLowerCase() == 'selesai';
          final hasCatatan = (d.catatan ?? '').trim().isNotEmpty;
          return isKatim && (isSelesai || hasCatatan);
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
              const Text(
                'Alur Disposisi & Persetujuan',
                style: AppTextStyles.h3,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  isKatimDone
                      ? 'Selesai'
                      : (list.isEmpty ? 'Menunggu Disposisi' : 'Dalam Proses'),
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

  Widget _buildStepItem(
    int stepNum,
    String title,
    bool isDone,
    bool isCurrent,
  ) {
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent || isDone
                  ? FontWeight.bold
                  : FontWeight.normal,
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
          const Text(
            '📜 Timeline Disposisi Bertingkat',
            style: AppTextStyles.h3,
          ),
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

            final isSender =
                activeUserId.isNotEmpty && item.dariUserId == activeUserId;
            final isRecipient =
                activeUserId.isNotEmpty &&
                (item.kepadaUserId == activeUserId ||
                    item.kepadaUserId.isEmpty);

            final isCanBeRecalled =
                isSender &&
                (item.statusDisposisi == 'pending' ||
                    item.statusDisposisi == 'dibaca');
            final isKatimTarget =
                item.kepadaJabatan.toLowerCase().contains('tim kerja') ||
                item.kepadaJabatan.toLowerCase().contains('katim') ||
                item.kepadaRole.toLowerCase().contains('katim');

            final isCanBeCompleted =
                (item.statusDisposisi == 'pending' ||
                    item.statusDisposisi == 'dibaca' ||
                    item.statusDisposisi == 'diproses') &&
                (isRecipient || PermissionService.isKatim || PermissionService.isAdmin || isKatimTarget);

            String dua(int n) => n.toString().padLeft(2, '0');
            final dt = item.assignedAt;
            final waktuFormatted =
                '${dua(dt.day)}/${dua(dt.month)}/${dt.year} ${dua(dt.hour)}:${dua(dt.minute)} WIB';

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
                      color: item.statusDisposisi == 'selesai'
                          ? AppColors.success
                          : const Color(0xFFF59E0B),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              waktuFormatted,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
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
                                onTap: (_loading || _isSubmitting)
                                    ? null
                                    : () => _tarikDisposisi(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    border: Border.all(
                                      color: Colors.orange.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.undo_rounded,
                                        size: 10,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Tarik Disposisi',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (isCanBeCompleted) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: (_loading || _isSubmitting)
                                    ? null
                                    : () => _showModalCatatanSelesai(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x20000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selesaikan',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.instruksi != null &&
                            item.instruksi!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Instruksi: "${item.instruksi}"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        if (item.catatan != null &&
                            item.catatan!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Catatan Pelaksanaan: "${item.catatan}"',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                        if (item.completedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Waktu Selesai: ${dua(item.completedAt!.day)}/${dua(item.completedAt!.month)}/${item.completedAt!.year} ${dua(item.completedAt!.hour)}:${dua(item.completedAt!.minute)} WIB',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
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
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
  final bool isKaro;

  const _ModalIsiDisposisiSheet({
    super.key,
    required this.surat,
    required this.isSubmitting,
    this.isKaro = true,
  });

  @override
  State<_ModalIsiDisposisiSheet> createState() =>
      _ModalIsiDisposisiSheetState();
}

class _ModalIsiDisposisiSheetState extends State<_ModalIsiDisposisiSheet> {
  static const Map<String, String> _karoTargets = {
    'Kabag. Tata Usaha': 'kabag_tu_jab',
    'Kabag. Rumah Tangga': 'kabag_rt_jab',
    'Kabag. Keuangan dan Aset': 'kabag_asset_jab',
  };

  static const Map<String, String> _kabagTargets = {
    'Ka. Tim Kerja . Urusan Dalam': 'katim_ud_jab',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 1': 'katim_gd_jab',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung 2': 'katim_gd_jab',
    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan': 'katim_kd_jab',
  };

  late List<String> _selectedDiteruskan;
  late TextEditingController _instruksiCtrl;
  late FocusNode _instruksiFocusNode;

  @override
  void initState() {
    super.initState();

    _selectedDiteruskan = [];
    _instruksiCtrl = TextEditingController();
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
        const SnackBar(content: Text('Pilih minimal 1 penerima disposisi')),
      );
      return;
    }

    if (_instruksiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan instruksi tidak boleh kosong')),
      );
      return;
    }

    Navigator.pop(context, {
      'diteruskan': _selectedDiteruskan,
      'instruksi': _instruksiCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKaroTurn = widget.isKaro;

    final Map<String, String> targetOptions = isKaroTurn
        ? _karoTargets
        : _kabagTargets;

    final String sheetTitle = isKaroTurn
        ? 'Disposisi Karo ➔ Kabag'
        : 'Disposisi Kabag ➔ Katim';

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
                Text(
                  sheetTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PENERIMA CHECKBOX LIST
            const Text(
              'Diteruskan Kepada Yth. (Minimal 1):',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 6),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: targetOptions.keys.map((targetLabel) {
                  final isChecked = _selectedDiteruskan.contains(targetLabel);
                  return CheckboxListTile(
                    title: Text(
                      targetLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: isChecked,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedDiteruskan.add(targetLabel);
                        } else {
                          _selectedDiteruskan.remove(targetLabel);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // INSTRUKSI DISPOSISI
            const Text(
              'Catatan / Instruksi Disposisi:',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _instruksiCtrl,
              focusNode: _instruksiFocusNode,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tuliskan catatan instruksi di sini...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  widget.isSubmitting ? 'Mengirim...' : 'Kirim Disposisi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
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
  State<_ModalCatatanSelesaiDialog> createState() =>
      _ModalCatatanSelesaiDialogState();
}

class _ModalCatatanSelesaiDialogState
    extends State<_ModalCatatanSelesaiDialog> {
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
      title: const Text('CATATAN PELAKSANAAN TUGAS', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disposisi dari: ${widget.disposisi.dariJabatan}',
              style: AppTextStyles.caption,
            ),

            if (widget.disposisi.instruksi != null &&
                widget.disposisi.instruksi!.isNotEmpty) ...[
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  widget.disposisi.instruksi!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 14),

            const Text(
              'Catatan Pelaksanaan / Hasil Tugas:',
              style: AppTextStyles.label,
            ),

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
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.check_circle_rounded, size: 16),
          label: const Text(
            'Selesaikan Tugas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
