import 'package:cloud_firestore/cloud_firestore.dart';

class PegawaiModel {
  final String uid;
  final String nip;
  final String nama;
  final String email;
  final String role;
  final List<String> permissions;
  final String golongan;
  final String instalasi;
  final String jenisKelamin;
  final String kelompok;
  final String keterangan;
  final String kontak;
  final String ruangan;
  final String statusKepegawaian;
  final String jadwalKerja; // 'Reguler' atau 'Shift'
  final bool isActive;
  final bool isFirstLogin;
  final int totalJpl;
  final int totalSertifikat;
  final int totalSkp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PegawaiModel({
    required this.uid,
    required this.nip,
    required this.nama,
    required this.email,
    required this.role,
    required this.permissions,
    required this.golongan,
    required this.instalasi,
    required this.jenisKelamin,
    required this.kelompok,
    required this.keterangan,
    required this.kontak,
    required this.ruangan,
    required this.statusKepegawaian,
    this.jadwalKerja = 'Reguler',
    required this.isActive,
    required this.isFirstLogin,
    required this.totalJpl,
    required this.totalSertifikat,
    required this.totalSkp,
    this.createdAt,
    this.updatedAt,
  });

  // Factory untuk membuat Objek dari Dokumen Firestore
  factory PegawaiModel.fromFirestore(Map<String, dynamic> data, String docId) {
    List<dynamic> rawPermissions = data['permissions'] ?? [];

    return PegawaiModel(
      uid: data['uid'] ?? docId,
      nip: data['nip'] ?? '',
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: data['role']?.toString().toLowerCase() ?? 'pegawai',
      permissions: rawPermissions
          .map((e) => e.toString().toLowerCase().trim())
          .toList(),
      golongan: data['golongan'] ?? '',
      instalasi: data['instalasi'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      kelompok: data['kelompok'] ?? '',
      keterangan: data['keterangan'] ?? '',
      kontak: data['kontak'] ?? '',
      ruangan: data['ruangan'] ?? '',
      statusKepegawaian: data['status_kepegawaian'] ?? '',
      jadwalKerja: data['jadwal_kerja'] ?? 'Reguler',
      isActive: data['is_active'] ?? true,
      isFirstLogin: data['is_first_login'] ?? false,
      // Default ke 0 jika field statistik belum diisi di dokumen Firestore
      totalJpl: (data['total_jpl'] as num?)?.toInt() ?? 0,
      totalSertifikat: (data['total_sertifikat'] as num?)?.toInt() ?? 0,
      totalSkp: (data['total_skp'] as num?)?.toInt() ?? 0,
      // Disesuaikan dengan key 'created_at' di Firestore
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // Map untuk keperluan simpan/update ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'nip': nip,
      'nama': nama,
      'email': email,
      'role': role,
      'permissions': permissions,
      'golongan': golongan,
      'instalasi': instalasi,
      'jenis_kelamin': jenisKelamin,
      'kelompok': kelompok,
      'keterangan': keterangan,
      'kontak': kontak,
      'ruangan': ruangan,
      'status_kepegawaian': statusKepegawaian,
      'jadwal_kerja': jadwalKerja,
      'is_active': isActive,
      'is_first_login': isFirstLogin,
      'total_jpl': totalJpl,
      'total_sertifikat': totalSertifikat,
      'total_skp': totalSkp,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // --- HELPER GETTERS FOR HAK AKSES ---
  bool get isSuperAdmin => role == 'super_admin';
  bool get isVerifikator => permissions.contains('verifikator');
}