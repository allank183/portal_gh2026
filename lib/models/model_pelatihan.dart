import 'package:cloud_firestore/cloud_firestore.dart';

class PelatihanModel {
  final String? id;
  final String uid;
  final String nip;
  final String namaPegawai;
  final String nomorSertifikat;
  final String judulPelatihan;
  final String penyelenggara;
  final String tanggalKegiatan;
  final double jumlahJpl;
  final double jumlahSkp;
  final String fileUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final bool isPossibleDuplicate; // FLAG BARU
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? catatanAdmin;
  final DateTime? createdAt;

  PelatihanModel({
    this.id,
    required this.uid,
    required this.nip,
    required this.namaPegawai,
    required this.nomorSertifikat,
    required this.judulPelatihan,
    required this.penyelenggara,
    required this.tanggalKegiatan,
    required this.jumlahJpl,
    required this.jumlahSkp,
    required this.fileUrl,
    this.status = 'pending',
    this.isPossibleDuplicate = false, // Default false
    this.verifiedBy,
    this.verifiedAt,
    this.catatanAdmin,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nip': nip,
      'nama_pegawai': namaPegawai,
      'nomor_sertifikat': nomorSertifikat,
      'judul_pelatihan': judulPelatihan,
      'penyelenggara': penyelenggara,
      'tanggal_kegiatan': tanggalKegiatan,
      'jumlah_jpl': jumlahJpl,
      'jumlah_skp': jumlahSkp,
      'file_url': fileUrl,
      'status': status,
      'is_possible_duplicate': isPossibleDuplicate, // Ditambahkan ke Map
      'verified_by': verifiedBy,
      'verified_at': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'catatan_admin': catatanAdmin,
      'createdAt': FieldValue.serverTimestamp(), // Tetap gunakan serverTimestamp Firestore
    };
  }

  factory PelatihanModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PelatihanModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      nip: data['nip'] ?? '',
      namaPegawai: data['nama_pegawai'] ?? '',
      nomorSertifikat: data['nomor_sertifikat'] ?? '',
      judulPelatihan: data['judul_pelatihan'] ?? '',
      penyelenggara: data['penyelenggara'] ?? '',
      tanggalKegiatan: data['tanggal_kegiatan'] ?? '',
      jumlahJpl: (data['jumlah_jpl'] ?? 0).toDouble(),
      jumlahSkp: (data['jumlah_skp'] ?? 0).toDouble(),
      fileUrl: data['file_url'] ?? '',
      status: data['status'] ?? 'pending',
      isPossibleDuplicate: data['is_possible_duplicate'] ?? false, // Parsing dari Firestore
      verifiedBy: data['verified_by'],
      verifiedAt: (data['verified_at'] as Timestamp?)?.toDate(),
      catatanAdmin: data['catatan_admin'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}