import 'package:flutter/material.dart';

class RefreshTrigger extends ChangeNotifier {
  // Panggil ini saat data Pelatihan berubah (Upload/Approve/Reject)
  void notifyPelatihanUpdate() {
    notifyListeners();
  }

  // Panggil ini saat data Presensi berubah (Absen Masuk/Pulang/Izin)
  void notifyPresensiUpdate() {
    notifyListeners();
  }
}

// Inisialisasi secara global agar bisa dipanggil dari mana saja
final refreshTrigger = RefreshTrigger();
