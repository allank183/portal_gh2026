import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/model_pegawai.dart';
import '../../../widgets/premium_header.dart';
import '../../pelatihan/upload_pelatihan.dart';
import 'tabs/tab_detail_pegawai.dart';
import 'tabs/tab_status_sertifikat.dart';

class ScreenProfilSaya extends StatefulWidget {
  final PegawaiModel pegawai;

  const ScreenProfilSaya({super.key, required this.pegawai});

  @override
  State<ScreenProfilSaya> createState() => _ScreenProfilSayaState();
}

class _ScreenProfilSayaState extends State<ScreenProfilSaya> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Premium Header Biru
          const PremiumHeader(
            title: 'Profil Saya',
            subtitle: 'AKUN & KINERJA',
            borderRadius: BorderRadius.zero,
          ),

          // Konten Utama
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildCompactProfileHeader(context),
                  const SizedBox(height: 20),

                  // Tab Controller Navigation Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorColor: Colors.transparent,
                      labelColor: const Color(0xFF2563EB),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Status Sertifikat"),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Detail Informasi Pegawai"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Content Area
                  SizedBox(
                    height: 550,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        TabStatusSertifikat(pegawai: widget.pegawai),
                        TabDetailPegawai(pegawai: widget.pegawai),
                      ],
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

  Widget _buildCompactProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)), // Border Luar Lebih Tegas
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 700;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      widget.pegawai.nama.isNotEmpty ? widget.pegawai.nama[0].toUpperCase() : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.pegawai.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              widget.pegawai.kelompok.isNotEmpty ? widget.pegawai.kelompok : 'Umum',
                              const Color(0xFF2563EB),
                              const Color(0xFFEFF6FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIP. ${widget.pegawai.nip}  •  Role: ${widget.pegawai.role.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Unit/Ruangan: ${widget.pegawai.ruangan.isNotEmpty ? widget.pegawai.ruangan : '-'} (${widget.pegawai.instalasi})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadSertifikatPage(
                              pegawaiData: widget.pegawai.toFirestore(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Upload Sertifikat',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),

              // Divider Horizontal Dipertegas
              const Divider(
                height: 32,
                thickness: 1.5,
                color: Color(0xFFCBD5E1),
              ),

              // Bagian Statistik dengan Divider Vertikal Tegas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total JPL', widget.pegawai.totalJpl.toString(), const Color(0xFF2563EB)),
                  _buildStatDivider(),
                  _buildStatItem('Total SKP', widget.pegawai.totalSkp.toString(), const Color(0xFF059669)),
                  _buildStatDivider(),
                  _buildStatItem('Sertifikat', widget.pegawai.totalSertifikat.toString(), const Color(0xFFD97706)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  // Divider Vertikal Dipertegas
  Widget _buildStatDivider() {
    return Container(
      height: 32,
      width: 1.5,
      color: const Color(0xFFCBD5E1),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}