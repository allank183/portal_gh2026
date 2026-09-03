import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../models/model_pelatihan.dart';
import '../../repositories/repo_pelatihan.dart';
import '../../services/service_storage.dart';

class UploadSertifikatPage extends StatefulWidget {
  final Map<String, dynamic> pegawaiData;
  final Uint8List? initialBytes;
  final String? initialFileName;

  const UploadSertifikatPage({
    super.key,
    required this.pegawaiData,
    this.initialBytes,
    this.initialFileName,
  });

  @override
  State<UploadSertifikatPage> createState() => _UploadSertifikatPageState();
}

class _UploadSertifikatPageState extends State<UploadSertifikatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomorController = TextEditingController();
  final _judulController = TextEditingController();
  final _penyelenggaraController = TextEditingController();
  final _jplController = TextEditingController();
  final _skpController = TextEditingController();
  final _tanggalController = TextEditingController();

  Map<String, dynamic>? _selectedPegawai;
  List<Map<String, dynamic>> _allPegawaiCache = [];

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedFileExtension;
  bool _isLoading = false;
  bool _isParsing = false;

  // Status penguncian form dari hasil ekstraksi PDF
  bool _isFieldsLocked = false;

  @override
  void initState() {
    super.initState();

    _fetchPegawaiCache();

    if (widget.pegawaiData.isNotEmpty && widget.pegawaiData['nip'] != null) {
      _selectedPegawai = widget.pegawaiData;
    }

    if (widget.initialBytes != null && widget.initialFileName != null) {
      _selectedFileBytes = widget.initialBytes;
      _selectedFileName = widget.initialFileName;
      _selectedFileExtension = widget.initialFileName!.split('.').last.toLowerCase();

      if (_selectedFileExtension == 'pdf') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _parsePdfData(_selectedFileBytes!);
        });
      }
    }
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _judulController.dispose();
    _penyelenggaraController.dispose();
    _jplController.dispose();
    _skpController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _fetchPegawaiCache() async {
    // Jika user sudah ditentukan di awal, tidak perlu fetch cache
    if (widget.pegawaiData.isNotEmpty && widget.pegawaiData['nip'] != null) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('pegawai').get();
      if (mounted) {
        setState(() {
          _allPegawaiCache = snapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal fetch pegawai cache: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List fileBytes = result.files.single.bytes!;
      String fileName = result.files.single.name;
      String fileExt = result.files.single.extension?.toLowerCase() ?? 'pdf';

      setState(() {
        _selectedFileBytes = fileBytes;
        _selectedFileName = fileName;
        _selectedFileExtension = fileExt;
      });

      if (fileExt == 'pdf') {
        _parsePdfData(fileBytes);
      }
    }
  }

  Future<void> _parsePdfData(Uint8List bytes) async {
    setState(() => _isParsing = true);

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      _nomorController.clear();
      _judulController.clear();
      _penyelenggaraController.clear();
      _tanggalController.clear();
      _jplController.clear();
      _skpController.clear();

      // 1. Nomor Sertifikat
      RegExp regNomorSpesifik = RegExp(r'\/(\d+)\/(?:20\d{2})', caseSensitive: false);
      var matchNomorSpesifik = regNomorSpesifik.firstMatch(text);

      if (matchNomorSpesifik != null) {
        _nomorController.text = matchNomorSpesifik.group(1) ?? '';
      } else {
        RegExp regNomorFull = RegExp(r'Nomor(?:\s+Sertifikat)?\s*[:]?\s*([\s\S]*?)\s+Diberikan', caseSensitive: false);
        var matchNomorFull = regNomorFull.firstMatch(text);
        if (matchNomorFull != null) {
          _nomorController.text = matchNomorFull.group(1)?.replaceAll(RegExp(r'\s+'), '').trim() ?? '';
        }
      }

      // 2. Judul Pelatihan
      RegExp regJudul = RegExp(r'Telah\s+mengikuti\s+([\s\S]*?)\s+diselenggarakan\s+oleh', caseSensitive: false);
      var matchJudul = regJudul.firstMatch(text);
      if (matchJudul != null) {
        String rawJudul = matchJudul.group(1) ?? '';
        _judulController.text = rawJudul.replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      // 3. Penyelenggara
      RegExp regPenyelenggara = RegExp(r'diselenggarakan\s+oleh\s+([\s\S]*?)\s+Pada', caseSensitive: false);
      var matchPenyelenggara = regPenyelenggara.firstMatch(text);
      if (matchPenyelenggara != null) {
        String rawPenyelenggara = matchPenyelenggara.group(1) ?? '';
        _penyelenggaraController.text = rawPenyelenggara.replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      // 4. Tanggal / Tahun Kegiatan
      RegExp regTahun = RegExp(r'\b(20\d{2})\b');
      var matchTahun = regTahun.firstMatch(text);
      if (matchTahun != null) {
        _tanggalController.text = matchTahun.group(1) ?? '';
      }

      // 5. Ekstraksi JPL
      RegExp regJpl = RegExp(r'(?:Jumlah|setara)?\s*(\d+[\.,]?\d*)\s*(?:Jam Pelajaran|JPL)', caseSensitive: false);
      var matchJpl = regJpl.firstMatch(text);

      if (matchJpl != null) {
        _jplController.text = matchJpl.group(1)?.replaceAll(',', '.') ?? '';
      } else {
        RegExp regJplFallback = RegExp(r'Jumlah\s*(\d+[\.,]?\d*)', caseSensitive: false);
        var matchFallback = regJplFallback.firstMatch(text);
        if (matchFallback != null) {
          _jplController.text = matchFallback.group(1)?.replaceAll(',', '.') ?? '';
        }
      }

      // 6. Ekstraksi SKP
      RegExp regSkp = RegExp(r'(?:senilai|sebesar|sejumlah)\s*(\d+[\.,]?\d*)\s*SKP', caseSensitive: false);
      var matchSkp = regSkp.firstMatch(text);

      if (matchSkp != null) {
        _skpController.text = matchSkp.group(1)?.replaceAll(',', '.') ?? '';
      } else {
        RegExp regSkpFallback = RegExp(r'(?:Pelajaran|JPL)?\s*(?:senilai)?\s*(\d+[\.,]?\d*)\s*SKP', caseSensitive: false);
        var matchSkpFallback = regSkpFallback.firstMatch(text);
        if (matchSkpFallback != null) {
          _skpController.text = matchSkpFallback.group(1)?.replaceAll(',', '.') ?? '';
        }
      }

      // Kunci form jika data berhasil diekstrak
      if (_nomorController.text.isNotEmpty || _jplController.text.isNotEmpty) {
        _isFieldsLocked = true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sertifikat berhasil dipindai & data terkunci otomatis!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekstrak PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPegawai == null || (_selectedPegawai!['nip'] ?? '').toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih pegawai terlebih dahulu!')),
      );
      return;
    }

    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih berkas sertifikat terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String nomorInput = _nomorController.text.trim();
      String nip = _selectedPegawai!['nip'];
      String nama = _selectedPegawai!['nama'] ?? '';

      // 1. Cek Duplikasi Ganda: Nomor Sertifikat OR Kombinasi (NIP + Judul + Tahun)
      bool isNumDuplicate = await PelatihanRepository().isSertifikatExists(nomorInput);
      bool isKombinasiDuplicate = await PelatihanRepository().isKombinasiExists(
        nip: nip,
        judulPelatihan: _judulController.text,
        tanggalAtauTahun: _tanggalController.text,
      );

      // Flag true jika SALAH SATU terdeteksi ganda (Tetap diunggah, tidak diblokir)
      bool isDuplicate = isNumDuplicate || isKombinasiDuplicate;

      // 2. Upload file ke Storage
      String fileUrl = await StorageService().uploadSertifikatFile(
        bytes: _selectedFileBytes!,
        fileName: _selectedFileName ?? 'sertifikat.pdf',
        nip: nip,
      );

      String uid = _selectedPegawai!['uid'] ??
          _selectedPegawai!['id'] ??
          widget.pegawaiData['uid'] ??
          FirebaseAuth.instance.currentUser?.uid ??
          '';

      // 3. Konstruksi Model Pelatihan dengan flag isPossibleDuplicate
      PelatihanModel pelatihan = PelatihanModel(
        uid: uid,
        nip: nip,
        namaPegawai: nama,
        nomorSertifikat: nomorInput,
        judulPelatihan: _judulController.text.trim(),
        penyelenggara: _penyelenggaraController.text.trim(),
        tanggalKegiatan: _tanggalController.text.trim(),
        jumlahJpl: double.tryParse(_jplController.text) ?? 0.0,
        jumlahSkp: double.tryParse(_skpController.text) ?? 0.0,
        fileUrl: fileUrl,
        isPossibleDuplicate: isDuplicate, // Tanda merah akan otomatis muncul di panel admin jika true
      );

      // 4. Simpan ke Firestore
      await PelatihanRepository().simpanSertifikat(pelatihan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sertifikat berhasil disimpan & menunggu verifikasi!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserLocked = widget.pegawaiData.isNotEmpty && widget.pegawaiData['nip'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Sertifikat Pelatihan'),
      ),
      body: _isLoading || _isParsing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memproses dokumen...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Pegawai
              Card(
                color: isUserLocked ? Colors.indigo.shade50 : Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _selectedPegawai != null && isUserLocked
                      ? Row(
                    children: [
                      const Icon(Icons.person, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pegawai: ${_selectedPegawai!['nama']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text('NIP: ${_selectedPegawai!['nip']}'),
                        ],
                      ),
                      const Spacer(),
                      const Chip(
                        label: Text('Terkunci', style: TextStyle(fontSize: 12)),
                        avatar: Icon(Icons.lock, size: 14),
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedPegawai != null)
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Terpilih: ${_selectedPegawai!['nama']} (${_selectedPegawai!['nip']})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _selectedPegawai = null),
                            ),
                          ],
                        )
                      else
                        Autocomplete<Map<String, dynamic>>(
                          displayStringForOption: (option) => "${option['nama']} (${option['nip']})",
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Map<String, dynamic>>.empty();
                            }
                            final q = textEditingValue.text.toLowerCase();
                            // Hemat Kuota: Filter dilakukan pada cache lokal, bukan query Firestore
                            return _allPegawaiCache.where((data) =>
                                (data['nama'] ?? '').toString().toLowerCase().contains(q) ||
                                (data['nip'] ?? '').toString().toLowerCase().contains(q));
                          },
                          onSelected: (Map<String, dynamic> selection) {
                            setState(() {
                              _selectedPegawai = selection;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Cari & Pilih Pegawai (Ketik Nama / NIP)',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_selectedFileName ?? 'Pilih Berkas Sertifikat (PDF/Gambar)'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomorController,
                readOnly: _isFieldsLocked,
                decoration: InputDecoration(
                  labelText: 'Nomor Sertifikat',
                  suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                ),
                validator: (v) => v!.isEmpty ? 'Nomor wajib diisi' : null,
              ),

              TextFormField(
                controller: _judulController,
                readOnly: _isFieldsLocked,
                decoration: InputDecoration(
                  labelText: 'Judul Pelatihan',
                  suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                ),
                validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
              ),

              TextFormField(
                controller: _penyelenggaraController,
                readOnly: _isFieldsLocked,
                decoration: InputDecoration(
                  labelText: 'Penyelenggara',
                  suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                ),
                validator: (v) => v!.isEmpty ? 'Penyelenggara wajib diisi' : null,
              ),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jplController,
                      readOnly: _isFieldsLocked,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah JPL',
                        suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _skpController,
                      readOnly: _isFieldsLocked,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah SKP',
                        suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                      ),
                    ),
                  ),
                ],
              ),

              TextFormField(
                controller: _tanggalController,
                readOnly: _isFieldsLocked,
                decoration: InputDecoration(
                  labelText: 'Tanggal / Tahun Kegiatan',
                  suffixIcon: _isFieldsLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                ),
                validator: (v) => v!.isEmpty ? 'Tahun wajib diisi' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Unggah Sertifikat & Akumulasi JPL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}