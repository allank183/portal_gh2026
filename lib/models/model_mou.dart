class MouModel {
  final int? id;
  final String nomorMou;
  final String judul;
  final String mitra;
  final String kategori; // Pendidikan, Penelitian, Pelayanan, Lainnya
  final String tanggalMulai;
  final String tanggalSelesai;
  final String? fileUrl;
  final String status; // Aktif, Kadaluarsa
  final String? catatan;
  final DateTime? createdAt;

  MouModel({
    this.id,
    required this.nomorMou,
    required this.judul,
    required this.mitra,
    this.kategori = 'Pendidikan',
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.fileUrl,
    this.status = 'Aktif',
    this.catatan,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomor_mou': nomorMou,
      'judul': judul,
      'mitra': mitra,
      'kategori': kategori,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'file_url': fileUrl,
      'status': status,
      'catatan': catatan,
    };
  }

  factory MouModel.fromJson(Map<String, dynamic> json) {
    return MouModel(
      id: json['id'],
      nomorMou: json['nomor_mou'] ?? '',
      judul: json['judul'] ?? '',
      mitra: json['mitra'] ?? '',
      kategori: json['kategori'] ?? 'Pendidikan',
      tanggalMulai: json['tanggal_mulai'] ?? '',
      tanggalSelesai: json['tanggal_selesai'] ?? '',
      fileUrl: json['file_url'],
      status: json['status'] ?? 'Aktif',
      catatan: json['catatan'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
