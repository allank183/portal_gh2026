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

  // Factory untuk membuat Objek dari Dokumen Firestore atau JSON D1
  factory PegawaiModel.fromFirestore(Map<String, dynamic> data, String docId) {
    bool _parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      return defaultValue;
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    // --- PERBAIKAN LOGIKA PERMISSIONS DI SINI ---
    List<String> permissionsList = [];
    final rawData = data['permissions'];
    if (rawData is List) {
      permissionsList = rawData.map((e) => e.toString().toLowerCase().trim()).toList();
    } else if (rawData is String && rawData.isNotEmpty) {
      permissionsList = rawData.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
    // --------------------------------------------

    return PegawaiModel(
      uid: data['uid']?.toString() ?? docId,
      nip: data['nip']?.toString() ?? '',
      nama: data['nama']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString().toLowerCase() ?? 'pegawai',
      permissions: permissionsList, // <--- Gunakan variabel baru ini
      golongan: data['golongan']?.toString() ?? '',
      instalasi: data['instalasi']?.toString() ?? '',
      jenisKelamin: data['jenis_kelamin']?.toString() ?? '',
      kelompok: data['kelompok']?.toString() ?? '',
      keterangan: data['keterangan']?.toString() ?? '',
      kontak: data['kontak']?.toString() ?? '',
      ruangan: data['ruangan']?.toString() ?? '',
      statusKepegawaian: data['status_kepegawaian']?.toString() ?? '',
      jadwalKerja: data['jadwal_kerja']?.toString() ?? 'Reguler',
      isActive: _parseBool(data['is_active'], defaultValue: true),
      isFirstLogin: _parseBool(data['is_first_login'], defaultValue: false),
      totalJpl: (data['total_jpl'] as num?)?.toInt() ?? 0,
      totalSertifikat: (data['total_sertifikat'] as num?)?.toInt() ?? 0,
      totalSkp: (data['total_skp'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
    );
  }
  // Map untuk keperluan simpan/update ke Firestore/D1
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
      'is_active': isActive ? 1 : 0, // Simpan sebagai 1/0 agar cocok dengan D1
      'is_first_login': isFirstLogin ? 1 : 0,
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