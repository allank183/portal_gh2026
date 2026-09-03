import 'package:cloud_firestore/cloud_firestore.dart';

class PresensiModel {
  final String id;
  final String uid;
  final String nip;
  final String namaPegawai;
  final String tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamPulang;
  final String status;
  final String jadwalKerja; // 'Reguler' / 'Shift'
  final String? tipeShift;  // 'Pagi', 'Siang', 'Malam'
  final int menitTerlambat;
  final int menitWajibGanti;
  final DateTime? targetJamPulang;
  final String? catatMasuk;
  final String? catatPulang;
  final String? pengajuanId;
  final DateTime? createdAt;
  final String? catatanPenolakan;

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
    this.pengajuanId,
    this.createdAt,
    this.catatanPenolakan,
  });

  factory PresensiModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PresensiModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      nip: data['nip'] ?? '',
      namaPegawai: data['nama_pegawai'] ?? '',
      tanggal: data['tanggal'] ?? '',
      jamMasuk: data['jam_masuk'] != null ? (data['jam_masuk'] as Timestamp).toDate() : null,
      jamPulang: data['jam_pulang'] != null ? (data['jam_pulang'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'Tepat Waktu',
      jadwalKerja: data['jadwal_kerja'] ?? 'Reguler',
      tipeShift: data['tipe_shift'],
      menitTerlambat: data['menit_terlambat'] ?? 0,
      menitWajibGanti: data['menit_wajib_ganti'] ?? 0,
      targetJamPulang: data['target_jam_pulang'] != null
          ? (data['target_jam_pulang'] as Timestamp).toDate()
          : null,
      catatMasuk: data['catat_masuk'],
      catatPulang: data['catat_pulang'],
      pengajuanId: data['pengajuan_id'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? (data['created_at'] as Timestamp?)?.toDate(),
      catatanPenolakan: data['catatan_penolakan'],
    );
  }

  factory PresensiModel.fromJson(Map<String, dynamic> json) {
    return PresensiModel(
      id: json['id']?.toString() ?? '',
      uid: json['uid'] ?? '',
      nip: json['nip'] ?? '',
      namaPegawai: json['nama_pegawai'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jamMasuk: json['jam_masuk'] != null ? DateTime.tryParse(json['jam_masuk']) : null,
      jamPulang: json['jam_pulang'] != null ? DateTime.tryParse(json['jam_pulang']) : null,
      status: json['status'] ?? 'Tepat Waktu',
      jadwalKerja: json['jadwal_kerja'] ?? 'Reguler',
      tipeShift: json['tipe_shift'],
      menitTerlambat: json['menit_terlambat'] ?? 0,
      menitWajibGanti: json['menit_wajib_ganti'] ?? 0,
      targetJamPulang: json['target_jam_pulang'] != null
          ? DateTime.tryParse(json['target_jam_pulang'])
          : null,
      catatMasuk: json['catat_masuk'],
      catatPulang: json['catat_pulang'],
      pengajuanId: json['pengajuan_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      catatanPenolakan: json['catatan_penolakan'],
    );
  }
}