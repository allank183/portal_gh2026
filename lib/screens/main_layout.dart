import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/model_pegawai.dart';
import '../repositories/repo_pegawai.dart';
import 'dashboard/screen_dashboard_utama.dart';
import 'pelatihan/screen_pelatihan_pegawai.dart';
import 'pelatihan/verif_pelatihan/screen_verifikasi_pelatihan.dart';
import 'mahasiswa/screen_kegiatan_mahasiswa.dart';
import 'presensi/screen_presensi.dart';
import 'presensi/screen_verifikasi_presensi.dart';
import 'admin/admin_page.dart';
import 'dashboard/profil_saya/profil_saya.dart';
import 'link_eksternal.dart';
import 'about_system_screen.dart';
import 'dashboard/profil_sdm/screen_profil_sdm.dart';
import 'ai/screen_marsal_chat.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  PegawaiModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Beri jeda singkat agar Firebase Auth di Web stabil
      await Future.delayed(const Duration(milliseconds: 600));
      final user = FirebaseAuth.instance.currentUser;
      print("INFO: UID YANG SEDANG LOGIN ADALAH -> ${user?.uid}");

      final pegawai = await PegawaiRepository().getCurrentPegawai();
      if (mounted) {
        setState(() {
          _currentUser = pegawai;
          _isLoading = false;
        });

        // --- TAMBAHKAN PERINGATAN INI ---
        if (pegawai == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil tidak ditemukan di database D1. Harap hubungi Admin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat data pegawai: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool isDesktop = MediaQuery.of(context).size.width >= 850;

    // Pengecekan Hak Akses Verifikasi & Admin
    bool canVerifyPelatihan = _currentUser?.isVerifikator ?? false;
    bool canVerifyPresensi = (_currentUser?.isSuperAdmin ?? false) ||
        (_currentUser?.permissions.contains('presensi') ?? false) ||
        (_currentUser?.permissions.contains('admin') ?? false);
    bool isSuperAdmin = _currentUser?.isSuperAdmin ?? false;

    final List<_NavItem> menuItems = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.auto_awesome, label: 'Marsal AI'),
      _NavItem(icon: Icons.badge_rounded, label: 'Profil SDM'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil Saya'),
      _NavItem(icon: Icons.school_rounded, label: 'Pelatihan'),
      _NavItem(icon: Icons.groups_rounded, label: 'Mahasiswa'),
      _NavItem(icon: Icons.fingerprint_rounded, label: 'Presensi'),
      _NavItem(icon: Icons.link_rounded, label: 'Tautan Penting'),
      _NavItem(icon: Icons.info_outline_rounded, label: 'Tentang Sistem'),
      // Modul Khusus Admin/Verifikator di posisi paling bawah
      if (canVerifyPelatihan)
        _NavItem(icon: Icons.fact_check_rounded, label: 'Verifikasi Pelatihan'),
      if (canVerifyPresensi)
        _NavItem(icon: Icons.assignment_turned_in_rounded, label: 'Verifikasi Presensi'),
      if (isSuperAdmin)
        _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin Page'),
    ];

    final List<Widget> screens = [
      const ScreenDashboardUtama(),
      ScreenMarsalChat(userData: _currentUser?.toFirestore() ?? {}),
      const ScreenProfilSdm(),
      _currentUser != null
          ? ScreenProfilSaya(pegawai: _currentUser!)
          : const Center(child: CircularProgressIndicator()),
      const ScreenPelatihanPegawai(),
      const ScreenKegiatanMahasiswa(),
      const ScreenPresensi(),
      const ExternalLinksScreen(),
      const AboutSystemScreen(),
      if (canVerifyPelatihan)
        ScreenVerifikasiPelatihan(adminId: _currentUser?.uid ?? ''),
      if (canVerifyPresensi)
        const ScreenVerifikasiPresensi(),
      if (isSuperAdmin)
        const ScreenImportPegawai(),
    ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Stack(
        children: [
          // 1. Tampilan Utama (Sidebar + Konten)
          Row(
            children: [
              // Sidebar Desktop
              if (isDesktop)
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A), // Dark Slate Navy
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Branding Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.domain_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PORTAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Laporan Kinerja',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFF1E293B)),

                      // Menu List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            final isSelected = _selectedIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => setState(() => _selectedIndex = index),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Logout Button
                      const Divider(height: 1, color: Color(0xFF1E293B)),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: const Icon(Icons.logout_rounded, color: Color(0xFFF87171)),
                          title: Text(
                            'Keluar',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFF87171),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),

              // Konten Utama
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: screens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Konfirmasi Keluar'),
            ],
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}