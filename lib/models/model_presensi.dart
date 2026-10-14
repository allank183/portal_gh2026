class PresensiModel {
  // --- 1. DEKLARASI VARIABEL DITARUH DI SINI ---
  final String id;
  final String uid;
  final String nip;
  final String namaPegawai;
  final String tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamPulang;
  final String status;
  final String jadwalKerja;
  final String? tipeShift;
  final int menitTerlambat;
  final int menitWajibGanti;
  final DateTime? targetJamPulang;
  final String? catatMasuk;
  final String? catatPulang;
  final String? fotoMasukUrl;  
  final String? fotoPulangUrl; 
  final String? pengajuanId;
  final DateTime? createdAt;
  final String? catatanPenolakan;

  // --- 2. CONSTRUCTOR ---
  PresensiModel({
    required this.id,
    required this.uid,
    required this.nip,
    required this.namaPegawai,
    required this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    required this.status,
    this.jadwalKerja = 'Reguler',
    this.tipeShift,
    this.menitTerlambat = 0,
    this.menitWajibGanti = 0,
    this.targetJamPulang,
    this.catatMasuk,
    this.catatPulang,
    this.fotoMasukUrl,  
    this.fotoPulangUrl, 
    this.pengajuanId,
    this.createdAt,
    this.catatanPenolakan,
  });

  // Helper untuk parsing waktu UTC dari database D1 ke waktu lokal (.toLocal())
  static DateTime? _parseServerTime(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    if (str.isEmpty) return null;
    
    if (!str.endsWith('Z') && !str.contains('+') && !str.contains(RegExp(r'-\d{2}:?\d{2}'))) {
      str = '${str.replaceAll(' ', 'T')}Z';
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  // --- 3. FACTORY FROM JSON (D1) ---
  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      nip: json['nip']?.toString() ?? '',
      namaPegawai: json['nama_pegawai']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      jamMasuk: _parseServerTime(json['jam_masuk']),
      jamPulang: _parseServerTime(json['jam_pulang']),
      status: json['status']?.toString() ?? 'Tepat Waktu',
      jadwalKerja: json['jadwal_kerja']?.toString() ?? 'Reguler',
      tipeShift: json['tipe_shift']?.toString(),
      menitTerlambat: json['menit_terlambat'] ?? 0,
      menitWajibGanti: json['menit_wajib_ganti'] ?? 0,
      targetJamPulang: _parseServerTime(json['target_jam_pulang']),
      catatMasuk: json['catat_masuk']?.toString(),
      catatPulang: json['catat_pulang']?.toString(),
      fotoMasukUrl: json['foto_masuk_url']?.toString(),   
      fotoPulangUrl: json['foto_pulang_url']?.toString(), 
      pengajuanId: json['pengajuan_id']?.toString(),
      createdAt: _parseServerTime(json['created_at']),
      catatanPenolakan: json['catatan_penolakan']?.toString(),
    );
  }
}
