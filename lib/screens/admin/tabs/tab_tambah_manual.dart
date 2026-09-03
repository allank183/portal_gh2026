import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/repo_pegawai.dart';

class TabTambahManual extends StatefulWidget {
  const TabTambahManual({super.key});

  @override
  State<TabTambahManual> createState() => _TabTambahManualState();
}

class _TabTambahManualState extends State<TabTambahManual> {
  final _nipController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'upfbbkpm');
  final _golonganController = TextEditingController();
  final _instalasiController = TextEditingController();
  final _ruanganController = TextEditingController();
  final _kontakController = TextEditingController();
  final _keteranganController = TextEditingController(text: 'UPF BBKPM');

  String _jenisKelamin = 'L';
  String _kelompok = 'Medis';
  bool _isManualLoading = false;

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

  Future<void> _registerManualPegawai() async {
    if (_nipController.text.trim().isEmpty ||
        _namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIP, Nama, dan Email Wajib Diisi!')),
      );
      return;
    }

    setState(() => _isManualLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      UserCredential userCredential = await _createUserWithoutSwitchingSession(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2. Siapkan data untuk D1 (Gunakan int 1/0 untuk bool agar awet di SQL)
      Map<String, dynamic> pegawaiData = {
        'uid': uid,
        'nip': _nipController.text.trim(),
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'jenis_kelamin': _jenisKelamin,
        'golongan': _golonganController.text.trim(),
        'kelompok': _kelompok,
        'instalasi': _instalasiController.text.trim(),
        'ruangan': _ruanganController.text.trim(),
        'kontak': _kontakController.text.trim(),
        'keterangan': _keteranganController.text.trim(),
        'status_kepegawaian': 'PNS',
        'jadwal_kerja': 'Reguler',
        'is_active': 1, // <--- Simpan sebagai Integer
        'is_first_login': 1,
        'role': 'pegawai',
        'total_jpl': 0,
        'total_sertifikat': 0,
        'total_skp': 0,
      };

      // 3. KIRIM KE CLOUDFLARE D1 (Gunakan Repository)
      await PegawaiRepository().updatePegawai(pegawaiData);
      // Atau panggil http.post langsung ke $_baseUrl/pegawai/add jika Anda sudah buat endpointnya

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pegawai ${_namaController.text} Berhasil Ditambahkan ke D1!')),
        );
        _clearManualForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah pegawai: $e')),
        );
      }
    }
    finally {
      if (mounted) setState(() => _isManualLoading = false);
    }
  }

  void _clearManualForm() {
    _nipController.clear();
    _namaController.clear();
    _emailController.clear();
    _golonganController.clear();
    _instalasiController.clear();
    _ruanganController.clear();
    _kontakController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrasi Pegawai Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tambahkan akun dan profil kepegawaian baru ke sistem.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextField(controller: _nipController, decoration: _inputStyle('NIP / ID Pegawai', Icons.badge_outlined))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _namaController, decoration: _inputStyle('Nama Lengkap & Gelar', Icons.person_outline))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _jenisKelamin,
                      decoration: _inputStyle('Gender', Icons.wc),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                      ],
                      onChanged: (val) => setState(() => _jenisKelamin = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _kelompok,
                      decoration: _inputStyle('Kelompok', Icons.groups_outlined),
                      items: const [
                        DropdownMenuItem(value: 'Medis', child: Text('Medis')),
                        DropdownMenuItem(value: 'Nakes', child: Text('Nakes')),
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => _kelompok = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _golonganController, decoration: _inputStyle('Golongan (cth: III/b)', Icons.stars_outlined))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _instalasiController, decoration: _inputStyle('Instalasi', Icons.business_outlined))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _ruanganController, decoration: _inputStyle('Ruangan / Jabatan', Icons.meeting_room_outlined))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _kontakController, decoration: _inputStyle('No. WhatsApp / Kontak', Icons.phone_outlined))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _emailController, decoration: _inputStyle('Email Pegawai', Icons.email_outlined))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _passwordController, decoration: _inputStyle('Password Awal', Icons.lock_outline))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isManualLoading ? null : _registerManualPegawai,
                  icon: _isManualLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isManualLoading ? 'Menyimpan...' : 'Simpan Pegawai Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.indigo.shade400),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
      ),
    );
  }
}