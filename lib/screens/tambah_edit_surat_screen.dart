import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/arsip_surat_model.dart';
import '../theme/app_theme.dart';
import '../services/arsip_surat_service.dart';
import '../widgets/common_widgets.dart';

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
  
  DateTime? _selectedTanggal;
  String _selectedUrgensi = 'Biasa';
  String _selectedKategori = 'Umum';

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
      _selectedTanggal = e.tanggalSurat;
      // Map existing urgensi to match standard values or fallback
      _selectedUrgensi = ['Biasa', 'Segera', 'Sangat Segera'].contains(e.tingkatUrgensi)
          ? e.tingkatUrgensi
          : 'Biasa';
      _selectedKategori = e.kategori;
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
      setState(() {
        _pickedFileName = file.name;
        _pickedFileBytes = file.bytes;
        _pickedFileSize = file.size;
        _pickedMimeType = 'application/pdf';
        _isImage = false;
      });
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
      setState(() {
        _pickedFileName = image.name;
        _pickedFileBytes = bytes;
        _pickedFileSize = size;
        _pickedMimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        _isImage = true;
      });
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
    
    // File validation
    if (!isEdit && _pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda wajib melampirkan file surat (PDF/Kamera/Galeri)'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final judul = _judulCtrl.text.trim();
      final nomor = _nomorCtrl.text.trim();
      final dari = _dariCtrl.text.trim();
      final kepada = _kepadaCtrl.text.trim();

      final statusPengiriman = widget.existing?.statusPengiriman ?? 'belum_dikirim_karo';
      final instruksiDisposisi = widget.existing?.instruksiDisposisi ?? '';

      final deskripsiMap = {
        'nomor_surat': nomor,
        'tanggal_surat': _selectedTanggal?.toIso8601String() ?? '',
        'dari': dari,
        'kepada': kepada,
        'instruksi_disposisi': instruksiDisposisi,
        'tingkat_urgensi': _selectedUrgensi,
        'status_pengiriman': statusPengiriman,
        'status_disposisi': statusPengiriman,
      };

      String finalFileUrl = widget.existing?.fileUrl ?? '';
      String finalFilePath = widget.existing?.filePath ?? '';
      int? finalFileSize = widget.existing?.fileSize;

      // 1. Upload new file only if selected
      if (_pickedFileBytes != null && _pickedFileName != null) {
        final uploadResult = await ArsipSuratService.uploadBerkasAsli(
          fileName: _pickedFileName!,
          fileBytes: _pickedFileBytes!,
          mimeType: _pickedMimeType ?? 'application/pdf',
        );
        finalFileUrl = uploadResult['file_url']!;
        finalFilePath = uploadResult['file_path']!;
        finalFileSize = _pickedFileSize;
      }

      // 2. Save metadata to DB
      if (isEdit) {
        await ArsipSuratService.updateArsip(
          id: widget.existing!.id,
          judul: judul,
          kategori: _selectedKategori,
          deskripsi: deskripsiMap,
          fileUrl: finalFileUrl,
          filePath: finalFilePath,
          fileSize: finalFileSize,
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

  Color _getUrgensiColor(String urgensi) {
    switch (urgensi) {
      case 'Sangat Segera':
        return AppColors.error;
      case 'Segera':
        return AppColors.warning;
      case 'Biasa':
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
        title: Text(isEdit ? 'Edit Arsip Surat' : 'Tambah Arsip Surat Masuk'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _saving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
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
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Perihal
                          const Text('Perihal Surat / Judul', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _judulCtrl,
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

                    // Informasi Disposisi Card
                    NeuCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Disposisi', style: AppTextStyles.h3),
                          const SizedBox(height: 16),

                          // Dari (Asal Surat)
                          const Text('Dari (Pengirim)', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dariCtrl,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Instansi pengirim',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Asal pengirim wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // Kepada (Penerima Disposisi)
                          const Text('Kepada (Penerima Disposisi)', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _kepadaCtrl,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Tujuan penerima disposisi',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Penerima disposisi wajib diisi' : null,
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
                            initialValue: _selectedKategori,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                              DropdownMenuItem(value: 'Keuangan', child: Text('Keuangan')),
                              DropdownMenuItem(value: 'Kepegawaian', child: Text('Kepegawaian')),
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
                      child: GradientButton(
                        label: isEdit ? 'Simpan Perubahan' : 'Simpan Arsip',
                        icon: Icons.save_rounded,
                        onPressed: _simpan,
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
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Upload Lampiran Berkas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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
          if (_isImage && isLocal && _pickedFileBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _pickedFileBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!_isImage) ...[
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
