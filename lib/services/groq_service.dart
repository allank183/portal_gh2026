import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Import repository & model resmi
import '../repositories/repo_pegawai.dart';
import '../repositories/repo_pelatihan.dart';
import '../repositories/repo_presensi.dart';
import '../repositories/repo_statistik.dart';
import '../models/model_pegawai.dart';
import '../models/model_pelatihan.dart';
import '../models/model_presensi.dart';

class GroqService {
  static const String _workerUrl = 'https://portal-lapker-apigro.mmakerapps.workers.dev';

  /// Backwards Compatibility Alias
  static Future<String> askAI({
    required String promptUser,
    required Map<String, dynamic> userData,
  }) async {
    return askUnifiedAI(promptUser: promptUser, userData: userData);
  }

  /// Fungsi Utama AI Terpadu
  static Future<String> askUnifiedAI({
    required String promptUser,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final pegawaiRepo = PegawaiRepository();
      final pelatihanRepo = PelatihanRepository();
      final presensiRepo = PresensiRepository();
      final statistikRepo = StatistikRepository();
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1. Ekstraksi Identifier User
      final dynamic rawNip = userData['nip'] ?? userData['NIP'] ?? userData['nip_pegawai'] ?? '';
      final String userNip = rawNip.toString().trim();
      final String userUid = (userData['uid'] ?? '').toString().trim();

      // 2. Filter Kata Kunci
      final List<String> words = promptUser
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((w) => w.length > 2 && ![
        'siapa', 'profil', 'data', 'berapa', 'tentang', 'mengenai', 'cari',
        'tolong', 'carikan', 'berikan', 'saja', 'apa', 'sertifikat', 'pelatihan'
      ].contains(w))
          .toList();

      // 3. FETCH PARALEL DENGAN REPOSITORY RESMI
      final results = await Future.wait<dynamic>([
        // Index 0: Laporan Statistik Pegawai
        statistikRepo.getStatistikStream().first.catchError((_) => DataStatistikPegawai(
          totalPegawai: 0, totalLaki: 0, totalPerempuan: 0, totalMedis: 0,
          totalNakes: 0, totalAdmin: 0, totalPns: 0, totalP3k: 0, totalBlu: 0, totalCukup40Jpl: 0,
        )),

        // Index 1: Kegiatan Mahasiswa
        firestore.collection('kegiatan_mahasiswa').limit(10).get()
            .then((snap) => snap.docs.map((d) => d.data()).toList())
            .catchError((_) => <Map<String, dynamic>>[]),

        // Index 2: Data Detail Pegawai Login dari Repository
        userUid.isNotEmpty || userNip.isNotEmpty
            ? pegawaiRepo.getCurrentPegawai().catchError((_) => null)
            : Future<PegawaiModel?>.value(null),

        // Index 3: Riwayat Presensi Personal User
        userUid.isNotEmpty
            ? presensiRepo.getRiwayatPresensiStream(userUid).first.catchError((_) => <PresensiModel>[])
            : Future<List<PresensiModel>>.value(<PresensiModel>[]),

        // Index 4: Seluruh Pegawai
        pegawaiRepo.getAllPegawai().catchError((_) => <PegawaiModel>[]),

        // Index 5: Riwayat Pelatihan Personal User
        (userUid.isNotEmpty || userNip.isNotEmpty)
            ? pelatihanRepo.getRiwayatByUidOrNip(uid: userUid, nip: userNip).first.catchError((_) => <PelatihanModel>[])
            : Future<List<PelatihanModel>>.value(<PelatihanModel>[]),
      ]);

      // Parsing Hasil Query
      final statData = results[0] as DataStatistikPegawai;
      final listMahasiswa = results[1] as List<Map<String, dynamic>>;
      final currentPegawaiModel = results[2] as PegawaiModel?;
      final listAbsensi = results[3] as List<PresensiModel>;
      final allPegawai = results[4] as List<PegawaiModel>;
      final listPelatihanUser = results[5] as List<PelatihanModel>;

      // 4. Olah Data Personal User (JPL & Target)
      const double targetJpl = 40.0;
      double totalJpl = currentPegawaiModel?.totalJpl.toDouble() ??
          (userData['total_jpl'] ?? userData['totalJpl'] ?? 0.0).toDouble();

      double sisaJpl = targetJpl - totalJpl;
      if (sisaJpl < 0) sisaJpl = 0;
      bool sudahTercapai = totalJpl >= targetJpl;

      // 5. Pencarian Profil Pegawai & Riwayat Pegawai Lain
      List<String> hasilPencarianPegawai = [];
      String matchedNipTarget = "";

      if (words.isNotEmpty && allPegawai.isNotEmpty) {
        for (var p in allPegawai) {
          String nama = p.nama;
          String namaLower = nama.toLowerCase();

          if (words.any((w) => namaLower.contains(w))) {
            String nip = p.nip.isEmpty ? '-' : p.nip;
            matchedNipTarget = nip;
            String kelompok = p.kelompok.isEmpty ? '-' : p.kelompok;
            String instalasi = p.instalasi.isNotEmpty ? p.instalasi : (p.ruangan.isNotEmpty ? p.ruangan : '-');
            String gol = p.golongan.isEmpty ? '-' : p.golongan;
            String kontak = p.kontak.isEmpty ? '-' : p.kontak;

            hasilPencarianPegawai.add(
                "• Profil Pegawai: Nama: $nama | NIP: $nip | Kelompok: $kelompok | Unit/Ruangan: $instalasi | Golongan: $gol | Kontak: $kontak"
            );
          }
        }
      }

      String riwayatPelatihanTarget = "";
      if (matchedNipTarget.isNotEmpty && matchedNipTarget != userNip) {
        final pelatihanTargetModels = await pelatihanRepo
            .getRiwayatByUidOrNip(nip: matchedNipTarget)
            .first
            .catchError((_) => <PelatihanModel>[]);

        if (pelatihanTargetModels.isNotEmpty) {
          riwayatPelatihanTarget = pelatihanTargetModels.take(5).map((pl) {
            return "  - ${pl.judulPelatihan} | ${pl.jumlahJpl} JPL | SKP: ${pl.jumlahSkp} | Status: ${pl.status}";
          }).join('\n');
        }
      }

      String stringHasilPencarian = hasilPencarianPegawai.isEmpty
          ? "• Tidak ditemukan data pegawai yang cocok dengan kata kunci tersebut."
          : hasilPencarianPegawai.join('\n');

      if (riwayatPelatihanTarget.isNotEmpty) {
        stringHasilPencarian += "\n\n  Riwayat Pelatihan Pegawai yang Dicari:\n$riwayatPelatihanTarget";
      }

      // 6. Format Riwayat Pelatihan Personal User
      String stringPelatihanUser = "Belum ada rincian riwayat pelatihan terdaftar.";
      if (listPelatihanUser.isNotEmpty) {
        stringPelatihanUser = listPelatihanUser.map((pl) {
          return "• ${pl.judulPelatihan} (${pl.jumlahJpl} JPL, SKP: ${pl.jumlahSkp}) - Status: ${pl.status}";
        }).join('\n');
      }

      // 7. Format Pegawai Target Tercapai
      List<String> daftarPegawaiTercapai = allPegawai
          .where((p) => p.totalJpl >= targetJpl)
          .take(20)
          .map((p) => "• ${p.nama} (${p.kelompok.isEmpty ? 'Umum' : p.kelompok}) - ${p.totalJpl} JPL")
          .toList();

      String stringDaftarTercapai = daftarPegawaiTercapai.isEmpty
          ? "• Belum ada rincian nama pegawai yang tercatat mencapai target."
          : daftarPegawaiTercapai.join('\n');

      // 8. Format Absensi Personal User
      String infoAbsensiPersonal = "Belum ada catatan absensi tercatat.";
      if (listAbsensi.isNotEmpty) {
        Map<String, Map<String, int>> rekapBulan = {};
        List<String> detailKetidakhadiran = [];

        for (var item in listAbsensi) {
          DateTime? tgl = item.jamMasuk;
          if (tgl == null) continue;

          String namaBulan = DateFormat('MMMM yyyy', 'id_ID').format(tgl);
          String tglFormatted = DateFormat('dd MMMM yyyy', 'id_ID').format(tgl);
          String status = item.status;

          rekapBulan.putIfAbsent(namaBulan, () => {});
          rekapBulan[namaBulan]![status] = (rekapBulan[namaBulan]![status] ?? 0) + 1;

          if (status.toLowerCase() != 'tepat waktu') {
            detailKetidakhadiran.add("• $tglFormatted: $status (${item.tipeShift ?? 'Reguler'})");
          }
        }

        if (rekapBulan.isNotEmpty) {
          List<String> listRekap = [];
          rekapBulan.forEach((bulan, statusMap) {
            String rincianStatus = statusMap.entries
                .map((e) => "${e.key}: ${e.value} hari")
                .join(', ');
            listRekap.add("• $bulan -> $rincianStatus");
          });

          infoAbsensiPersonal = "Ringkasan Bulanan:\n${listRekap.join('\n')}";

          if (detailKetidakhadiran.isNotEmpty) {
            infoAbsensiPersonal += "\n\nDetail Catatan Ketidakhadiran/Izin/Sakit/Terlambat:\n${detailKetidakhadiran.join('\n')}";
          }
        }
      }

      // 9. Kegiatan Mahasiswa
      String rincianMahasiswa = listMahasiswa.take(5).map((m) {
        String jenisKegiatan = m['jenis_kegiatan'] ?? m['kegiatan'] ?? 'Kegiatan Mahasiswa';
        return "• ${m['nama_mahasiswa'] ?? 'Mhs'} (${m['nama_kampus'] ?? '-'}): $jenisKegiatan";
      }).join('\n');

      String tanggalSekarang = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

      // SYSTEM PROMPT
      final String systemPrompt = '''
Anda adalah Marsal, Asisten Virtual & Intelligent Assistant untuk Dashboard Portal Kinerja SDM ini.
Hari ini adalah tanggal: $tanggalSekarang.

===================
1. PROFIL PEGAWAI (USER AKTIF)
===================
- Nama: ${currentPegawaiModel?.nama ?? userData['nama'] ?? 'Pengguna'}
- NIP: ${userNip.isEmpty ? '-' : userNip}
- Role/Kelompok: ${currentPegawaiModel?.role ?? userData['role'] ?? 'Staff'}
- Unit Kerja/Ruangan: ${currentPegawaiModel?.instalasi ?? userData['instalasi'] ?? '-'}
- Total Capaian JPL Pelatihan: $totalJpl JPL (Target Tahunan: $targetJpl JPL)
- Status Target JPL: ${sudahTercapai ? 'SUDAH TERCAPAI' : 'Kurang ${sisaJpl.toStringAsFixed(1)} JPL lagi'}
- Riwayat Pelatihan Yang Pernah Diikuti User Ini:
$stringPelatihanUser

- Rekap Absensi Personal User Ini:
$infoAbsensiPersonal

===================
2. METRIK GLOBAL ORGANISASI & LAPORAN MANAJERIAL
===================
- Total Pegawai: ${statData.totalPegawai} orang (PNS: ${statData.totalPns}, PPPK: ${statData.totalP3k}, BLU: ${statData.totalBlu})
- Rincian Kelompok: Admin: ${statData.totalAdmin}, Medis: ${statData.totalMedis}, Nakes: ${statData.totalNakes}.
- Gender: ${statData.totalLaki} Pria, ${statData.totalPerempuan} Wanita.
- Total Pegawai Mencapai 40 JPL: ${statData.totalCukup40Jpl} orang.

DAFTAR PEGAWAI YANG SUDAH MENCAPAI TARGET 40 JPL:
$stringDaftarTercapai

HASIL PENCARIAN PROFIL PEGAWAI / PEGAWAI LAIN:
$stringHasilPencarian

- Sampel Kegiatan Mahasiswa Terbaru:
${rincianMahasiswa.isEmpty ? '• Belum ada data mahasiswa' : rincianMahasiswa}

===================
ATURAN BISNIS & INTERAKSI AI
===================
1. Jawablah pertanyaan pengguna secara sopan, cerdas, presisi, dan langsung ke inti masalah.
2. FORMAT BALASAN:
   - DILARANG Menggunakan format tabel Markdown (| ... |) atau HTML.
   - Gunakan format poin (•) atau penomoran biasa agar nyaman dibaca.
   - Gunakan huruf tebal (**teks**) untuk judul/kategori penting.
3. PENCARIAN PEGAWAI & RIWAYAT: Jika pengguna menanyakan profil seseorang, jawab detail dari "HASIL PENCARIAN PROFIL PEGAWAI / PEGAWAI LAIN".
4. PELATIHANS USER: Jika pengguna bertanya "pelatihan apa saja yang sudah saya ikuti", paparkan daftar pelatihan dari "Riwayat Pelatihan Yang Pernah Diikuti User Ini".
5. BATASAN CAKUPAN: Fokus hanya pada Portal Kinerja, JPL, pelatihan, absensi, mahasiswa, dan data SDM pegawai.
''';

      // 10. Request ke Worker Proxy
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'openai/gpt-oss-20b',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': promptUser},
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('error')) {
          final errMessage = data['error'] is Map ? data['error']['message'] : data['error'];
          return 'Error AI: $errMessage';
        }

        if (data is Map && data['choices'] != null && (data['choices'] as List).isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? 'Tidak ada respon dari AI.';
        }

        return 'Format respon tidak sesuai: ${response.body}';
      } else {
        if (kDebugMode) debugPrint('Proxy Error Body: ${response.body}');
        return 'Gagal terhubung ke AI (Status: ${response.statusCode})';
      }
    } catch (e) {
      return 'Terjadi kesalahan koneksi AI: $e';
    }
  }
}