import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;

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
      [
        'nama',
        'nip',
        'email',
        'kontak',
        'jenis_kelamin',
        'golongan',
        'status_kepegawaian',
        'kelompok',
        'instalasi',
        'ruangan',
        'keterangan'
      ],
      [
        'HIJRAH S.Kep Ners',
        '\'198409062010122006', // Gunakan \' di depan angka panjang
        'hijrah@example.com',
        '\'08114010609',        // Gunakan \' di depan nomor HP
        'P',
        'III/d',
        'PNS',
        'Nakes',
        'Rawat Inap',
        'Perawatan Lantai 4',
        'UPF BBKPM'
      ],
      [
        'Budi Santoso',
        '\'198501012010121001',
        '',
        '\'08123456789',
        'L',
        'III/b',
        'PNS',
        'Medis',
        'Rawat Jalan',
        'Poli Umum',
        'UPF BBKPM'
      ]
    ];

    // Menghasilkan data CSV
    String csvData = Csv().encode(csvContent);

    // Menambahkan 'sep=,\n' agar Excel otomatis memecah kolom A sampai K saat dibuka
    String excelFriendlyCsv = "sep=,\n$csvData";

    if (kIsWeb) {
      // Menambahkan Byte Order Mark (BOM) UTF-8 agar karakter Excel tidak berantakan
      final bytes = utf8.encode('\uFEFF$excelFriendlyCsv');
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "template_import_pegawai.csv")
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template CSV berhasil diunduh! Silakan buka di Excel.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur unduh template didukung penuh pada mode Web.')),
      );
    }
  }

  Future<UserCredential> _createUserWithoutSwitchingSession(String email, String password) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempRegisterApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
    UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await tempApp.delete();
    return credential;
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _logs.clear();
          _logs.add('File dipilih: ${_selectedFile!.name}');
        });
      }
    } catch (e) {
      setState(() => _logs.add('Error saat memilih file: $e'));
    }
  }

  Future<void> _processCsvAndRegister() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file CSV terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _logs.add('Memulai membaca file CSV...');
    });

    try {
      String csvString = utf8.decode(_selectedFile!.bytes!);

      // Abaikan instruksi sep=, jika ada di baris pertama
      if (csvString.startsWith('sep=')) {
        csvString = csvString.substring(csvString.indexOf('\n') + 1);
      }

      List<List<dynamic>> csvData = Csv().decode(csvString);

      if (csvData.length <= 1) {
        setState(() {
          _logs.add('Error: File CSV kosong atau hanya berisi header.');
          _isProcessing = false;
        });
        return;
      }

      int totalRows = csvData.length - 1;
      int successCount = 0;
      int failedCount = 0;

      final defaultPassword = _csvPasswordController.text.trim();
      final firestore = FirebaseFirestore.instance;

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.isEmpty || row.length < 2) continue;

        String nama = row[0].toString().trim();
        String nip = row[1].toString().trim();
        String rawEmail = row.length > 2 ? row[2].toString().trim().toLowerCase() : '';
        String email = (rawEmail.isNotEmpty && rawEmail.contains('@')) ? rawEmail : '$nip@lapker.internal';

        try {
          final checkDoc = await firestore.collection('pegawai').where('nip', isEqualTo: nip).limit(1).get();

          if (checkDoc.docs.isNotEmpty) {
            setState(() => _logs.add('--> SKIP: $nama (NIP sudah terdaftar)'));
            successCount++;
            continue;
          }

          UserCredential userCredential = await _createUserWithoutSwitchingSession(
            email,
            defaultPassword,
          );

          String uid = userCredential.user!.uid;

          Map<String, dynamic> pegawaiData = {
            'uid': uid,
            'nama': nama,
            'nip': nip,
            'email': email,
            'kontak': row.length > 3 ? row[3].toString().trim() : '',
            'jenis_kelamin': row.length > 4 ? row[4].toString().trim() : 'L',
            'golongan': row.length > 5 ? row[5].toString().trim() : '',
            'status_kepegawaian': row.length > 6 ? row[6].toString().trim() : 'PNS',
            'kelompok': row.length > 7 ? row[7].toString().trim() : 'Medis',
            'instalasi': row.length > 8 ? row[8].toString().trim() : '',
            'ruangan': row.length > 9 ? row[9].toString().trim() : '',
            'keterangan': row.length > 10 ? row[10].toString().trim() : 'UPF BBKPM',
            'jadwal_kerja': 'Reguler',
            'is_active': true,
            'is_first_login': true,
            'role': 'pegawai',
            'permissions': ['upload_sertifikat', 'view_own_dashboard'],
            'total_jpl': 0,
            'total_sertifikat': 0,
            'total_skp': 0,
            'created_at': FieldValue.serverTimestamp(),
          };

          await firestore.collection('pegawai').doc(uid).set(pegawaiData);

          successCount++;
          setState(() => _logs.add('--> BERHASIL: $nama (UID: $uid)'));
        } catch (e) {
          failedCount++;
          setState(() => _logs.add('--> GAGAL: $nama | Error: ${e.toString()}'));
        }

        setState(() => _progress = i / totalRows);
      }

      setState(() {
        _logs.add('===================================');
        _logs.add('PROSES SELESAI!');
        _logs.add('Berhasil: $successCount | Gagal/Eksis: $failedCount');
      });
    } catch (e) {
      setState(() => _logs.add('Terjadi kesalahan fatal: $e'));
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
              const Text(
                'Import Data Pegawai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: _downloadTemplateCsv,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Template CSV (Excel Compatible)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: InkWell(
              onTap: _isProcessing ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 56, color: Colors.indigo.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null ? _selectedFile!.name : 'Klik untuk Pilih File CSV Pegawai',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Format berkas harus .csv', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _csvPasswordController,
            enabled: !_isProcessing,
            decoration: InputDecoration(
              labelText: 'Password Default Akun Baru',
              prefixIcon: Icon(Icons.lock_outline, size: 20, color: Colors.indigo.shade400),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isProcessing || _selectedFile == null ? null : _processCsvAndRegister,
              icon: const Icon(Icons.people_alt_rounded),
              label: Text(_isProcessing ? 'Memproses CSV...' : 'Proses Registrasi Massal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isProcessing) LinearProgressIndicator(value: _progress, color: Colors.indigo),
          const SizedBox(height: 20),
          const Text('Log Eksekusi:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}