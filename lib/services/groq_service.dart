import 'dart:convert';
import 'package:http/http.dart' as http;

import '../repositories/repo_pegawai.dart';
import '../repositories/repo_pelatihan.dart';
import '../repositories/repo_presensi.dart';
import '../repositories/repo_statistik.dart';
import '../models/model_pegawai.dart';
import '../models/model_pelatihan.dart';
import '../models/model_presensi.dart';

class GroqService {
  static const String _workerUrl = 'https://portal-lapker-apigro.mmakerapps.workers.dev';

  static Future<String> askUnifiedAI({
    required String promptUser,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final pegawaiRepo = PegawaiRepository();
      final pelatihanRepo = PelatihanRepository();
      final presensiRepo = PresensiRepository();
      final statistikRepo = StatistikRepository();

      final String userNip = (userData['nip'] ?? '').toString().trim();
      final String userUid = (userData['uid'] ?? '').toString().trim();

      // 1. Ekstraksi kata kunci untuk pencarian
      final List<String> words = promptUser.toLowerCase().split(' ').where((w) => w.length > 3).toList();
      String searchKey = words.isNotEmpty ? words.first : "";

      // 2. FETCH PARALEL DARI CLOUDFLARE D1 (Sangat Cepat & Hemat)
      final results = await Future.wait<dynamic>([
        // Index 0: Statistik (D1)
        statistikRepo.getStatistikData(),

        // Index 1: Detail Pegawai Login (D1)
        pegawaiRepo.getCurrentPegawai(),

        // Index 2: Riwayat Presensi (D1)
        userUid.isNotEmpty ? presensiRepo.getRiwayatPresensiStream(userUid).first : Future.value(<PresensiModel>[]),

        // Index 3: Riwayat Pelatihan (D1)
        userNip.isNotEmpty ? pelatihanRepo.getRiwayatPelatihanPegawaiStream(userNip).first : Future.value(<PelatihanModel>[]),

        // Index 4: PENCARIAN TARGET (SQL LIKE - Bukan ambil semua!)
        searchKey.isNotEmpty ? pegawaiRepo.searchPegawai(searchKey) : Future.value(<PegawaiModel>[]),
      ]);

      final statData = results[0] as DataStatistikPegawai;
      final currentPegawai = results[1] as PegawaiModel?;
      final listAbsensi = results[2] as List<PresensiModel>;
      final listPelatihan = results[3] as List<PelatihanModel>;
      final searchResult = results[4] as List<PegawaiModel>;

      // 3. Format Data untuk AI
      String infoPencarian = searchResult.isNotEmpty
          ? searchResult.map((p) => "• Nama: ${p.nama} | NIP: ${p.nip} | Unit: ${p.instalasi}").join('\n')
          : "Tidak ada pencarian spesifik.";

      String infoPelatihan = listPelatihan.isNotEmpty
          ? listPelatihan.take(5).map((pl) => "• ${pl.judulPelatihan} (${pl.jumlahJpl} JPL) - ${pl.status}").join('\n')
          : "Belum ada riwayat pelatihan.";

      final String systemPrompt = '''
Anda adalah Marsal, Asisten Dashboard SDM. Gunakan data berikut:
PROFIL USER: Nama: ${currentPegawai?.nama}, NIP: ${currentPegawai?.nip}, Unit: ${currentPegawai?.instalasi}.
CAPAIAN JPL: ${currentPegawai?.totalJpl} JPL dari target 40 JPL.
RIWAYAT PELATIHAN USER:
$infoPelatihan
HASIL PENCARIAN PEGAWAI LAIN:
$infoPencarian
STATISTIK GLOBAL: Total: ${statData.totalPegawai}, Pria: ${statData.totalLaki}, Wanita: ${statData.totalPerempuan}, Capai Target: ${statData.totalCukup40Jpl}.
''';

      // 4. Kirim ke Groq Worker
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
        return data['choices'][0]['message']['content'];
      }
      return "Maaf, AI sedang sibuk. Silakan coba lagi.";
    } catch (e) {
      return "Terjadi kesalahan koneksi AI: $e";
    }
  }
}