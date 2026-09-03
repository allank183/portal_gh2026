import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/model_pegawai.dart';

class TabDetailPegawai extends StatelessWidget {
  final PegawaiModel pegawai;

  const TabDetailPegawai({super.key, required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 65,
                child: _buildMainInfoCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 35,
                child: _buildSideInfoCard(),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainInfoCard(),
            const SizedBox(height: 12),
            _buildSideInfoCard(),
          ],
        );
      },
    );
  }

  // Card Utama (Kiri) - Disusun compact tanpa scroll
  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.badge_rounded, 'Informasi Kepegawaian'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildListTile(Icons.card_membership_rounded, 'Golongan', pegawai.golongan, const Color(0xFF2563EB))),
              const SizedBox(width: 8),
              Expanded(child: _buildListTile(Icons.workspace_premium_rounded, 'Status', pegawai.statusKepegawaian, const Color(0xFFEA580C))),
              const SizedBox(width: 8),
              Expanded(child: _buildListTile(Icons.schedule_rounded, 'Jadwal', pegawai.jadwalKerja, const Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildListTile(Icons.wc_rounded, 'Jenis Kelamin', pegawai.jenisKelamin, const Color(0xFF4F46E5))),
              const SizedBox(width: 8),
              const Expanded(flex: 2, child: SizedBox()), // Placeholder penyeimbang layout 3 kolom
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          _buildSectionHeader(Icons.business_center_rounded, 'Penugasan & Unit Kerja'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildListTile(Icons.store_rounded, 'Instalasi', pegawai.instalasi, const Color(0xFF0284C7))),
              const SizedBox(width: 8),
              Expanded(child: _buildListTile(Icons.meeting_room_rounded, 'Ruangan', pegawai.ruangan, const Color(0xFF7C3AED))),
              const SizedBox(width: 8),
              Expanded(
                child: pegawai.kelompok.isNotEmpty
                    ? _buildListTile(Icons.grid_view_rounded, 'Kelompok SDM', pegawai.kelompok, const Color(0xFFD97706))
                    : const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card Samping (Kanan)
  Widget _buildSideInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.contact_phone_rounded, 'Kontak & Akun'),
          const SizedBox(height: 8),
          _buildListTile(Icons.email_rounded, 'Email', pegawai.email, const Color(0xFF0284C7)),
          const SizedBox(height: 6),
          _buildListTile(Icons.phone_rounded, 'No. HP', pegawai.kontak, const Color(0xFF16A34A)),
          const SizedBox(height: 6),
          _buildListTile(
            Icons.check_circle_rounded,
            'Status Akun',
            pegawai.isActive ? 'Aktif' : 'Non-Aktif',
            pegawai.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),

          if (pegawai.keterangan.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'Keterangan: ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                  ),
                  Expanded(
                    child: Text(
                      pegawai.keterangan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF78350F)),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  value.isNotEmpty ? value : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}