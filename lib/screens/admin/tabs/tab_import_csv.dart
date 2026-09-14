import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' as excel_lib;
import '../../../models/model_pegawai.dart';
import '../../../repositories/repo_pegawai.dart';
import '../../../services/service_trigger.dart';

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

  void _downloadTemplateExcel() {
    var excel = excel_lib.Excel.createExcel();
    excel_lib.Sheet sheetObject = excel['Sheet1'];

    // Header
    sheetObject.appendRow([
      excel_lib.TextCellValue('nama'),
      excel_lib.TextCellValue('nip'),
      excel_lib.TextCellValue('email'),
      excel_lib.TextCellValue('kontak'),
      excel_lib.TextCellValue('jenis_kelamin'),
      excel_lib.TextCellValue('golongan'),
      excel_lib.TextCellValue('status_kepegawaian'),
      excel_lib.TextCellValue('kelompok'),
      excel_lib.TextCellValue('instalasi'),
      excel_lib.TextCellValue('ruangan'),
      excel_lib.TextCellValue('keterangan'),
    ]);

    // Contoh Data
    sheetObject.appendRow([
      excel_lib.TextCellValue('HIJRAH S.Kep Ners'),
      excel_lib.TextCellValue('198409062010122006'),
      excel_lib.TextCellValue('hijrah@example.com'),
      excel_lib.TextCellValue('08114010609'),
      excel_lib.TextCellValue('P'),
      excel_lib.TextCellValue('III/d'),
      excel_lib.TextCellValue('PNS'),
      excel_lib.TextCellValue('Nakes'),
      excel_lib.TextCellValue('Rawat Inap'),
      excel_lib.TextCellValue('Perawatan Lantai 4'),
      excel_lib.TextCellValue('UPF BBKPM'),
    ]);

    final fileBytes = excel.encode();
    if (fileBytes != null && kIsWeb) {
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "template_pegawai.xlsx")
        ..click();
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
      FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls', 'csv'],
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
      _logs.add('Memulai memproses file...');
    });

    try {
      List<List<dynamic>> rows = [];
      final repo = PegawaiRepository();

      if (_selectedFile!.name.toLowerCase().endsWith('.csv')) {
        String csvString = utf8.decode(_selectedFile!.bytes!);
        if (csvString.startsWith('sep=')) csvString = csvString.substring(csvString.indexOf('\n') + 1);
        rows = Csv().decode(csvString);
      } else {
        // PROSES EXCEL
        var excel = excel_lib.Excel.decodeBytes(_selectedFile!.bytes!);
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            rows.add(row.map((cell) => cell?.value?.toString()).toList());
          }
        }
      }

      if (rows.length <= 1) {
        setState(() { _logs.add('Error: File kosong atau tidak terbaca.'); _isProcessing = false; });
        return;
      }

      int totalRows = rows.length - 1;
      int successCount = 0;
      int failedCount = 0;
      final defaultPassword = _csvPasswordController.text.trim();

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length < 2 || row[0] == null) continue;

        String nama = row[0].toString().trim();
        String nip = row[1].toString().trim();
        String email = row.length > 2 && row[2] != null && row[2].toString().contains('@')
            ? row[2].toString().trim()
            : '$nip@gh2026.internal';

        try {
          if (await repo.isNipExists(nip)) {
            setState(() => _logs.add('--> SKIP: $nama (NIP Eksis)'));
            successCount++;
            continue;
          }

          UserCredential userCredential = await _createUserWithoutSwitchingSession(email, defaultPassword);
          String uid = userCredential.user!.uid;

          // Buat objek model untuk sinkronisasi D1
          final newPegawai = PegawaiModel(
            uid: uid,
            nip: nip,
            nama: nama,
            email: email,
            role: 'pegawai',
            permissions: [],
            golongan: row.length > 5 && row[5] != null ? row[5].toString() : '',
            instalasi: row.length > 8 && row[8] != null ? row[8].toString() : '',
            jenisKelamin: row.length > 4 && row[4] != null ? row[4].toString() : 'L',
            kelompok: row.length > 7 && row[7] != null ? row[7].toString() : 'Lainnya',
            keterangan: row.length > 10 && row[10] != null ? row[10].toString() : '',
            kontak: row.length > 3 && row[3] != null ? row[3].toString() : '',
            ruangan: row.length > 9 && row[9] != null ? row[9].toString() : '',
            statusKepegawaian: row.length > 6 && row[6] != null ? row[6].toString() : 'PNS',
            jadwalKerja: 'Reguler',
            isActive: true,
            isFirstLogin: true,
            totalJpl: 0.0,
            totalSertifikat: 0,
            totalSkp: 0.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await repo.addPegawai(newPegawai);

          successCount++;
          setState(() => _logs.add('--> BERHASIL: $nama'));
        } catch (e) {
          failedCount++;
          setState(() => _logs.add('--> GAGAL: $nama | $e'));
        }
        setState(() => _progress = i / totalRows);
      }
      setState(() => _logs.add('SELESAI! Berhasil: $successCount, Gagal: $failedCount'));
      if (successCount > 0) {
        refreshTrigger.notifyPegawaiUpdate();
        refreshTrigger.notifyStatistikUpdate();
      }
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
              OutlinedButton.icon(onPressed: _downloadTemplateExcel, icon: const Icon(Icons.download), label: const Text('Template Excel')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: InkWell(
              onTap: _isProcessing ? null : _pickFile,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.description_outlined, size: 50, color: Colors.indigo.shade400), const Text('Pilih File Excel / CSV Pegawai')])),
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
