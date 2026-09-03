import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class ServiceLocation {
  // Helper internal untuk membaca double dari .env dengan Exception aman
  double _getEnvDouble(String key) {
    final value = dotenv.env[key];
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) {
      throw Exception('Konfigurasi $key tidak ditemukan atau tidak valid di file .env');
    }
    return parsed;
  }

  double get targetLatitude => _getEnvDouble('OFFICE_LATITUDE');
  double get targetLongitude => _getEnvDouble('OFFICE_LONGITUDE');
  double get maxRadiusInMeters => _getEnvDouble('OFFICE_MAX_RADIUS_METERS');

  /// Mengambil lokasi saat ini dan memvalidasi radius kantor
  Future<Position> getCurrentLocationAndValidate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan GPS/Lokasi tidak aktif. Harap nyalakan GPS Anda.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Harap izinkan melalui pengaturan perangkat/browser.');
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );

    if (distanceInMeters > maxRadiusInMeters) {
      throw Exception(
        'Anda berada di luar radius kantor (${distanceInMeters.toStringAsFixed(0)}m dari lokasi kantor).',
      );
    }

    return currentPosition;
  }
}