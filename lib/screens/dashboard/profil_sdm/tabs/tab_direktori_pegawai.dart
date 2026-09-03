import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/model_pegawai.dart';

class TabDirektoriPegawai extends StatefulWidget {
  final List<PegawaiModel> listPegawai;
  final Map<String, Color> colorMap;

  const TabDirektoriPegawai({
    super.key,
    required this.listPegawai,
    required this.colorMap,
  });

  @override
  State<TabDirektoriPegawai> createState() => _TabDirektoriPegawaiState();
}

class _TabDirektoriPegawaiState extends State<TabDirektoriPegawai> {
  String _searchQuery = '';

  @override
// DI DALAM tab_direktori_pegawai.dart

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.listPegawai.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.nama.toLowerCase().contains(query) ||
          p.nip.toLowerCase().contains(query) ||
          p.instalasi.toLowerCase().contains(query) ||
          p.ruangan.toLowerCase().contains(query);
    }).toList();

    // BUNGKUS CONTAINER DENGAN SingleChildScrollView TERLEBIH DAHULU
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24.0), // Padding bawah agar scroll nyaman
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tambahkan ini agar mengikuti tinggi konten
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direktori Pegawai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Menampilkan ${filteredList.length} dari ${widget.listPegawai.length} data pegawai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 300,
                    height: 42,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari Nama, NIP, Ruangan...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 1200
                    ? MediaQuery.of(context).size.width - 120
                    : 1000,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: Colors.white,
                    dividerColor: const Color(0xFFF1F5F9),
                  ),
                  child: PaginatedDataTable(
                    rowsPerPage: 10,
                    horizontalMargin: 20,
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(label: _tableHeader('No')),
                      DataColumn(label: _tableHeader('Nama Lengkap')),
                      DataColumn(label: _tableHeader('NIP')),
                      DataColumn(label: _tableHeader('Kelompok')),
                      DataColumn(label: _tableHeader('Status')),
                      DataColumn(label: _tableHeader('Golongan')),
                      DataColumn(label: _tableHeader('Instalasi')),
                      DataColumn(label: _tableHeader('Ruangan')),
                    ],
                    source: ModernPegawaiTableSource(filteredList, widget.colorMap),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class ModernPegawaiTableSource extends DataTableSource {
  final List<PegawaiModel> list;
  final Map<String, Color> colorMap;

  ModernPegawaiTableSource(this.list, this.colorMap);

  @override
  DataRow? getRow(int index) {
    if (index >= list.length) return null;
    final p = list[index];

    // Fungsi pembantu badge status kepegawaian & kelompok
    Widget buildBadge(String text) {
      Color textColor = colorMap[text] ?? const Color(0xFF475569);

      // Menentukan warna background lembut (Soft Tone)
      Color bgColor;
      switch (text.toUpperCase()) {
        case 'MEDIS':
          bgColor = const Color(0xFFEEF2FF);
          break;
        case 'NAKES':
          bgColor = const Color(0xFFF0FDF4);
          break;
        case 'ADMIN':
        case 'PNS':
          bgColor = const Color(0xFFFFF7ED);
          break;
        case 'P3K':
          bgColor = const Color(0xFFFEF2F2);
          break;
        case 'BLU':
        default:
          bgColor = const Color(0xFFF1F5F9);
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );
    }

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${index + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFEFF6FF), // Soft Blue
                child: Text(
                  p.nama.isNotEmpty ? p.nama[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  p.nama,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(p.nip, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)))),
        DataCell(buildBadge(p.kelompok)),
        DataCell(buildBadge(p.statusKepegawaian)),
        DataCell(Text(p.golongan.isEmpty ? '-' : p.golongan, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)))),
        DataCell(Text(p.instalasi, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)))),
        DataCell(Text(p.ruangan, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => list.length;
  @override
  int get selectedRowCount => 0;
}