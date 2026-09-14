import 'package:flutter/material.dart';

/// Pusat Kendali Refresh Data (Action-Based Refresh)
/// Gunakan ini untuk memicu pembaruan data di layar mana pun tanpa polling.
class RefreshTrigger extends ChangeNotifier {
  
  // 1. Pemicu Refresh Pelatihan (Upload, Verifikasi)
  void notifyPelatihanUpdate() {
    notifyListeners();
  }

  // 2. Pemicu Refresh Presensi (Absen Masuk, Pulang, Izin)
  void notifyPresensiUpdate() {
    notifyListeners();
    // Biasanya saat presensi berubah, statistik dashboard juga perlu update
    notifyStatistikUpdate();
  }

  // 3. Pemicu Refresh Profil Pegawai
  void notifyPegawaiUpdate() {
    notifyListeners();
  }

  // 4. Pemicu Refresh Statistik Dashboard
  void notifyStatistikUpdate() {
    notifyListeners();
  }
}

// Global Singleton
final refreshTrigger = RefreshTrigger();
