import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../repositories/repo_pegawai.dart';

class TabImportCsv extends StatefulWidget {
  const TabImportCsv({super.key});

  @override
  State<TabImportCsv> createState() => _TabImportCsvState();
}

class _TabImportCsvState extends State<TabImportCsv> {
  final TextEditingController _csvPasswordController = TextEditingController(text: 'upfbbkpm');
  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  double _progress = 0.0;
  final List<String> _logs = [];

  void _downloadTemplateCsv() {
    final List<List<dynamic>> csvContent = [
      ['nama', 'nip', 'email', 'kontak', 'jenis_kelamin', 'golongan', 'status_kepegawaian', 'kelompok', 'instalasi', 'ruangan', 'keterangan'],
      ['HIJRAH S.Kep Ners', '198409062010122006', 'hijrah@example.com', '08114010609', 'P', 'III/d', 'PNS', 'Nakes', 'Rawat Inap', 'Perawatan Lantai 4', 'UPF BBKPM'],
    ];

    // PERBAIKAN: Gunakan class Csv() sesuai versi library Anda
    String csvData = Csv().encode(csvContent);

    if (kIsWeb) {
      final bytes = utf8.encode('\uFEFF$csvData');
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute("download", "template_pegawai.csv")..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<UserCredential> _createUserWithoutSwitchingSession(String email, String password) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
    UserCredential credential = await tempAuth.createUserWithEmailAndPassword(email: email, password: password);
    await tempApp.delete();
    return credential;
  }

  Future<void> _pickFile() async {
    try {
      // PERBAIKAN: Gunakan FilePicker.pickFiles langsung tanpa .platform
      FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          withData: true
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _logs.clear();
          _logs.add('File dipilih: ${_selectedFile!.name}');
        });
      }
    } catch (e) {
      setState(() => _logs.add('Error pilih file: $e'));
    }
  }

  Future<void> _processCsvAndRegister() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _logs.add('Memulai memproses file CSV...');
    });

    try {
      String csvString = utf8.decode(_selectedFile!.bytes!);
      if (csvString.startsWith('sep=')) csvString = csvString.substring(csvString.indexOf('\n') + 1);

      // PERBAIKAN: Gunakan Csv().decode() sesuai versi library Anda
      List<List<dynamic>> csvData = Csv().decode(csvString);

      if (csvData.length <= 1) {
        setState(() { _logs.add('Error: File CSV kosong.'); _isProcessing = false; });
        return;
      }

      int totalRows = csvData.length - 1;
      int successCount = 0;
      int failedCount = 0;
      final defaultPassword = _csvPasswordController.text.trim();

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.isEmpty || row.length < 2) continue;

        String nama = row[0].toString().trim();
        String nip = row[1].toString().trim();
        String email = row.length > 2 && row[2].toString().contains('@')
            ? row[2].toString().trim()
            : '$nip@lapker.internal';

        try {
          // CEK NIP DI D1
          final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
          final checkRes = await http.get(Uri.parse('$baseUrl/pegawai/check-nip?nip=$nip'));
          if (jsonDecode(checkRes.body)['exists'] == true) {
            setState(() => _logs.add('--> SKIP: $nama (NIP Eksis)'));
            successCount++;
            continue;
          }

          // REGISTER AUTH
          UserCredential userCredential = await _createUserWithoutSwitchingSession(email, defaultPassword);
          String uid = userCredential.user!.uid;

          // SIMPAN KE CLOUDFLARE D1
          await PegawaiRepository().updatePegawai({
            'uid': uid, 'nip': nip, 'nama': nama, 'email': email,
            'jenis_kelamin': row.length > 4 ? row[4].toString() : 'L',
            'golongan': row.length > 5 ? row[5].toString() : '',
            'status_kepegawaian': row.length > 6 ? row[6].toString() : 'PNS',
            'kelompok': row.length > 7 ? row[7].toString() : 'Medis',
            'instalasi': row.length > 8 ? row[8].toString() : '',
            'ruangan': row.length > 9 ? row[9].toString() : '',
            'is_active': 1, 'is_first_login': 1, 'role': 'pegawai',
            'total_jpl': 0, 'total_sertifikat': 0, 'total_skp': 0,
          });

          successCount++;
          setState(() => _logs.add('--> BERHASIL: $nama'));
        } catch (e) {
          failedCount++;
          setState(() => _logs.add('--> GAGAL: $nama | $e'));
        }
        setState(() => _progress = i / totalRows);
      }
      setState(() => _logs.add('SELESAI! Berhasil: $successCount, Gagal: $failedCount'));
    } catch (e) {
      setState(() => _logs.add('Kesalahan Fatal: $e'));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Import Data Pegawai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(onPressed: _downloadTemplateCsv, icon: const Icon(Icons.download), label: const Text('Template CSV')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: InkWell(
              onTap: _isProcessing ? null : _pickFile,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.indigo.shade400), const Text('Pilih File CSV Pegawai')])),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _csvPasswordController, decoration: const InputDecoration(labelText: 'Password Akun Baru', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _isProcessing || _selectedFile == null ? null : _processCsvAndRegister, child: Text(_isProcessing ? 'Memproses...' : 'Proses Registrasi'))),
          const SizedBox(height: 16),
          if (_isProcessing) LinearProgressIndicator(value: _progress),
          const SizedBox(height: 20),
          const Text('Log Eksekusi:', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(height: 200, width: double.infinity, padding: const EdgeInsets.all(12), color: const Color(0xFF1E293B), child: ListView.builder(itemCount: _logs.length, itemBuilder: (ctx, i) => Text(_logs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 12)))),
        ],
      ),
    );
  }
}