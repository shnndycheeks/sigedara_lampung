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
import '../widgets/lembar_disposisi_widget.dart';

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
  bool _anyEdit = false;

  @override
  void initState() {
    super.initState();
    _arsip = widget.surat;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
    });
    try {
      final updated = await ArsipSuratService.getArsipById(_arsip.id);
      if (mounted) {
        setState(() {
          _arsip = updated;
          _loading = false;
        });
        await _loadSignedUrl();
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

    String fileUrl = _arsip.fileUrl;
    if (_arsip.filePath.isNotEmpty) {
      try {
        final freshSignedUrl = await Supabase.instance.client.storage
            .from('arsip-surat')
            .createSignedUrl(_arsip.filePath, 604800); // 7 days expiration
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
        "Silakan membaca surat terlebih dahulu, kemudian lakukan disposisi melalui Google Form berikut:\n\n"
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

  Future<void> _cetakLembarDisposisi() async {
    setState(() {
      _loading = true;
    });
    try {
      final pdfBytes = await generateLembarDisposisiPdf(_arsip);
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
          _loading = false;
        });
      }
    }
  }

  Future<void> _showModalIsiDisposisi() async {
    String selectedLevel = _arsip.penerimaLevel;
    List<String> selectedDiteruskan = List<String>.from(_arsip.diteruskanKepada);
    final instruksiCtrl = TextEditingController(text: _arsip.instruksiDisposisi);
    final agendaCtrl = TextEditingController(text: _arsip.noAgenda != '-' ? _arsip.noAgenda : '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isKaro = selectedLevel == 'Bapak Kepala Biro Umum';
            final currentOptions = isKaro
                ? [
                    'Kabag. Tata Usaha',
                    'Kabag. Rumah Tangga',
                    'Kabag. Administrasi dan Aset',
                    'Sespri',
                  ]
                : [
                    'Ka. Tim Kerja . Urusan Dalam',
                    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Gedung/Kantor',
                    'Ka. Tim Kerja . Pengelolaan dan Pemeliharaan Kendaraan',
                  ];

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
                        const Text('📝 Isi / Edit Lembar Disposisi', style: AppTextStyles.h3),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Level Penandatangan Disposisi
                    const Text('Pejabat Yang Mendingosisi', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLevel,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bapak Kepala Biro Umum',
                          child: Text('Bapak Kepala Biro Umum (Karo)'),
                        ),
                        DropdownMenuItem(
                          value: 'Kepala Bagian Rumah Tangga',
                          child: Text('Kepala Bagian Rumah Tangga (Kabag)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedLevel = val;
                            if (val == 'Bapak Kepala Biro Umum') {
                              selectedDiteruskan = ['Kabag. Tata Usaha', 'Kabag. Rumah Tangga'];
                            } else {
                              selectedDiteruskan = ['Ka. Tim Kerja . Urusan Dalam'];
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // No. Agenda Diterima
                    const Text('Nomor Agenda Diterima (Opsional)', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: agendaCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 045.2 / 128 / II.01',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Checkboxes Diteruskan Kepada Yth
                    const Text('Diteruskan Kepada Yth. :', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    ...currentOptions.map((opt) {
                      final isChecked = selectedDiteruskan.contains(opt);
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
                          setModalState(() {
                            if (val == true) {
                              if (!selectedDiteruskan.contains(opt)) selectedDiteruskan.add(opt);
                            } else {
                              selectedDiteruskan.remove(opt);
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
                      controller: instruksiCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan catatan instruksi pimpinan di sini...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text(
                          'Simpan & Kirim Disposisi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      // Update DB and refresh
      setState(() {
        _loading = true;
      });
      try {
        final isKaro = selectedLevel == 'Bapak Kepala Biro Umum';
        final newStatus = isKaro ? 'menunggu_kabag' : 'menunggu_katim';
        final pengirim = isKaro ? 'Kepala Biro Umum' : 'Kabag Rumah Tangga';
        final penerima = selectedDiteruskan.isNotEmpty ? selectedDiteruskan.join(', ') : (isKaro ? 'Kabag Rumah Tangga' : 'Ka. Tim Kerja');
        final statusText = isKaro ? 'Menunggu Disposisi Kabag Rumah Tangga' : 'Menunggu ${selectedDiteruskan.isNotEmpty ? selectedDiteruskan.first : "Ka. Tim Kerja"}';

        final List<Map<String, dynamic>> historyList = List<Map<String, dynamic>>.from(_arsip.riwayatDisposisi);
        historyList.add({
          'oleh': pengirim,
          'ke': penerima,
          'waktu': DateTime.now().toIso8601String(),
          'status': statusText,
          'instruksi': instruksiCtrl.text.trim().isNotEmpty ? instruksiCtrl.text.trim() : 'Surat didisposisikan.',
        });

        final updatedMap = Map<String, dynamic>.from(_arsip.deskripsi);
        updatedMap['penerima_level'] = selectedLevel;
        updatedMap['diteruskan_kepada'] = selectedDiteruskan;
        updatedMap['instruksi_disposisi'] = instruksiCtrl.text.trim();
        updatedMap['no_agenda'] = agendaCtrl.text.trim();
        updatedMap['status_pengiriman'] = newStatus;
        updatedMap['status_disposisi'] = newStatus;
        updatedMap['riwayat_disposisi'] = historyList;

        final targetRole = isKaro ? 'Kabag Rumah Tangga' : 'Ka. Tim Kerja';
        final nextStage = statusText;

        // Re-generate Lembar Disposisi PDF
        final tempSurat = ArsipSurat(
          id: _arsip.id,
          judul: _arsip.judul,
          kategori: _arsip.kategori,
          deskripsi: updatedMap,
          fileUrl: _arsip.fileUrl,
          filePath: _arsip.filePath,
          fileSize: _arsip.fileSize,
          createdAt: _arsip.createdAt,
          nomorSurat: _arsip.nomorSurat,
          tanggalSurat: _arsip.tanggalSurat,
          dari: _arsip.dari,
          kepada: _arsip.kepada,
          instruksiDisposisi: instruksiCtrl.text.trim(),
          tingkatUrgensi: _arsip.tingkatUrgensi,
          statusPengiriman: updatedMap['status_pengiriman'],
        );

        final newPdfBytes = await generateLembarDisposisiPdf(tempSurat);

        // Upload updated PDF to storage
        final uploadResult = await ArsipSuratService.uploadBerkasAsli(
          fileName: 'Lembar_Disposisi_${DateTime.now().millisecondsSinceEpoch}.pdf',
          fileBytes: newPdfBytes,
          mimeType: 'application/pdf',
        );

        await ArsipSuratService.updateArsip(
          id: _arsip.id,
          judul: _arsip.judul,
          kategori: _arsip.kategori,
          deskripsi: updatedMap,
          fileUrl: uploadResult['file_url'],
          filePath: uploadResult['file_path'],
          fileSize: newPdfBytes.length,
          oldFilePathToDelete: _arsip.filePath,
        );

        await _refreshData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Disposisi berhasil disimpan & diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Send WhatsApp notification automatically
        final message = "Assalamu'alaikum Wr. Wb.\n\n"
            "Yth. $targetRole,\n\n"
            "Terdapat pembaharuan alur disposisi surat masuk.\n\n"
            "━━━━━━━━━━━━━━\n\n"
            "Nomor Surat:\n${_arsip.nomorSurat}\n\n"
            "Perihal:\n${_arsip.judul}\n\n"
            "Asal Surat:\n${_arsip.dari}\n\n"
            "Status Disposisi:\n$nextStage\n\n"
            "Instruksi:\n${instruksiCtrl.text.trim().isNotEmpty ? instruksiCtrl.text.trim() : '-'}\n\n"
            "━━━━━━━━━━━━━━\n\n"
            "📄 Lembar Disposisi Digital:\n${_signedUrl ?? _arsip.fileUrl}\n\n"
            "Terima kasih.";

        final encodedMessage = Uri.encodeComponent(message);
        final phone = "62887437216916";
        final whatsappAppUri = Uri.parse("whatsapp://send?phone=$phone&text=$encodedMessage");
        final whatsappWebUri = Uri.parse("https://wa.me/$phone?text=$encodedMessage");

        try {
          if (await canLaunchUrl(whatsappAppUri)) {
            await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(whatsappWebUri)) {
            await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan disposisi: $e'),
              backgroundColor: AppColors.error,
            ),
          );
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
                  // LEMBAR DISPOSISI DIGITAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lembar Disposisi Digital', style: AppTextStyles.h3),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _showModalIsiDisposisi,
                            icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                            label: const Text('Isi Disposisi', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _cetakLembarDisposisi,
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
                                'Setelah tombol Kirim ke WhatsApp Kepala Biro ditekan, proses disposisi selanjutnya dilakukan melalui WhatsApp dan Google Form.\n\nSistem SIMASTER hanya digunakan sebagai media pengarsipan surat masuk.',
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

                  // TINDAKAN ALUR DISPOSISI
                  const Text('Tindakan Alur Disposisi & Persetujuan', style: AppTextStyles.h3),
                  const SizedBox(height: 12),

                  // Button 1: Kirim WA ke Karo (TU)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _kirimKeWhatsAppKepalaBiro,
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

                  // Button 2: Disposisi Karo -> Kabag Rumah Tangga
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _updateWorkflowStage('disposisi_kabag', 'Disposisi Karo ➔ Kabag Rumah Tangga', '62887437216916', 'Kabag Rumah Tangga'),
                      icon: const Icon(Icons.forward_to_inbox_rounded, color: Colors.white),
                      label: Text(
                        _arsip.statusPengiriman == 'disposisi_kabag'
                            ? '2. Disposisi ke Kabag Rumah Tangga (Terkirim)'
                            : '2. Teruskan Disposisi Karo ➔ Kabag Rumah Tangga',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 3: Disposisi Kabag -> Katim
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _updateWorkflowStage('disposisi_katim', 'Disposisi Kabag ➔ Ka. Tim Kerja', '62887437216916', 'Ka. Tim Kerja'),
                      icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
                      label: Text(
                        _arsip.statusPengiriman == 'disposisi_katim'
                            ? '3. Disposisi ke Ka. Tim Kerja (Terkirim)'
                            : '3. Teruskan Disposisi Kabag ➔ Ka. Tim Kerja (Katim)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button 4: Katim Setujui Pengajuan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : () => _updateWorkflowStage('disetujui_katim', 'Disetujui Katim (Selesai)', '62887437216916', 'Pemohon / Admin'),
                      icon: const Icon(Icons.verified_rounded, color: Colors.white),
                      label: Text(
                        _arsip.statusPengiriman == 'disetujui_katim'
                            ? '4. Pengajuan Disetujui Katim (Selesai)'
                            : '4. Setujui Pengajuan (Ka. Tim Kerja)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      key: ValueKey(_signedUrl ?? _arsip.fileUrl),
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
      ),
    );
  }

  Future<void> _onDirectDisposisiChanged(List<String> newDiteruskan, String newInstruksi, String newLevel) async {
    try {
      final updatedMap = Map<String, dynamic>.from(_arsip.deskripsi);
      updatedMap['penerima_level'] = newLevel;
      updatedMap['diteruskan_kepada'] = newDiteruskan;
      updatedMap['instruksi_disposisi'] = newInstruksi;

      final isKaro = newLevel.toLowerCase().contains('biro') || newLevel.toLowerCase().contains('karo');
      final newStatus = isKaro ? 'menunggu_kabag' : 'menunggu_katim';
      updatedMap['status_pengiriman'] = newStatus;
      updatedMap['status_disposisi'] = newStatus;

      await ArsipSuratService.updateArsip(
        id: _arsip.id,
        judul: _arsip.judul,
        kategori: _arsip.kategori,
        deskripsi: updatedMap,
        fileUrl: _arsip.fileUrl,
        filePath: _arsip.filePath,
        fileSize: _arsip.fileSize,
      );

      final updated = await ArsipSuratService.getArsipById(_arsip.id);
      if (mounted) {
        setState(() {
          _arsip = updated;
          _anyEdit = true;
        });
      }
    } catch (e) {
      debugPrint('Error updating direct disposisi: $e');
    }
  }

  Future<void> _updateWorkflowStage(String newStatus, String stageName, String phone, String targetRole) async {
    setState(() {
      _loading = true;
    });
    try {
      final List<Map<String, dynamic>> historyList = List<Map<String, dynamic>>.from(_arsip.riwayatDisposisi);
      String oleh = 'Admin';
      String ke = targetRole;

      if (newStatus == 'menunggu_karo') {
        oleh = 'Admin TU';
        ke = 'Kepala Biro Umum';
      } else if (newStatus == 'menunggu_kabag' || newStatus == 'disposisi_kabag') {
        oleh = 'Kepala Biro Umum';
        ke = 'Kabag Rumah Tangga';
      } else if (newStatus == 'menunggu_katim' || newStatus == 'disposisi_katim') {
        oleh = 'Kabag Rumah Tangga';
        ke = _arsip.diteruskanKepada.isNotEmpty ? _arsip.diteruskanKepada.first : 'Ka. Tim Kerja';
      } else if (newStatus == 'selesai' || newStatus == 'disetujui_katim') {
        oleh = _arsip.diteruskanKepada.isNotEmpty ? _arsip.diteruskanKepada.first : 'Ka. Tim Kerja';
        ke = 'Selesai';
      }

      historyList.add({
        'oleh': oleh,
        'ke': ke,
        'waktu': DateTime.now().toIso8601String(),
        'status': stageName,
        'instruksi': newStatus == 'selesai' || newStatus == 'disetujui_katim'
            ? 'Pekerjaan telah dilaksanakan dan selesai.'
            : (_arsip.instruksiDisposisi.isNotEmpty ? _arsip.instruksiDisposisi : 'Status alur diperbarui.'),
      });

      final updatedDeskripsi = Map<String, dynamic>.from(_arsip.deskripsi);
      updatedDeskripsi['status_pengiriman'] = newStatus;
      updatedDeskripsi['status_disposisi'] = newStatus;
      updatedDeskripsi['riwayat_disposisi'] = historyList;

      await ArsipSuratService.updateArsip(
        id: _arsip.id,
        judul: _arsip.judul,
        kategori: _arsip.kategori,
        deskripsi: updatedDeskripsi,
        fileUrl: _arsip.fileUrl,
        filePath: _arsip.filePath,
        fileSize: _arsip.fileSize,
      );
      
      final updated = await ArsipSuratService.getArsipById(_arsip.id);
      if (mounted) {
        setState(() {
          _arsip = updated;
          _anyEdit = true;
          _loading = false;
        });
      }

      final message = "Assalamu'alaikum Wr. Wb.\n\n"
          "Yth. $targetRole,\n\n"
          "Terdapat pembaharuan alur disposisi surat masuk.\n\n"
          "━━━━━━━━━━━━━━\n\n"
          "Nomor Surat:\n${_arsip.nomorSurat}\n\n"
          "Perihal:\n${_arsip.judul}\n\n"
          "Asal Surat:\n${_arsip.dari}\n\n"
          "Status Disposisi:\n$stageName\n\n"
          "Instruksi:\n${_arsip.instruksiDisposisi.isNotEmpty ? _arsip.instruksiDisposisi : '-'}\n\n"
          "━━━━━━━━━━━━━━\n\n"
          "📄 Lembar Disposisi & Surat:\n${_signedUrl ?? _arsip.fileUrl}\n\n"
          "Terima kasih.";

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappAppUri = Uri.parse("whatsapp://send?phone=$phone&text=$encodedMessage");
      final whatsappWebUri = Uri.parse("https://wa.me/$phone?text=$encodedMessage");
      
      try {
        if (await canLaunchUrl(whatsappAppUri)) {
          await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(whatsappWebUri)) {
          await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui alur disposisi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildAlurDisposisiTimeline() {
    final status = _arsip.statusPengiriman;

    int currentStep = 1;
    if (status == 'sudah_dikirim_karo') currentStep = 1;
    if (status == 'disposisi_kabag') currentStep = 2;
    if (status == 'disposisi_katim') currentStep = 3;
    if (status == 'disetujui_katim') currentStep = 4;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alur Disposisi & Persetujuan', style: AppTextStyles.h3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: currentStep == 4 ? AppColors.success.withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentStep == 4 ? AppColors.success : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  currentStep == 4 ? 'Disetujui Katim' : 'Tahap $currentStep dari 4',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentStep == 4 ? AppColors.success : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Alur: TU Scan ➔ Karo (Biro) ➔ Kabag Rumah Tangga ➔ Katim (Persetujuan)',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepItem(1, 'TU Scan', currentStep >= 1, currentStep == 1),
              _buildStepLine(currentStep >= 2),
              _buildStepItem(2, 'Karo', currentStep >= 2, currentStep == 2),
              _buildStepLine(currentStep >= 3),
              _buildStepItem(3, 'Kabag', currentStep >= 3, currentStep == 3),
              _buildStepLine(currentStep >= 4),
              _buildStepItem(4, 'Katim', currentStep >= 4, currentStep == 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNum, String title, bool isDone, bool isCurrent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? (stepNum == 4 && isDone ? AppColors.success : const Color(0xFFF59E0B))
                  : Colors.grey.shade200,
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
    final history = _arsip.riwayatDisposisi;
    if (history.isEmpty) return const SizedBox.shrink();

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📜 Riwayat Transparan Disposisi', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          const Text(
            'Catatan riwayat audit waktu, pengirim, penerima, dan instruksi.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...history.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final oleh = item['oleh']?.toString() ?? '-';
            final ke = item['ke']?.toString() ?? '-';
            final statusStr = item['status']?.toString() ?? '-';
            final instruksiStr = item['instruksi']?.toString() ?? '-';
            final waktuRaw = item['waktu']?.toString();
            DateTime? dt;
            if (waktuRaw != null) dt = DateTime.tryParse(waktuRaw);

            String dua(int n) => n.toString().padLeft(2, '0');
            final waktuFormatted = dt != null
                ? '${dua(dt.day)}/${dua(dt.month)}/${dt.year} ${dua(dt.hour)}:${dua(dt.minute)} WIB'
                : '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: idx == history.length - 1 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
                                '$oleh ➔ $ke',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            Text(
                              waktuFormatted,
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Status: $statusStr',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                        if (instruksiStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Instruksi: "$instruksiStr"',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
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
