class Ruangan {
  final String id;
  final String nama;
  final String lokasi;
  final int kapasitas;
  final String status;

  final String deskripsi;
  final String fasilitas;
  final String peraturan;

  final String gambar1;
  final String gambar2;
  final String gambar3;

  Ruangan({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.kapasitas,
    required this.status,
    required this.deskripsi,
    required this.fasilitas,
    required this.peraturan,
    required this.gambar1,
    required this.gambar2,
    required this.gambar3,
  });

  factory Ruangan.fromJson(Map<String, dynamic> json) {
    return Ruangan(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      lokasi: json['lokasi'] ?? '',
      kapasitas: json['kapasitas'] ?? 0,
      status: json['status'] ?? '',

      deskripsi: json['deskripsi'] ?? '',
      fasilitas: json['fasilitas'] ?? '',
      peraturan: json['peraturan'] ?? '',

      gambar1: json['gambar_1'] ?? '',
      gambar2: json['gambar_2'] ?? '',
      gambar3: json['gambar_3'] ?? '',
    );
  }
}