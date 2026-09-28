# Implementation Plan - Modul Kegiatan Mahasiswa

Implementasi modul **Kegiatan Mahasiswa** secara lengkap yang mencakup ringkasan metrik (Total Mahasiswa, Mahasiswa Aktif, Total Pendapatan), daftar rincian mahasiswa yang melakukan kegiatan, serta form pendaftaran/pencatatan awal masuk kegiatan mahasiswa.

## User Review Required

> [!IMPORTANT]
> - **Database Backend (Cloudflare D1)**: Penambahan tabel baru `mahasiswa_kegiatan` pada Cloudflare Worker (`index.js`) untuk menyimpan data registrasi kegiatan mahasiswa, kampus asal, jenis kegiatan, jenjang, durasi, dan biaya/pendapatan.
> - **Struktur Tab**: Modul `ScreenKegiatanMahasiswa` akan diperkaya dengan Dashboard Ringkasan & Tabel Rincian Kegiatan Mahasiswa, berdampingan dengan tab Master Kampus & Master Tarif yang sudah ada sebelumnya.

## Open Questions
- Apakah perhitungan pendapatan dihitung otomatis berdasarkan tarif per satuan (hari/pekan/bulan) dikali durasi? Ya, kami merencanakan kalkulasi otomatis menggunakan data dari `Master Tarif`.

## Proposed Changes

### 1. Model & Repository (`lib/`)
#### [NEW] [model_mahasiswa.dart](file:///D:/ALLANK/proding/portal_gh2026/lib/models/model_mahasiswa.dart)
- Membuat kelas `MahasiswaKegiatanModel` untuk memetakan data mahasiswa peserta kegiatan (ID, nama, NIM, asal kampus, jenis kegiatan, jenjang, tanggal mulai, durasi, satuan, biaya, status, catatan).

#### [MODIFY] [repo_mahasiswa.dart](file:///D:/ALLANK/proding/portal_gh2026/lib/repositories/repo_mahasiswa.dart)
- Menambahkan metode untuk mengambil daftar mahasiswa kegiatan (`getAllMahasiswaKegiatan`), menambah data (`addMahasiswaKegiatan`), mengupdate status/data (`updateMahasiswaKegiatan`), dan menghapus (`deleteMahasiswaKegiatan`).

### 2. Backend API (`index.js`)
#### [MODIFY] [index.js](file:///D:/ALLANK/proding/portal_gh2026/index.js)
- Menambahkan endpoint Cloudflare Worker:
  - `GET /mahasiswa-kegiatan/all`
  - `POST /mahasiswa-kegiatan/add`
  - `POST /mahasiswa-kegiatan/update`
  - `GET /mahasiswa-kegiatan/delete?id=...`

### 3. UI Screen (`lib/screens/mahasiswa/`)
#### [MODIFY] [screen_kegiatan_mahasiswa.dart](file:///D:/ALLANK/proding/portal_gh2026/lib/screens/mahasiswa/screen_kegiatan_mahasiswa.dart)
- Mengembangkan UI menjadi Tabbed Screen:
  1. **Tab Kegiatan Mahasiswa**:
     - **Kartu Metrik Ringkasan**: Total Mahasiswa, Mahasiswa Aktif, Total Pendapatan (Rp).
     - **Tabel / Daftar Rincian Mahasiswa**: Menampilkan nama, NIM, asal kampus, jenis kegiatan, status, dan nominal pendapatan.
     - **Tombol Form Registrasi Awal Masuk**: Dialog form interaktif bagi mahasiswa/admin untuk mencatat data kegiatan baru (lengkap dengan pilihan kampus, jenis kegiatan, dan kalkulasi otomatis tarif).
  2. **Tab Master Kampus** (`TabMasterKampus`)
  3. **Tab Master Tarif** (`TabMasterTarif`)

## Verification Plan

### Automated Tests
- Menjalankan analisis kode (`analyze_file`) pada file Dart yang diubah.

### Manual Verification
- Membuka menu Mahasiswa di aplikasi Flutter, menguji form tambah kegiatan mahasiswa baru, memverifikasi kalkulasi total mahasiswa & total pendapatan, serta menguji daftar rincian.
