import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/model_pelatihan.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PelatihanRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Simpan Sertifikat Baru
  Future<void> simpanSertifikat(PelatihanModel pelatihan) async {
    await _db.collection('riwayat_pelatihan').add(pelatihan.toMap());
  }

  // 2. APPROVE SERTIFIKAT
  Future<void> approveSertifikat({
    required PelatihanModel pelatihan,
    required String adminId,
  }) async {
    WriteBatch batch = _db.batch();

    DocumentReference pelatihanRef =
    _db.collection('riwayat_pelatihan').doc(pelatihan.id);

    batch.update(pelatihanRef, {
      'status': 'approved',
      'verified_by': adminId,
      'verified_at': FieldValue.serverTimestamp(),
    });

    DocumentReference pegawaiRef;

    if (pelatihan.uid.isNotEmpty) {
      pegawaiRef = _db.collection('pegawai').doc(pelatihan.uid);
    } else {
      final pegawaiQuery = await _db
          .collection('pegawai')
          .where('nip', isEqualTo: pelatihan.nip)
          .limit(1)
          .get();

      if (pegawaiQuery.docs.isEmpty) {
        throw Exception(
            'Data pegawai dengan NIP ${pelatihan.nip} tidak ditemukan.');
      }
      pegawaiRef = pegawaiQuery.docs.first.reference;
    }

    batch.set(
      pegawaiRef,
      {
        'total_jpl': FieldValue.increment(pelatihan.jumlahJpl),
        'total_skp': FieldValue.increment(pelatihan.jumlahSkp),
        'total_sertifikat': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // 3. REJECT SERTIFIKAT
  Future<void> rejectSertifikat({
    required String docIdSertifikat,
    required String adminId,
    required String catatanAdmin,
  }) async {
    await _db.collection('riwayat_pelatihan').doc(docIdSertifikat).update({
      'status': 'rejected',
      'verified_by': adminId,
      'catatan_admin': catatanAdmin,
      'verified_at': FieldValue.serverTimestamp(),
    });
  }

  // 4. Stream antrean verifikasi
  Stream<List<PelatihanModel>> getPendingPelatihanStream() {
    return _db
        .collection('riwayat_pelatihan')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PelatihanModel.fromDocument(doc)).toList();
    });
  }

  // 5. Cek Duplikasi Nomor Sertifikat (Mengembalikan true jika nomor sertifikat ada)
  Future<bool> isSertifikatExists(String nomorSertifikat) async {
    final cleanNomor = nomorSertifikat.trim();
    if (cleanNomor.isEmpty) return false;

    final query = await _db
        .collection('riwayat_pelatihan')
        .where('nomor_sertifikat', isEqualTo: cleanNomor)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // 6. Stream Riwayat Pelatihan Pegawai
  Stream<List<PelatihanModel>> getRiwayatByUidOrNip({String? uid, String? nip}) {
    Query query = _db.collection('riwayat_pelatihan');

    if (uid != null && uid.isNotEmpty) {
      query = query.where('uid', isEqualTo: uid);
    } else if (nip != null && nip.isNotEmpty) {
      query = query.where('nip', isEqualTo: nip);
    } else {
      return Stream.value([]);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PelatihanModel.fromDocument(doc))
          .toList();

      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return list;
    });
  }

  // 7. Stream Rekap Data Pegawai
  Stream<DocumentSnapshot<Map<String, dynamic>>> getRekapPegawaiByUid(String uid) {
    return _db.collection('pegawai').doc(uid).snapshots();
  }

  // 8. Recalculate Pegawai Stats
  Future<void> recalculatePegawaiStats({required String uid, required String nip}) async {
    try {
      final querySnapshot = await _db
          .collection('riwayat_pelatihan')
          .where('nip', isEqualTo: nip)
          .where('status', isEqualTo: 'approved')
          .get();

      double totalJpl = 0.0;
      double totalSkp = 0.0;
      int totalSertifikat = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalJpl += (data['jumlah_jpl'] ?? 0).toDouble();
        totalSkp += (data['jumlah_skp'] ?? 0).toDouble();
      }

      await _db.collection('pegawai').doc(uid).update({
        'total_jpl': totalJpl,
        'total_skp': totalSkp,
        'total_sertifikat': totalSertifikat,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal recalculate stats: $e');
    }
  }

  // 9. Hapus Sertifikat & Recalculate
  Future<void> hapusSertifikat({
    required String docIdSertifikat,
    required String uid,
    required String nip,
  }) async {
    await _db.collection('riwayat_pelatihan').doc(docIdSertifikat).delete();
    await recalculatePegawaiStats(uid: uid, nip: nip);
  }

  Stream<List<PelatihanModel>> getRiwayatPelatihanPegawaiStream(String nip) {
    return _db
        .collection('riwayat_pelatihan')
        .where('nip', isEqualTo: nip)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PelatihanModel.fromDocument(doc))
        .toList());
  }

  // Cek duplikasi berdasarkan Kombinasi: NIP + Judul Pelatihan + Tahun
  Future<bool> isKombinasiExists({
    required String nip,
    required String judulPelatihan,
    required String tanggalAtauTahun,
  }) async {
    final cleanJudul = judulPelatihan.trim().toLowerCase();
    final cleanTahun = tanggalAtauTahun.trim();
    if (cleanJudul.isEmpty || nip.trim().isEmpty) return false;

    // Ambil riwayat pegawai yang sudah disetujui (approved)
    final query = await _db
        .collection('riwayat_pelatihan')
        .where('nip', isEqualTo: nip.trim())
        .where('status', isEqualTo: 'approved')
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final dbJudul = (data['judul_pelatihan'] ?? '').toString().trim().toLowerCase();
      final dbTahun = (data['tanggal_kegiatan'] ?? '').toString().trim();

      // Jika Judul & Tahun cocok dengan data yang sudah approved
      if (dbJudul == cleanJudul && dbTahun == cleanTahun) {
        return true;
      }
    }
    return false;
  }


// --- FUNGSI MIGRASI PELATIHAN KE CLOUDFLARE D1 ---
  Future<void> jalankanMigrasiPelatihanKeCloudflare() async {
    try {
      debugPrint('Memulai Migrasi Riwayat Pelatihan...');

      // 1. Ambil data dari Firestore
      final snapshot = await _db.collection('riwayat_pelatihan').get();
      final listData = snapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'uid': d['uid'] ?? '',
          'nip': d['nip'] ?? '',
          'judul_pelatihan': d['judul_pelatihan'] ?? '',
          'jumlah_jpl': (d['jumlah_jpl'] ?? 0).toDouble(),
          'status': d['status'] ?? 'pending',
          'file_url': d['file_url'] ?? '',
        };
      }).toList();

      debugPrint('Ditemukan ${listData.length} data pelatihan. Mengirim ke Worker...');

      // 2. Kirim ke Worker
      final response = await http.post(
        Uri.parse('https://portalgh2026.mmakerapps.workers.dev/sync-pelatihan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(listData),
      );

      if (response.statusCode == 200) {
        debugPrint('MIGRASI PELATIHAN BERHASIL!');
      } else {
        debugPrint('MIGRASI PELATIHAN GAGAL: ${response.body}');
      }
    } catch (e) {
      debugPrint('ERROR SYNC PELATIHAN: $e');
    }
  }
}
