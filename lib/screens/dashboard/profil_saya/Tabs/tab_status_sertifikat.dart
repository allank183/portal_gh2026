import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/model_pegawai.dart';
import '../../../../models/model_pelatihan.dart';
import '../../../../repositories/repo_pelatihan.dart';

class TabStatusSertifikat extends StatelessWidget {
  final PegawaiModel pegawai;

  const TabStatusSertifikat({super.key, required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            // Header Tab Navigation (Pending, Approved, Rejected)
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stream Builder Data Sertifikat
            Expanded(
              child: StreamBuilder<List<PelatihanModel>>(
                stream: PelatihanRepository().getRiwayatPelatihanPegawaiStream(pegawai.nip),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint('Error Firestore TabStatusSertifikat: ${snapshot.error}');
                    return Center(
                      child: SelectableText(
                        'Gagal memuat data sertifikat:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13),
                      ),
                    );
                  }

                  final allData = snapshot.data ?? [];

                  // Filter berdasarkan status
                  final pendingList = allData.where((e) => e.status.toLowerCase() == 'pending').toList();
                  final approvedList = allData.where((e) =>
                  e.status.toLowerCase() == 'approved' ||
                      e.status.toLowerCase() == 'acc' ||
                      e.status.toLowerCase() == 'disetujui'
                  ).toList();
                  final rejectedList = allData.where((e) =>
                  e.status.toLowerCase() == 'rejected' ||
                      e.status.toLowerCase() == 'ditolak'
                  ).toList();

                  return TabBarView(
                    children: [
                      _buildListSertifikat(pendingList, 'Belum ada sertifikat dalam status Pending'),
                      _buildListSertifikat(approvedList, 'Belum ada sertifikat yang Disetujui (Approved)'),
                      _buildListSertifikat(rejectedList, 'Belum ada sertifikat yang Ditolak (Rejected)'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget untuk Menampilkan Daftar Sertifikat per Tab
  Widget _buildListSertifikat(List<PelatihanModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final String tglUpload = item.createdAt != null
            ? item.createdAt.toString().split(' ')[0]
            : '-';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judulPelatihan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Penyelenggara: ${item.penyelenggara}  •  JPL: ${item.jumlahJpl}  •  Tgl: $tglUpload',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Menampilkan alasan/catatan admin jika status Rejected
                    if (item.status.toLowerCase() == 'rejected' &&
                        (item.catatanAdmin?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          'Alasan Penolakan: ${item.catatanAdmin}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),
              _buildStatusBadge(item.status),
            ],
          ),
        );
      },
    );
  }

  // Helper Badge Status (Pill)
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'acc':
      case 'disetujui':
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        icon = Icons.check_circle_rounded;
        label = 'Approved';
        break;
      case 'rejected':
      case 'ditolak':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        icon = Icons.hourglass_bottom_rounded;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}