export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Header CORS standar untuk Flutter Web & API Access
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, HEAD, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
    };

    // Respon otomatis untuk Preflight Request dari Browser
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // --- ENDPOINT: STATISTIK ---
      if (url.pathname === "/statistik" && request.method === "GET") {
        const stats = await env.portal_gh2026.prepare(`
          SELECT 
            COUNT(*) as totalPegawai,
            SUM(CASE WHEN jenis_kelamin = 'L' THEN 1 ELSE 0 END) as totalLaki,
            SUM(CASE WHEN jenis_kelamin = 'P' THEN 1 ELSE 0 END) as totalPerempuan,
            SUM(CASE WHEN kelompok = 'Medis' THEN 1 ELSE 0 END) as totalMedis,
            SUM(CASE WHEN kelompok = 'Nakes' THEN 1 ELSE 0 END) as totalNakes,
            SUM(CASE WHEN kelompok = 'Admin' THEN 1 ELSE 0 END) as totalAdmin,
            SUM(CASE WHEN status_kepegawaian = 'PNS' THEN 1 ELSE 0 END) as totalPns,
            SUM(CASE WHEN status_kepegawaian IN ('P3K', 'PPPK') THEN 1 ELSE 0 END) as totalP3k,
            SUM(CASE WHEN status_kepegawaian = 'BLU' THEN 1 ELSE 0 END) as totalBlu,
            SUM(CASE WHEN total_jpl >= 40.0 THEN 1 ELSE 0 END) as totalCukup40Jpl
          FROM pegawai
        `).first();
        return new Response(JSON.stringify(stats), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT: TAMBAH PELATIHAN BARU ---
      if (url.pathname === "/pelatihan/add" && request.method === "POST") {
        const p = await request.json();
        await env.portal_gh2026.prepare(`
          INSERT INTO riwayat_pelatihan 
          (uid, nip, nama_pegawai, nomor_sertifikat, judul_pelatihan, penyelenggara, tanggal_kegiatan, jumlah_jpl, jumlah_skp, file_url, status, is_possible_duplicate, catatan_admin)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          p.uid, p.nip, p.nama_pegawai, p.nomor_sertifikat, p.judul_pelatihan, 
          p.penyelenggara, p.tanggal_kegiatan, p.jumlah_jpl, p.jumlah_skp, 
          p.file_url, p.status || 'pending', p.is_possible_duplicate || 0, p.catatan_admin || ''
        ).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT: APPROVE SERTIFIKAT ATOMIK ---
      if (url.pathname === "/pelatihan/approve" && request.method === "POST") {
        const d = await request.json();
        await env.portal_gh2026.batch([
          env.portal_gh2026.prepare(`
            UPDATE riwayat_pelatihan 
            SET status = 'approved', verified_by = ?, verified_at = CURRENT_TIMESTAMP 
            WHERE id = ?
          `).bind(d.admin_id, d.id),
          
          env.portal_gh2026.prepare(`
            UPDATE pegawai SET 
              total_jpl = (SELECT COALESCE(SUM(jumlah_jpl), 0) FROM riwayat_pelatihan WHERE uid = ? AND status = 'approved'),
              total_sertifikat = (SELECT COUNT(*) FROM riwayat_pelatihan WHERE uid = ? AND status = 'approved')
            WHERE uid = ?
          `).bind(d.uid, d.uid, d.uid)
        ]);
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT: REJECT SERTIFIKAT ---
      if (url.pathname === "/pelatihan/reject" && request.method === "POST") {
        const d = await request.json();
        await env.portal_gh2026.prepare(`
          UPDATE riwayat_pelatihan 
          SET status = 'rejected', verified_by = ?, catatan_admin = ?, verified_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `).bind(d.admin_id, d.catatan, d.id).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT: AMBIL ANTREAN PENDING UNTUK ADMIN ---
      if (url.pathname === "/pelatihan/pending" && request.method === "GET") {
        const { results } = await env.portal_gh2026.prepare(
          "SELECT * FROM riwayat_pelatihan WHERE status = 'pending' ORDER BY created_at DESC"
        ).all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT SYNC DATA PEGAWAI ---
      if (url.pathname === "/sync-pegawai" && request.method === "POST") {
        const dataPegawai = await request.json();
        const statements = dataPegawai.map(p => {
          return env.portal_gh2026.prepare(`
            INSERT OR REPLACE INTO pegawai 
            (uid, nip, nama, email, role, permissions, golongan, instalasi, jenis_kelamin, kelompok, ruangan, status_kepegawaian, jadwal_kerja, total_jpl, total_sertifikat, total_skp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).bind(
            p.uid, p.nip, p.nama, p.email, p.role, 
            p.permissions || '', 
            p.golongan, p.instalasi, p.jenis_kelamin, p.kelompok, p.ruangan, 
            p.status_kepegawaian, p.jadwal_kerja, p.total_jpl, p.total_sertifikat, p.total_skp
          );
        });
        await env.portal_gh2026.batch(statements);
        return new Response(JSON.stringify({ success: true, count: dataPegawai.length }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT SYNC PELATIHAN ---
      if (url.pathname === "/sync-pelatihan" && request.method === "POST") {
        const dataPelatihan = await request.json();
        const statements = dataPelatihan.map(p => {
          return env.portal_gh2026.prepare(`
            INSERT INTO riwayat_pelatihan (uid, nip, judul_pelatihan, jumlah_jpl, status, file_url)
            VALUES (?, ?, ?, ?, ?, ?)
          `).bind(p.uid, p.nip, p.judul_pelatihan, p.jumlah_jpl, p.status, p.file_url);
        });
        await env.portal_gh2026.batch(statements);
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT SYNC PRESENSI & IZIN ---
      if (url.pathname === "/sync-presensi-izin" && request.method === "POST") {
        const { listIzin, listPresensi } = await request.json();
        const batch = [];
        
        listIzin.forEach(i => {
          batch.push(env.portal_gh2026.prepare(`
            INSERT OR REPLACE INTO pengajuan_izin (id, uid, nama_pegawai, nip, jenis_izin, alasan, status, lampiran_url, tanggal_pengajuan)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).bind(i.id, i.uid, i.nama_pegawai, i.nip, i.jenis_izin, i.alasan, i.status, i.lampiran_url, i.tanggal_pengajuan));
        });

        listPresensi.forEach(p => {
  batch.push(env.portal_gh2026.prepare(`
    INSERT INTO presensi (
      uid, nip, nama_pegawai, tanggal, jam_masuk, jam_pulang, 
      status, jadwal_kerja, tipe_shift, menit_terlambat, 
      menit_wajib_ganti, target_jam_pulang, catat_masuk, catat_pulang, 
      pengajuan_id, catatan_penolakan, foto_masuk_url, foto_pulang_url
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    p.uid, p.nip, p.nama_pegawai, p.tanggal, p.jam_masuk, p.jam_pulang, 
    p.status, p.jadwal_kerja, p.tipe_shift, p.menit_terlambat, 
    p.menit_wajib_ganti, p.target_jam_pulang, p.catat_masuk, p.catat_pulang, 
    p.pengajuan_id, p.catatan_penolakan, p.foto_masuk_url, p.foto_pulang_url
  ));
});


        await env.portal_gh2026.batch(batch);
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT PEGAWAI (SINGLE) ---
      if (url.pathname === "/pegawai" && request.method === "GET") {
        const uid = url.searchParams.get("uid");
        if (!uid) return new Response(JSON.stringify({ error: "UID required" }), { status: 400, headers: corsHeaders });
        
        const data = await env.portal_gh2026.prepare("SELECT * FROM pegawai WHERE uid = ? OR nip = ? LIMIT 1").bind(uid, uid).first();
        return new Response(JSON.stringify(data || null), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT PEGAWAI (ALL) ---
      if (url.pathname === "/pegawai/all" && request.method === "GET") {
        const { results } = await env.portal_gh2026.prepare("SELECT * FROM pegawai ORDER BY nama ASC").all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT PRESENSI AKTIF ---
      // GANTI DENGAN INI (Sudah ditambah ORDER BY):
if (url.pathname === "/presensi-aktif" && request.method === "GET") {
  const uid = url.searchParams.get("uid");
  // Perubahan: Menambahkan ORDER BY tanggal DESC agar mengambil data terbaru
  const data = await env.portal_gh2026.prepare(
    "SELECT * FROM presensi WHERE uid = ? AND jam_pulang IS NULL ORDER BY tanggal DESC LIMIT 1"
  ).bind(uid).first();
  
  return new Response(JSON.stringify(data), { 
    headers: { ...corsHeaders, "Content-Type": "application/json" } 
  });
}

      // --- ENDPOINT RIWAYAT PRESENSI ---
      if (url.pathname === "/riwayat-presensi" && request.method === "GET") {
        const uid = url.searchParams.get("uid");
        const { results } = await env.portal_gh2026.prepare("SELECT * FROM presensi WHERE uid = ? ORDER BY jam_masuk DESC LIMIT 31").bind(uid).all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT CEK NOMOR SERTIFIKAT ---
      if (url.pathname === "/pelatihan/check-nomor" && request.method === "GET") {
        const nomor = url.searchParams.get("nomor");
        const data = await env.portal_gh2026.prepare("SELECT id FROM riwayat_pelatihan WHERE nomor_sertifikat = ? LIMIT 1").bind(nomor).first();
        return new Response(JSON.stringify({ exists: !!data }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

// --- ENDPOINT CEK KOMBINASI DUPLIKAT ---
if (url.pathname === "/pelatihan/check-kombinasi" && request.method === "POST") {
  const d = await request.json();
  const data = await env.portal_gh2026.prepare(
    "SELECT id FROM riwayat_pelatihan WHERE nip = ? AND judul_pelatihan = ? AND tanggal_kegiatan = ? LIMIT 1"
  ).bind(d.nip, d.judul, d.tahun).first();
  
  return new Response(JSON.stringify({ exists: !!data }), { 
    headers: { ...corsHeaders, "Content-Type": "application/json" } 
  });
}



      // --- ENDPOINT RECALCULATE JPL & SERTIFIKAT ---
      if (url.pathname === "/pegawai/recalculate" && request.method === "GET") {
        const uid = url.searchParams.get("uid");
        await env.portal_gh2026.prepare(`
          UPDATE pegawai SET 
            total_jpl = (SELECT COALESCE(SUM(jumlah_jpl), 0) FROM riwayat_pelatihan WHERE uid = ? AND status = 'approved'),
            total_sertifikat = (SELECT COUNT(*) FROM riwayat_pelatihan WHERE uid = ? AND status = 'approved')
          WHERE uid = ?
        `).bind(uid, uid, uid).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT RIWAYAT PELATIHAN ---
      if (url.pathname === "/pelatihan/riwayat" && request.method === "GET") {
        const uid = url.searchParams.get("uid");
        const nip = url.searchParams.get("nip");
        const sql = uid ? "SELECT * FROM riwayat_pelatihan WHERE uid = ?" : "SELECT * FROM riwayat_pelatihan WHERE nip = ?";
        const { results } = await env.portal_gh2026.prepare(sql).bind(uid || nip).all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }


// --- ENDPOINT REKAM MASUK ---
if (url.pathname === "/rekam-masuk" && request.method === "POST") {
  const d = await request.json();
  await env.portal_gh2026.prepare(`
    INSERT INTO presensi (uid, nip, nama_pegawai, tanggal, jam_masuk, status, jadwal_kerja, tipe_shift, catat_masuk, foto_masuk_url)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?, ?)
  `).bind(d.uid, d.nip, d.nama_pegawai, d.tanggal, d.status || 'Tepat Waktu', d.jadwal_kerja, d.tipe_shift, d.catat_masuk, d.foto_masuk_url).run();
  return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
}

// --- ENDPOINT REKAM PULANG ---
if (url.pathname === "/rekam-pulang" && request.method === "POST") {
  const d = await request.json();
  await env.portal_gh2026.prepare(`
    UPDATE presensi SET 
      jam_pulang = CURRENT_TIMESTAMP, 
      catat_pulang = ?, 
      foto_pulang_url = ?
    WHERE id = ?
  `).bind(d.catat_pulang, d.foto_pulang_url, d.id).run();
  return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
}




            // 1. ENDPOINT PENGAJUAN IZIN (UNTUK PEGAWAI SIMPAN IZIN BARU)
      if (url.pathname === "/pengajuan-izin" && request.method === "POST") {
        const d = await request.json();
        const idIzin = crypto.randomUUID();
        
        await env.portal_gh2026.batch([
          // AKSI 1: Masukkan ke tabel pengajuan_izin (Agar muncul di layar ADMIN)
          env.portal_gh2026.prepare(`
            INSERT INTO pengajuan_izin (id, uid, nama_pegawai, nip, jenis_izin, alasan, status, lampiran_url, tanggal_pengajuan)
            VALUES (?, ?, ?, ?, ?, ?, 'Pending', ?, CURRENT_TIMESTAMP)
          `).bind(idIzin, d.uid, d.nama_pegawai, d.nip, d.jenis_izin, d.alasan, d.lampiran_url),

          // AKSI 2: Masukkan ke tabel presensi (Agar muncul di RIWAYAT USER)
          // Kita simpan lampiran_url ke kolom foto_masuk_url agar Flutter bisa menampilkannya
          env.portal_gh2026.prepare(`
            INSERT INTO presensi (uid, nip, nama_pegawai, tanggal, status, pengajuan_id, foto_masuk_url)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          `).bind(d.uid, d.nip, d.nama_pegawai, d.tanggal, d.jenis_izin + ' (Pending)', idIzin, d.lampiran_url)
        ]);

        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // 2. ENDPOINT AMBIL DAFTAR PENGAJUAN IZIN (UNTUK ADMIN)
      if (url.pathname === "/pengajuan-izin/list" && request.method === "GET") {
        const { results } = await env.portal_gh2026.prepare(
          "SELECT * FROM pengajuan_izin ORDER BY tanggal_pengajuan DESC"
        ).all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // 3. ENDPOINT UPDATE STATUS PENGAJUAN IZIN (UNTUK ADMIN APPROVE / REJECT)
      if (url.pathname === "/pengajuan-izin/update-status" && request.method === "POST") {
        const d = await request.json(); // { pengajuan_id, status, catatan_penolakan, jenis_izin }
        
        await env.portal_gh2026.batch([
          // Update status di tabel pengajuan_izin
          env.portal_gh2026.prepare(`
            UPDATE pengajuan_izin 
            SET status = ?, catatan_penolakan = ?, approved_at = CURRENT_TIMESTAMP 
            WHERE id = ?
          `).bind(d.status, d.catatan_penolakan || null, d.pengajuan_id),

          // Update status presensi terkait
          env.portal_gh2026.prepare(`
            UPDATE presensi 
            SET status = ?, catatan_penolakan = ?
            WHERE pengajuan_id = ?
          `).bind(d.status === 'Disetujui' ? d.jenis_izin : 'Ditolak', d.catatan_penolakan || null, d.pengajuan_id)
        ]);

        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT CARI PEGAWAI ---
      if (url.pathname === "/pegawai/search" && request.method === "GET") {
        const query = url.searchParams.get("q") || "";
        const { results } = await env.portal_gh2026.prepare("SELECT * FROM pegawai WHERE nama LIKE ? OR nip LIKE ? LIMIT 5").bind(`%${query}%`, `%${query}%`).all();
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT UPDATE PEGAWAI ---
      if (url.pathname === "/pegawai/update" && request.method === "POST") {
        const d = await request.json();
        await env.portal_gh2026.prepare(`
          UPDATE pegawai SET 
            nama=?, role=?, permissions=?, jenis_kelamin=?, kelompok=?, golongan=?, 
            instalasi=?, ruangan=?, kontak=?, updated_at=CURRENT_TIMESTAMP
          WHERE uid = ?
        `).bind(
          d.nama, d.role, 
          d.permissions || '', 
          d.jenis_kelamin, d.kelompok, d.golongan, 
          d.instalasi, d.ruangan, d.kontak, d.uid
        ).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT DELETE PEGAWAI ---
      if (url.pathname === "/pegawai/delete" && request.method === "GET") {
        const uid = url.searchParams.get("uid");
        await env.portal_gh2026.prepare("DELETE FROM pegawai WHERE uid = ?").bind(uid).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT TAMBAH PEGAWAI ---
      if (url.pathname === "/pegawai/add" && request.method === "POST") {
        const p = await request.json();
        await env.portal_gh2026.prepare(`
          INSERT INTO pegawai (uid, nip, nama, email, role, permissions, golongan, instalasi, jenis_kelamin, kelompok, ruangan, status_kepegawaian)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          p.uid, p.nip, p.nama, p.email, p.role || 'pegawai', 
          p.permissions || '', 
          p.golongan, p.instalasi, p.jenis_kelamin, p.kelompok, p.ruangan, p.status_kepegawaian
        ).run();
        return new Response(JSON.stringify({ success: true }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      // --- ENDPOINT CEK NIP ---
      if (url.pathname === "/pegawai/check-nip" && request.method === "GET") {
        const nip = url.searchParams.get("nip");
        const data = await env.portal_gh2026.prepare("SELECT uid FROM pegawai WHERE nip = ? LIMIT 1").bind(nip).first();
        return new Response(JSON.stringify({ exists: !!data }), { 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        });
      }

      return new Response("API Portal GH 2026 Ready", { headers: corsHeaders });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      });
    }
  },
};