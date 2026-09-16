import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/model_pegawai.dart';
import '../../../../services/service_trigger.dart';

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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: refreshTrigger,
      builder: (context, _) {
        final filteredList = widget.listPegawai.where((p) {
          final query = _searchQuery.toLowerCase();
          return p.nama.toLowerCase().contains(query) ||
              p.nip.toLowerCase().contains(query) ||
              p.instalasi.toLowerCase().contains(query) ||
              p.ruangan.toLowerCase().contains(query);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24.0),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      bool isMobile = boxConstraints.maxWidth < 650;
                      return isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleSection(filteredList.length),
                                const SizedBox(height: 16),
                                _buildSearchField(),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildTitleSection(filteredList.length)),
                                const SizedBox(width: 16),
                                _buildSearchField(),
                              ],
                            );
                    },
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isCompact = constraints.maxWidth < 950;

                    return Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: Colors.white,
                        dividerColor: const Color(0xFFF1F5F9),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: PaginatedDataTable(
                          rowsPerPage: 10,
                          horizontalMargin: 16,
                          columnSpacing: isCompact ? 12 : 24,
                          showCheckboxColumn: false,
                          columns: [
                            DataColumn(
                              label: _tableHeader('Nama Lengkap', isCenter: false), // Dikembalikan ke Left Aligned agar rapi
                            ),
                            DataColumn(
                              label: _tableHeader('NIP', isCenter: true),
                            ),
                            DataColumn(
                              label: _tableHeader('Kelompok', isCenter: true),
                            ),
                            DataColumn(
                              label: _tableHeader('Status', isCenter: true),
                            ),
                            if (!isCompact) 
                              DataColumn(
                                label: _tableHeader('Golongan', isCenter: true),
                              ),
                            DataColumn(
                              label: _tableHeader('Instalasi', isCenter: true),
                            ),
                            DataColumn(
                              label: _tableHeader('Ruangan', isCenter: true),
                            ),
                          ],
                          source: ModernPegawaiTableSource(
                            filteredList,
                            widget.colorMap,
                            isCompact: isCompact,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleSection(int filteredCount) {
    return Column(
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
          'Menampilkan $filteredCount dari ${widget.listPegawai.length} data pegawai',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
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
    );
  }

  Widget _tableHeader(String text, {required bool isCenter}) {
    return Expanded(
      child: Container(
        alignment: isCenter ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class ModernPegawaiTableSource extends DataTableSource {
  final List<PegawaiModel> list;
  final Map<String, Color> colorMap;
  final bool isCompact;

  ModernPegawaiTableSource(this.list, this.colorMap, {required this.isCompact});

  @override
  DataRow? getRow(int index) {
    if (index >= list.length) return null;
    final p = list[index];

    Widget buildBadge(String text) {
      Color textColor = colorMap[text] ?? const Color(0xFF475569);
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
        DataCell(
          // Dikembalikan ke rata kiri (tanpa Center) agar avatar dan nama lurus membentuk garis anchor vertikal di kiri
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFEFF6FF),
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
                child: Container(
                  constraints: BoxConstraints(maxWidth: isCompact ? 140 : 250),
                  child: Text(
                    p.nama,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        DataCell(Container(alignment: Alignment.center, child: Text(p.nip, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))))),
        DataCell(Container(alignment: Alignment.center, child: buildBadge(p.kelompok))),
        DataCell(Container(alignment: Alignment.center, child: buildBadge(p.statusKepegawaian))),
        if (!isCompact) DataCell(Container(alignment: Alignment.center, child: Text(p.golongan.isEmpty ? '-' : p.golongan, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))))),
        DataCell(
          Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(maxWidth: isCompact ? 120 : 200),
            child: Text(
              p.instalasi,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        DataCell(
          Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(maxWidth: isCompact ? 120 : 200),
            child: Text(
              p.ruangan,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
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