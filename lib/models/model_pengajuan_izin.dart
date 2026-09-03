import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanIzinModel {
  final String id;
  final String uid;
  final String namaPegawai;
  final String nip;
  final String jenisIzin;
  final String alasan;
  final String status;
  final String? lampiranUrl; // <--- Menyimpan URL file dari Cloudflare R2
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

  factory PengajuanIzinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PengajuanIzinModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      namaPegawai: data['nama_pegawai'] ?? '',
      nip: data['nip'] ?? '',
      jenisIzin: data['jenis_izin'] ?? '',
      alasan: data['alasan'] ?? '',
      status: data['status'] ?? 'Pending',
      lampiranUrl: data['lampiran_url'],
      tanggalPengajuan: (data['tanggal_pengajuan'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama_pegawai': namaPegawai,
      'nip': nip,
      'jenis_izin': jenisIzin,
      'alasan': alasan,
      'status': status,
      'lampiran_url': lampiranUrl,
      'tanggal_pengajuan': Timestamp.fromDate(tanggalPengajuan),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}