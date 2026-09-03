import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/repo_pelatihan.dart';
import '../../widgets/premium_header.dart';
import 'upload_pelatihan.dart';

class ScreenPelatihanPegawai extends StatefulWidget {
  const ScreenPelatihanPegawai({super.key});

  @override
  State<ScreenPelatihanPegawai> createState() => _ScreenPelatihanPegawaiState();
}

class _ScreenPelatihanPegawaiState extends State<ScreenPelatihanPegawai> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allPegawai = [];
  List<DocumentSnapshot> _filteredPegawai = [];
  bool _isLoading = true;

  // Variable Filter State
  String _selectedKelompok = 'Semua';
  String _selectedCapaian = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchPegawaiData();
  }

  Future<void> _fetchPegawaiData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pegawai').get();
      final docs = snapshot.docs;

      docs.sort((a, b) {
        final num jplA = a.data()['total_jpl'] ?? 0;
        final num jplB = b.data()['total_jpl'] ?? 0;
        return jplB.compareTo(jplA);
      });

      if (mounted) {
        setState(() {
          _allPegawai = docs;
          _filteredPegawai = docs;
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredPegawai = _allPegawai.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nama = (data['nama'] ?? '').toString().toLowerCase();
        final nip = (data['nip'] ?? '').toString().toLowerCase();
        final kelompok = (data['kelompok'] ?? 'Umum').toString();
        final double jpl = ((data['total_jpl'] ?? 0)).toDouble();

        bool matchQuery = q.isEmpty || nama.contains(q) || nip.contains(q);
        bool matchKelompok = _selectedKelompok == 'Semua' || kelompok.toLowerCase() == _selectedKelompok.toLowerCase();

        bool matchCapaian = true;
        if (_selectedCapaian == 'Tercapai') {
          matchCapaian = jpl >= 40.0;
        } else if (_selectedCapaian == 'Belum Tercapai') {
          matchCapaian = jpl < 40.0;
        }

        return matchQuery && matchKelompok && matchCapaian;
      }).toList();

      _filteredPegawai.sort((a, b) {
        final double jplA = ((a.data() as Map<String, dynamic>)['total_jpl'] ?? 0.0).toDouble();
        final double jplB = ((b.data() as Map<String, dynamic>)['total_jpl'] ?? 0.0).toDouble();
        return jplB.compareTo(jplA);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Pelatihan Pegawai',
            subtitle: 'Monitoring',
            borderRadius: BorderRadius.zero,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Judul & Kontrol Filter
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 850;
                      return isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rekapitulasi JPL & SKP Pegawai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFilterSection(),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rekapitulasi JPL & SKP Pegawai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          _buildFilterSection(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Table Container
                  _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth < 750 ? 750 : constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMaxHeight: 68,
                                dividerThickness: 1,
                                horizontalMargin: 16,
                                columnSpacing: 12,
                                headingTextStyle: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                                columns: const [
                                  DataColumn(label: Text('NAMA PEGAWAI')),
                                  DataColumn(label: Text('KELOMPOK')),
                                  DataColumn(label: Text('TOTAL JPL')),
                                  DataColumn(label: Text('TOTAL SKP')),
                                  DataColumn(label: Text('SERTIFIKAT')),
                                  DataColumn(label: Text('AKSI')),
                                ],
                                rows: _filteredPegawai.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final double totalJpl = (data['total_jpl'] ?? 0).toDouble();
                                  final double totalSkp = (data['total_skp'] ?? 0).toDouble();
                                  final int totalSertifikat = data['total_sertifikat'] ?? 0;
                                  final String nama = data['nama'] ?? '-';
                                  final String nip = data['nip'] ?? '-';
                                  final String kelompok = data['kelompok'] ?? 'Umum';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                nama,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'NIP. $nip',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10.5,
                                                  color: const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(_buildKelompokBadge(kelompok)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: totalJpl >= 40.0 ? const Color(0xFFECFDF5) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            totalJpl.toStringAsFixed(1),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              color: totalJpl >= 40.0 ? const Color(0xFF059669) : const Color(0xFF0F172A),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          totalSkp.toStringAsFixed(1),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$totalSertifikat Sertifikat',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildActionButton(
                                              icon: Icons.upload_file_rounded,
                                              color: const Color(0xFF2563EB),
                                              bgColor: const Color(0xFFEFF6FF),
                                              tooltip: 'Upload Sertifikat',
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => UploadSertifikatPage(pegawaiData: data),
                                                  ),
                                                );
                                                _fetchPegawaiData();
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            _buildActionButton(
                                              icon: Icons.sync_rounded,
                                              color: const Color(0xFFD97706),
                                              bgColor: const Color(0xFFFFFBEB),
                                              tooltip: 'Sync / Hitung Ulang',
                                              onPressed: () async {
                                                final nipVal = data['nip'] ?? '';
                                                final uid = doc.id;

                                                if (nipVal.isNotEmpty) {
                                                  await PelatihanRepository().recalculatePegawaiStats(
                                                    uid: uid,
                                                    nip: nipVal,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Data JPL & Sertifikat NIP $nipVal berhasil disinkronkan!'),
                                                        backgroundColor: const Color(0xFF0F172A),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  }
                                                  _fetchPegawaiData();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildDropdownFilter(
          label: 'Kelompok',
          value: _selectedKelompok,
          items: ['Semua', 'Medis', 'Nakes', 'Admin'],
          onChanged: (val) {
            if (val != null) {
              _selectedKelompok = val;
              _applyFilter();
            }
          },
        ),
        _buildDropdownFilter(
          label: 'Capaian',
          value: _selectedCapaian,
          items: ['Semua', 'Tercapai', 'Belum Tercapai'],
          onChanged: (val) {
            if (val != null) {
              _selectedCapaian = val;
              _applyFilter();
            }
          },
        ),
        SizedBox(
          width: 240,
          child: _buildSearchField(),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelompokBadge(String kelompok) {
    Color bgColor;
    Color textColor;

    switch (kelompok.toLowerCase()) {
      case 'medis':
        bgColor = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF4F46E5);
        break;
      case 'nakes':
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF16A34A);
        break;
      case 'admin':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kelompok,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Cari Nama / NIP...',
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
      onChanged: (_) => _applyFilter(),
    );
  }
}