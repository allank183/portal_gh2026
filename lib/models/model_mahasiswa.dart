class MahasiswaKegiatanModel {
  final int? id;
  final String nama;
  final String nim;
  final String namaKampus;
  final String jenisKegiatan; // Penelitian, PKK, PKM, Coas, Residen
  final String jenjang; // S1, S2, D3, Profesi, dll
  final String tanggalMulai;
  final int durasi;
  final String satuan; // Hari, Pekan, Bulan, Kegiatan
  final double biaya;
  final String status; // Aktif, Selesai, Pending
  final String? kontak;
  final String? catatan;
  final DateTime? createdAt;

  MahasiswaKegiatanModel({
    this.id,
    required this.nama,
    required this.nim,
    required this.namaKampus,
    required this.jenisKegiatan,
    required this.jenjang,
    required this.tanggalMulai,
    required this.durasi,
    required this.satuan,
    required this.biaya,
    this.status = 'Aktif',
    this.kontak,
    this.catatan,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nim': nim,
      'nama_kampus': namaKampus,
      'jenis_kegiatan': jenisKegiatan,
      'jenjang': jenjang,
      'tanggal_mulai': tanggalMulai,
      'durasi': durasi,
      'satuan': satuan,
      'biaya': biaya,
      'status': status,
      'kontak': kontak,
      'catatan': catatan,
    };
  }

  factory MahasiswaKegiatanModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaKegiatanModel(
      id: json['id'],
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
      namaKampus: json['nama_kampus'] ?? '',
      jenisKegiatan: json['jenis_kegiatan'] ?? '',
      jenjang: json['jenjang'] ?? '',
      tanggalMulai: json['tanggal_mulai'] ?? '',
      durasi: json['durasi'] ?? 1,
      satuan: json['satuan'] ?? 'Hari',
      biaya: (json['biaya'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Aktif',
      kontak: json['kontak'],
      catatan: json['catatan'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
