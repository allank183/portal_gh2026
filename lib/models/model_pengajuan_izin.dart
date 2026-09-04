class PengajuanIzinModel {
  final String id;
  final String uid;
  final String namaPegawai;
  final String nip;
  final String jenisIzin;
  final String alasan;
  final String status;
  final String? lampiranUrl;
  final DateTime tanggalPengajuan;

  PengajuanIzinModel({
    required this.id,
    required this.uid,
    required this.namaPegawai,
    required this.nip,
    required this.jenisIzin,
    required this.alasan,
    required this.status,
    this.lampiranUrl,
    required this.tanggalPengajuan,
  });

  factory PengajuanIzinModel.fromJson(Map<String, dynamic> json) {
    return PengajuanIzinModel(
      id: json['id']?.toString() ?? '',
      uid: json['uid'] ?? '',
      namaPegawai: json['nama_pegawai'] ?? '',
      nip: json['nip'] ?? '',
      jenisIzin: json['jenis_izin'] ?? '',
      alasan: json['alasan'] ?? '',
      status: json['status'] ?? 'Pending',
      lampiranUrl: json['lampiran_url'],
      tanggalPengajuan: json['tanggal_pengajuan'] != null
          ? (DateTime.tryParse(json['tanggal_pengajuan'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}