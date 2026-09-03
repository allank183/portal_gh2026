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
  final bool isPossibleDuplicate;
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
    this.isPossibleDuplicate = false,
    this.verifiedBy,
    this.verifiedAt,
    this.catatanAdmin,
    this.createdAt,
  });

  // 1. Convert ke Map (Untuk simpan ke Firestore/D1)
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
      'is_possible_duplicate': isPossibleDuplicate,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // 2. Factory untuk data dari CLOUDFLARE D1 (JSON)
  factory PelatihanModel.fromJson(Map<String, dynamic> json) {
    // Helper parsing tanggal aman
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PelatihanModel(
      id: json['id']?.toString(), // ID Integer di SQL diubah jadi String
      uid: json['uid'] ?? '',
      nip: json['nip'] ?? '',
      namaPegawai: json['nama_pegawai'] ?? '',
      nomorSertifikat: json['nomor_sertifikat'] ?? '',
      judulPelatihan: json['judul_pelatihan'] ?? '',
      penyelenggara: json['penyelenggara'] ?? '',
      tanggalKegiatan: json['tanggal_kegiatan'] ?? '',
      jumlahJpl: (json['jumlah_jpl'] ?? 0).toDouble(),
      jumlahSkp: (json['jumlah_skp'] ?? 0).toDouble(),
      fileUrl: json['file_url'] ?? '',
      status: json['status'] ?? 'pending',
      isPossibleDuplicate: (json['is_possible_duplicate'] == 1 || json['is_possible_duplicate'] == true),
      verifiedBy: json['verified_by'],
      verifiedAt: _parseDate(json['verified_at']),
      catatanAdmin: json['catatan_admin'],
      createdAt: _parseDate(json['created_at']),
    );
  }

  // 3. Factory untuk data dari FIRESTORE (Lama)
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
      isPossibleDuplicate: data['is_possible_duplicate'] ?? false,
      verifiedBy: data['verified_by'],
      verifiedAt: (data['verified_at'] as Timestamp?)?.toDate(),
      catatanAdmin: data['catatan_admin'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}