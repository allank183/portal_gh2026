import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/model_pegawai.dart';

class TabDaftarPegawai extends StatefulWidget {
  const TabDaftarPegawai({super.key});

  @override
  State<TabDaftarPegawai> createState() => _TabDaftarPegawaiState();
}

class _TabDaftarPegawaiState extends State<TabDaftarPegawai> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showEditDialog(PegawaiModel pegawai) {
    final editNamaCtrl = TextEditingController(text: pegawai.nama);
    final editGolonganCtrl = TextEditingController(text: pegawai.golongan);
    final editInstalasiCtrl = TextEditingController(text: pegawai.instalasi);
    final editRuanganCtrl = TextEditingController(text: pegawai.ruangan);
    final editKontakCtrl = TextEditingController(text: pegawai.kontak);

    String editJenisKelamin = (pegawai.jenisKelamin.isNotEmpty) ? pegawai.jenisKelamin : 'L';
    String editKelompok = (pegawai.kelompok.isNotEmpty) ? pegawai.kelompok : 'Medis';

    InputDecoration inputStyle(String label, IconData icon, {bool enabled = true}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: enabled ? Colors.indigo.shade400 : Colors.grey),
        isDense: true,
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Data: ${pegawai.nama}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 600, // Memberikan ruang lebar agar layout grid 2 kolom terlihat rapi
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: pegawai.nip),
                          enabled: false,
                          decoration: inputStyle('NIP / ID Pegawai', Icons.badge_outlined, enabled: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: editNamaCtrl,
                          decoration: inputStyle('Nama Lengkap & Gelar', Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: editJenisKelamin,
                          decoration: inputStyle('Gender', Icons.wc),
                          items: const [
                            DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                            DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                          ],
                          onChanged: (val) => setDialogState(() => editJenisKelamin = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: editKelompok,
                          decoration: inputStyle('Kelompok', Icons.groups_outlined),
                          items: const [
                            DropdownMenuItem(value: 'Medis', child: Text('Medis')),
                            DropdownMenuItem(value: 'Nakes', child: Text('Nakes')),
                            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                          ],
                          onChanged: (val) => setDialogState(() => editKelompok = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: editGolonganCtrl,
                          decoration: inputStyle('Golongan (cth: III/b)', Icons.stars_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: editInstalasiCtrl,
                          decoration: inputStyle('Instalasi', Icons.business_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: editRuanganCtrl,
                          decoration: inputStyle('Ruangan / Jabatan', Icons.meeting_room_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: editKontakCtrl,
                          decoration: inputStyle('No. WhatsApp / Kontak', Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('pegawai')
                    .doc(pegawai.uid)
                    .update({
                  'nama': editNamaCtrl.text.trim(),
                  'jenis_kelamin': editJenisKelamin,
                  'kelompok': editKelompok,
                  'golongan': editGolonganCtrl.text.trim(),
                  'instalasi': editInstalasiCtrl.text.trim(),
                  'ruangan': editRuanganCtrl.text.trim(),
                  'kontak': editKontakCtrl.text.trim(),
                  'updated_at': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data pegawai berhasil diperbarui!')),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan Perubahan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePegawai(PegawaiModel pegawai) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pegawai'),
        content: Text('Apakah Anda yakin ingin menghapus data "${pegawai.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('pegawai').doc(pegawai.uid).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data pegawai berhasil dihapus!')),
                  );
                }
              },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari Berdasarkan Nama atau NIP...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pegawai').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada data pegawai.'));
                }

                final listPegawai = snapshot.data!.docs.map((doc) {
                  return PegawaiModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                }).where((p) {
                  return p.nama.toLowerCase().contains(_searchQuery) ||
                      p.nip.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.separated(
                  itemCount: listPegawai.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pegawai = listPegawai[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Text(pegawai.nama.isNotEmpty ? pegawai.nama[0] : 'P'),
                      ),
                      title: Text(pegawai.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('NIP: ${pegawai.nip} | ${pegawai.instalasi} - ${pegawai.ruangan}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _showEditDialog(pegawai),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeletePegawai(pegawai),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}