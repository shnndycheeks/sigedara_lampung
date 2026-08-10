import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/arsip_surat_model.dart';
import '../theme/app_theme.dart';
import '../services/arsip_surat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common_widgets.dart';
import '../widgets/lembar_disposisi_widget.dart';

class TambahEditSuratScreen extends StatefulWidget {
  final ArsipSurat? existing;
  const TambahEditSuratScreen({super.key, this.existing});

  @override
  State<TambahEditSuratScreen> createState() => _TambahEditSuratScreenState();
}

class _TambahEditSuratScreenState extends State<TambahEditSuratScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _judulCtrl = TextEditingController();
  final _nomorCtrl = TextEditingController();
  final _dariCtrl = TextEditingController();
  final _kepadaCtrl = TextEditingController();
  final _instruksiCtrl = TextEditingController();
  final _noAgendaCtrl = TextEditingController();
  
  DateTime? _selectedTanggal;
  String _selectedUrgensi = 'Biasa';
  String _selectedKategori = 'Keuangan';
  String _penerimaLevel = 'Bapak Kepala Biro Umum';
  List<String> _selectedDiteruskan = [];

  // File variables
  String? _pickedFileName;
  Uint8List? _pickedFileBytes;
  int? _pickedFileSize;
  String? _pickedMimeType;
  bool _isImage = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _judulCtrl.text = e.judul;
      _nomorCtrl.text = e.nomorSurat;
      _dariCtrl.text = e.dari;
      _kepadaCtrl.text = e.kepada;
      _instruksiCtrl.text = e.instruksiDisposisi;
      _noAgendaCtrl.text = e.noAgenda != '-' ? e.noAgenda : '';
      _penerimaLevel = e.penerimaLevel;
      _selectedDiteruskan = List<String>.from(e.diteruskanKepada);
      _selectedTanggal = e.tanggalSurat;
      // Map existing urgensi to match standard values or fallback
      _selectedUrgensi = ['Biasa', 'Segera', 'Sangat Segera'].contains(e.tingkatUrgensi)
          ? e.tingkatUrgensi
          : 'Biasa';
      _selectedKategori = const ['Keuangan', 'Rumah Tangga', 'Tata Usaha'].contains(e.kategori)
          ? e.kategori
          : 'Keuangan';
      _pickedFileName = e.filePath.split('/').last;
      _pickedMimeType = e.fileUrl.toLowerCase().contains('.pdf') ? 'application/pdf' : 'image/jpeg';
      _isImage = !_pickedMimeType!.contains('pdf');
      _pickedFileSize = e.fileSize;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _nomorCtrl.dispose();
    _dariCtrl.dispose();
    _kepadaCtrl.dispose();
    _instruksiCtrl.dispose();
    _noAgendaCtrl.dispose();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      debugPrint('[LOG 1] PDF File Picked from FilePicker:');
      debugPrint('  - name: ${file.name}');
      debugPrint('  - path: ${file.path}');
      debugPrint('  - size: ${file.size}');
      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
          debugPrint('  - bytes read manually from path, length: ${bytes.length}');
        } catch (e) {
          debugPrint('  - Error reading picked file bytes: $e');
        }
      } else {
        debugPrint('  - bytes length from picker: ${bytes?.length}');
      }

      setState(() {
        _pickedFileName = file.name;
        _pickedFileBytes = bytes;
        _pickedFileSize = file.size;
        _pickedMimeType = 'application/pdf';
        _isImage = false;
      });
    } else {
      debugPrint('[LOG 1] FilePicker returned null (user cancelled).');
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final size = bytes.length;
      debugPrint('[LOG 1] Image captured/picked via ImagePicker:');
      debugPrint('  - name: ${image.name}');
      debugPrint('  - path: ${image.path}');
      debugPrint('  - size: $size');
      debugPrint('  - bytes length: ${bytes.length}');

      setState(() {
        _pickedFileName = image.name;
        _pickedFileBytes = bytes;
        _pickedFileSize = size;
        _pickedMimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        _isImage = true;
      });
    } else {
      debugPrint('[LOG 1] ImagePicker returned null (user cancelled).');
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Lampiran',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentSourceItem(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _captureImage(ImageSource.camera);
                    },
                  ),
                  _AttachmentSourceItem(
                    icon: Icons.photo_outlined,
                    label: 'Galeri',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(ctx);
                      _captureImage(ImageSource.gallery);
                    },
                  ),
                  _AttachmentSourceItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'File PDF',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickPDF();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedTanggal = picked;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existing != null;
    
    setState(() {
      _saving = true;
    });

    try {
      final judul = _judulCtrl.text.trim();
      final nomor = _nomorCtrl.text.trim();
      final dari = _dariCtrl.text.trim();
      final kepada = _kepadaCtrl.text.trim();

      final statusPengiriman = isEdit
          ? (widget.existing?.statusPengiriman ?? 'menunggu_karo')
          : 'menunggu_karo';
      final instruksiDisposisi = _instruksiCtrl.text.trim();

      final existingHistory = isEdit ? widget.existing!.riwayatDisposisi : [];
      final List<Map<String, dynamic>> riwayatList = List<Map<String, dynamic>>.from(existingHistory);

      if (!isEdit && riwayatList.isEmpty) {
        riwayatList.add({
          'oleh': 'Admin TU',
          'ke': 'Kepala Biro Umum',
          'waktu': DateTime.now().toIso8601String(),
          'status': 'Menunggu Disposisi Kepala Biro',
          'instruksi': 'Surat di-scan dan di-upload ke aplikasi SIMASTER.',
        });
      }

      final deskripsiMap = {
        'nomor_surat': nomor,
        'tanggal_surat': _selectedTanggal?.toIso8601String() ?? '',
        'dari': dari,
        'kepada': kepada,
        'instruksi_disposisi': instruksiDisposisi,
        'no_agenda': _noAgendaCtrl.text.trim(),
        'penerima_level': _penerimaLevel,
        'diteruskan_kepada': _selectedDiteruskan,
        'tingkat_urgensi': _selectedUrgensi,
        'status_pengiriman': statusPengiriman,
        'status_disposisi': statusPengiriman,
        'riwayat_disposisi': riwayatList,
      };

      String finalFileUrl = widget.existing?.fileUrl ?? '';
      String finalFilePath = widget.existing?.filePath ?? '';
      int? finalFileSize = widget.existing?.fileSize;

      // 1. Upload new file if selected, otherwise generate official Lembar Disposisi PDF automatically
      if (_pickedFileBytes != null && _pickedFileName != null) {
        final uploadResult = await ArsipSuratService.uploadBerkasAsli(
          fileName: _pickedFileName!,
          fileBytes: _pickedFileBytes!,
          mimeType: _pickedMimeType ?? 'application/pdf',
        );
        finalFileUrl = uploadResult['file_url']!;
        finalFilePath = uploadResult['file_path']!;
        finalFileSize = _pickedFileSize;
      } else if (!isEdit || finalFileUrl.isEmpty) {
        // Otomatis buatkan dokumen PDF Lembar Disposisi Digital resmi Pemprov Lampung
        final tempSurat = ArsipSurat(
          id: widget.existing?.id ?? 'temp_id',
          judul: judul,
          kategori: _selectedKategori,
          deskripsi: deskripsiMap,
          fileUrl: '',
          filePath: '',
          fileSize: 0,
          createdAt: DateTime.now(),
          nomorSurat: nomor,
          tanggalSurat: _selectedTanggal,
          dari: dari,
          kepada: kepada,
          instruksiDisposisi: instruksiDisposisi,
          tingkatUrgensi: _selectedUrgensi,
          statusPengiriman: statusPengiriman,
        );

        final generatedPdfBytes = await generateLembarDisposisiPdf(tempSurat);
        final generatedFileName = 'Lembar_Disposisi_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final uploadResult = await ArsipSuratService.uploadBerkasAsli(
          fileName: generatedFileName,
          fileBytes: generatedPdfBytes,
          mimeType: 'application/pdf',
        );
        finalFileUrl = uploadResult['file_url']!;
        finalFilePath = uploadResult['file_path']!;
        finalFileSize = generatedPdfBytes.length;
      }

      // 2. Save metadata to DB
      if (isEdit) {
        final oldFilePath = widget.existing!.filePath;
        final hasNewFile = _pickedFileBytes != null && _pickedFileName != null;

        debugPrint('[LOG 2] Variabel file baru diteruskan ke ArsipSuratService:');
        debugPrint('  - fileUrl: $finalFileUrl');
        debugPrint('  - filePath: $finalFilePath');
        debugPrint('  - hasNewFile (triggers deletion of old file): $hasNewFile ($oldFilePath)');

        await ArsipSuratService.updateArsip(
          id: widget.existing!.id,
          judul: judul,
          kategori: _selectedKategori,
          deskripsi: deskripsiMap,
          fileUrl: finalFileUrl,
          filePath: finalFilePath,
          fileSize: finalFileSize,
          oldFilePathToDelete: hasNewFile ? oldFilePath : null,
        );
      } else {
        await ArsipSuratService.tambahArsip(
          judul: judul,
          kategori: _selectedKategori,
          deskripsi: deskripsiMap,
          fileUrl: finalFileUrl,
          filePath: finalFilePath,
          fileSize: finalFileSize ?? 0,
        );
      }

      if (!mounted) return;

      if (!isEdit) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Expanded(child: Text('Surat Disimpan!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              'Surat & Lembar Disposisi Digital berhasil dibuat!\n\nLanjutkan alur dengan mengirim notifikasi WhatsApp ke Karo (Bapak Kepala Biro)?',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nanti Saja'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _bukaWhatsAppKaro(nomor, dari, judul);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Kirim WA ke Karo'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _bukaWhatsAppKaro(String nomor, String dari, String perihal) async {
    final message = "Assalamu'alaikum Wr. Wb.\n\n"
        "Yth. Kepala Biro,\n\n"
        "Terdapat surat masuk baru yang telah di-scan oleh TU dan memerlukan disposisi.\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Nomor Surat:\n$nomor\n\n"
        "Perihal:\n$perihal\n\n"
        "Asal Surat:\n$dari\n\n"
        "━━━━━━━━━━━━━━\n\n"
        "Silakan lakukan disposisi ke Kabag Rumah Tangga melalui aplikasi SIMASTER.\n\n"
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Arsip Surat' : 'Tambah Arsip Surat Masuk',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF475569),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _saving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  SizedBox(height: 16),
                  Text(
                    'Mengunggah berkas & menyimpan metadata...',
                    style: AppTextStyles.bodySmall,
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Area Upload Lampiran (di bagian paling atas)
                    const Text('Lampiran Surat', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    _buildUploadArea(),
                    const SizedBox(height: 20),

                    // Informasi Surat Card
                    NeuCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Surat', style: AppTextStyles.h3),
                          const SizedBox(height: 16),
                          
                          // Nomor Surat
                          const Text('Nomor Surat', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nomorCtrl,
                            enabled: true,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Nomor surat masuk',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Nomor surat wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // Tanggal Surat
                          const Text('Tanggal Surat', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _selectTanggal,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTanggal == null
                                        ? 'Pilih tanggal surat'
                                        : '${_selectedTanggal!.day}/${_selectedTanggal!.month}/${_selectedTanggal!.year}',
                                    style: AppTextStyles.body.copyWith(
                                      color: _selectedTanggal == null ? AppColors.textHint : AppColors.textPrimary,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Dari (Asal Surat)
                          const Text('Dari (Instansi Pengirim)', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dariCtrl,
                            enabled: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Dinas Perhubungan / Sekda',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Asal pengirim wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // Kepada (Tujuan Surat)
                          const Text('Kepada (Tujuan Surat)', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _kepadaCtrl,
                            enabled: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Kepala Biro Umum',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Perihal
                          const Text('Perihal Surat / Judul', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _judulCtrl,
                            enabled: true,
                            keyboardType: TextInputType.multiline,
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Perihal / judul surat',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Perihal wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori & Tingkat Urgensi
                    NeuCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kategori & Urgensi', style: AppTextStyles.h3),
                          const SizedBox(height: 16),

                          // Kategori Dropdown
                          const Text('Kategori Arsip', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: const ['Keuangan', 'Rumah Tangga', 'Tata Usaha'].contains(_selectedKategori)
                                ? _selectedKategori
                                : 'Keuangan',
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Keuangan', child: Text('Keuangan')),
                              DropdownMenuItem(value: 'Rumah Tangga', child: Text('Rumah Tangga')),
                              DropdownMenuItem(value: 'Tata Usaha', child: Text('Tata Usaha')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedKategori = val);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tingkat Urgensi
                          const Text('Tingkat Urgensi', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Biasa', 'Segera', 'Sangat Segera'].map((urgensi) {
                              final isSelected = _selectedUrgensi == urgensi;
                              final color = _getUrgensiColor(urgensi);
                              return Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedUrgensi = urgensi),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? color : AppColors.divider,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        urgensi,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? color : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tombol Simpan Arsip
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _simpan,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan Arsip',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0x40F59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadArea() {
    if (_pickedFileName == null) {
      return InkWell(
        onTap: _showAttachmentPicker,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFFD97706)),
              SizedBox(height: 12),
              Text(
                'Upload Lampiran Berkas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mendukung Kamera, Galeri, atau File PDF',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final isLocal = _pickedFileBytes != null;

    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual File Type Indicator
          if (_isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isLocal && _pickedFileBytes != null
                  ? Image.memory(
                      _pickedFileBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : (widget.existing != null
                      ? Image.network(
                          widget.existing!.fileUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textHint),
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppColors.error),
                    SizedBox(height: 8),
                    Text(
                      'Dokumen PDF Terpilih',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File info row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_isImage ? AppColors.info : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isImage ? Icons.image_outlined : Icons.picture_as_pdf,
                  color: _isImage ? AppColors.info : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pickedFileName!,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tipe: ${_isImage ? "Gambar" : "PDF"} • Ukuran: ${_pickedFileSize != null ? _formatSize(_pickedFileSize!) : "-"}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action button to replace file
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAttachmentPicker,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Ganti File Lampiran'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentSourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentSourceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
