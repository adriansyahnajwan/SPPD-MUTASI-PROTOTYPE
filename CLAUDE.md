# Prototipe Digitalisasi SPPD Mutasi (JM-Click)

## Tujuan
Prototipe konsep (web, tampilan laptop) untuk digitalisasi SPPD Mutasi dan Tiket Pulang Pergi di JM-Click (Jasa Marga). Dipakai untuk demo konsep ke atasan dan tim IT, bukan aplikasi produksi. Di-hosting di GitHub Pages: https://adriansyahnajwan.github.io/SPPD-MUTASI-PROTOTYPE/ (nama file wajib `index.html`).

## Aktor (lane flowchart)
1. Karyawan: pemohon SPPD Mutasi & Tiket PP (SUDAH)
2. System: notifikasi, validasi, baca KK, nomor otomatis, ubah status
3. HCS: HCIS (SUDAH, halaman terpisah) dan Office Administration/OAD (BELUM; approval masih disimulasikan)
4. Accounting & Tax (ATA): BELUM (akun sudah ada, halaman belum)

## Login & role
Satu halaman login, pilih role Karyawan atau HCIS. Pengguna cukup mengisi NPP (5 digit angka) + password; tidak ada email di tampilan. Semua akun demo memakai password demo yang terisi otomatis di halaman login. Role dari tabel `akun`: karyawan → halaman karyawan; hcis / dept_head_hcis / group_head → halaman HCIS; oad & ata belum punya halaman.
- Karyawan: Budi Santoso, NPP 10234
- HCIS: Dewi Lestari, NPP 20117
Tombol "Keluar" ada di kedua topbar.

## Halaman karyawan
Beranda → sidebar "Travel Management" (bisa dilipat) → SPPD Mutasi, Tiket PP, Benefit, Panduan, Referensi (SK Mutasi & Keputusan Direksi), Master Data (menyusul).
- SPPD Mutasi: tabel riwayat (Tanggal Efektif, Jabatan/Unit Sebelum, Jabatan/Unit Setelah, Status, Action) + filter teks/status/tahun.
- Form 4 langkah: Data Mutasi (dari SK, read-only, jarak jalur darat) → Dokumen → Keluarga (Ya: ambil dari KK; Tidak: tetap submit, lalu berhak Tiket PP) → Review → nomor SPPD-MTS-YYYY-NNNNN.
- Langkah Dokumen: SK Mutasi (sk_mutasi.file_sk) dan Kartu Keluarga (karyawan.file_kk) terlampir otomatis sebagai kartu "Dari sistem" (tombol Lihat, tanpa ganti/hapus) dan tidak masuk tabel dokumen. Karyawan hanya wajib upload foto rekening payroll; dokumen sekolah wajib jika mengajukan bantuan sekolah. Di review & cek kelengkapan HCIS, SK/KK diberi keterangan "diambil dari Data Karyawan".
- Status karyawan: Draft → Diajukan → Verifikasi HCS → Proses Accounting & Tax → Selesai.

## Tiket Pulang Pergi (TPP)
- Hanya untuk SPPD yang sudah diajukan dan TIDAK membawa keluarga. Tidak ada approval GM/atasan unit kerja: langsung masuk antrean HCIS.
- Istilah (dokumen resmi): **Pulang** = kantor baru → domisili (berangkat ke keluarga); **Pergi** = domisili → kantor baru (kembali bertugas). Urutan di form/review/detail selalu Pulang lalu Pergi; tgl_pergi ≥ tgl_pulang.
- Kuota 1x per triwulan (TW I–IV tahun berjalan), dijaga juga di database (unique index per SPPD + tahun + triwulan, kecuali Ditolak). TPP pertama maks. 7 hari setelah SPPD diajukan (pengingat H-2); lewat batas = hak TW itu hangus, TW berikutnya boleh mengajukan. Notifikasi saat TW baru dimulai.
- Form: jenis (dipesankan kantor / reimburse), alat transportasi (Pesawat / Kereta / Bus; Kapal belum diatur), kelas otomatis (Pesawat = Ekonomi, Kereta/Bus = Eksekutif; tidak bisa diubah), lokasi unit kerja (kantor baru), domisili (kampung halaman, dikonfirmasi), jarak tempuh (tabel jarak_domisili), TW pengajuan (otomatis), tanggal pulang & pergi.
- Dipesankan kantor: + jam keberangkatan pulang & pergi; tidak upload apa pun. Reimburse: nominal + e-ticket + bukti transaksi untuk pulang dan pergi (4 file).
- SK, KK, dan rekening payroll (dari pengajuan SPPD) terlampir otomatis sebagai kartu "Dari sistem".
- Status karyawan TPP: Diajukan / Diproses / Selesai / Ditolak (Diproses sejak HCIS mulai cek; Selesai/Ditolak menunggu halaman ATA). Nomor TPP-YYYY-NNNNN.
- Dipesankan kantor: setelah HCIS menerbitkan e-ticket, karyawan dapat notifikasi "E-ticket sudah terbit" dan bisa mengunduh e-ticket pulang/pergi (PDF contoh) di riwayat Tiket PP.

## Halaman HCIS (9 tahap)
Diterima → Cek kelengkapan → Susun RAB → Approval Dept Head HCIS → Buat PR → Approval OAD & Group Head → Buat PO & GR → Serahkan ke ATA → Diserahkan ke ATA.
- SPPD Mutasi dan Tiket PP ada di antrean yang sama (kolom Jenis: "SPPD Mutasi" / "Tiket PP") dan memakai 9 tahap yang sama.
- Tiket PP di HCIS:
  - Cek kelengkapan: Form permohonan TPP, Copy form SPPD, SK, KK, Rekening payroll, Tiket transportasi PP, Tagihan travel agent (hanya dipesankan kantor). Dipesankan kantor: HCIS mengisi detail tiket per perjalanan (operator, rute, tanggal, jam, biaya), unggah e-ticket pulang/pergi + tagihan travel agent, lalu "Terbitkan e-ticket" (baru bisa lanjut setelah itu).
  - RAB TPP (tabel rab_tpp, nomor RAB-TPP-YYYY-NNNN): judul "RENCANA ANGGARAN BIAYA (RAB) PENGGANTIAN TIKET TRANSPORTASI UNTUK FASILITAS PULANG DAN PERGI KARYAWAN PENUGASAN", 2 baris Pulang/Pergi (angkutan + kelas, tujuan, hari/tgl, biaya), Total, Terbilang, Ket "TWx tahun", tanpa pajak. Biaya: reimburse = nominal karyawan; dipesankan kantor = biaya dari detail tiket.
  - Serahkan ke ATA: dulu "Permohonan Penggantian Biaya ≤ Rp 50.000.000" (PB, nomor EB3.HM.02.N; Kepada HCS Group Head, Dari HCIS Dept Head), baru Nota Dinas ke ATA. Rantai dokumen: PR → PO → GR → PB → ND.
  - PR/PO/GR/ND memakai format SPPD dengan teks Tiket PP; pembayaran ND: dipesankan kantor = rekening travel agent, reimburse = rekening payroll.
- Antrean dengan KPI & filter; detail kasus dengan stepper dan ringkasan.
- RAB dihitung dari tabel hak: uang harian = orang × hari × tarif level; pengepakan dari tabel (asal Jabotabek) atau manual; sewa; penginapan; bantuan sekolah (manual); pajak 5%; diterima = total − pajak. Anak yang ditolak tidak dihitung.
- Setiap tahap punya 2 tombol: "Pratinjau …" dan tombol lanjut langsung. Pratinjau opsional.
- Format dokumen RAB, PR, PO (latar hijau), GR (latar pink), Nota Dinas meniru contoh dokumen user; nama pejabat, rekening, angka budget = placeholder.
- Saat HCIS mulai proses, status karyawan → Verifikasi HCS; saat serah ke ATA → Proses Accounting & Tax.

## Aturan bisnis (System)
- Jarak kantor lama–baru ≥ 100 km jalur darat (snapshot Google Maps + link cek rute).
- Anak usia ≥ 25 tahun per tanggal pengajuan ditolak otomatis.
- NIK 16 digit, tidak boleh dobel. File maks. 10 MB, PDF/JPG/PNG.
- Dokumen sekolah wajib jika mengajukan bantuan sekolah.

## Database (rencana, Supabase)
- Rancangan lengkap: `Rancangan_Database_SPPD_Mutasi_fix.xlsx` (22 tabel termasuk jarak_domisili & rab_tpp; sheet Ringkasan & Relasi).
- SQL: `supabase-tahap1.sql` → `tahap2` → `tahap3` → `tahap4` → `supabase-file-kk.sql` → `supabase-tpp1-karyawan.sql` → `supabase-tpp2-hcis.sql`, lalu `supabase-reset-demo.sql`. Database yang sudah berjalan sebelum kolom `karyawan.file_kk` ada: jalankan `supabase-file-kk.sql` (sekali, aman diulang) (dijalankan manual di SQL Editor). Setiap ada file tahap baru, jalankan ulang `supabase-reset-demo.sql`. SQL Editor membatalkan semua isi file kalau ada satu error; cek hasilnya lewat API setelah dijalankan.
- Bertahap:
  - Tahap 1 (SUDAH): kantor, karyawan, sk_mutasi, pengajuan_sppd, dokumen (form karyawan muncul di antrean HCIS lintas laptop)
  - Tahap 2 (SUDAH): jarak_kantor, keluarga, pengajuan_keluarga, notifikasi, riwayat_status
  - Tahap 3 (SUDAH): tarif_* (dibaca saat HCIS login), rab (no RAB-HCIS-YYYY-NNNN, upsert per pengajuan), checklist_kelengkapan, tiket_pp (+ dokumen.tpp_id)
  - Tahap 4 (SUDAH): akun, approval, dokumen_pengadaan (PR/PO/GR/ND, rantai referensi_id), login Supabase Auth + Row Level Security per role.
    Supabase Auth wajib punya email, jadi kode memetakan NPP → ID internal `<npp>@jmclick.test` (tidak pernah tampil ke pengguna). Aturan akses:
    - tanpa login: tidak bisa baca/tulis tabel apa pun (kecuali fungsi `reset_demo()`)
    - karyawan: hanya data miliknya; tidak bisa melihat RAB, cek kelengkapan, approval, dokumen pengadaan
    - HCS (hcis, dept_head_hcis, oad, group_head): baca & proses semua; ATA: baca semua
    - nomor SPPD-MTS & TPP dibuat fungsi database `next_no_pengajuan()` / `next_no_tpp()`; RAB/PR/PO/GR/ND dari nomor terbesar + 1
- index.html memanggil REST API Supabase lewat `fetch` (fungsi `sb()`, kirim token login; token kedaluwarsa diperbarui otomatis), tanpa library. Sesi login hanya di memori (muat ulang = login lagi). Data Supabase dipetakan ke `S.subs` / `S.notifs` / `S.hc` supaya tampilan tidak berubah.
- Masih di localStorage (key `sppd-mutasi-proto-v5`): draft form, konfirmasi kampung halaman TPP, log aktivitas, cache kasus HCIS (diisi ulang dari database). Tampilan & alur JANGAN berubah.
- Kondisi awal demo: Budi (10234) BELUM mengajukan SPPD untuk SK-MUT/0457 (tombol "Isi Form", notifikasi "SK Mutasi terbit" belum dibaca); Rina (10871) = pengajuan baru yang diproses HCIS dari awal (Diajukan / Diterima, belum ada RAB); Agus (11302) = contoh kasus yang sudah diserahkan ke ATA.
- Tombol "Reset data demo" (halaman login) memanggil fungsi database `reset_demo()` (`supabase-reset-demo.sql`): hapus semua transaksi (termasuk tabel Tahap 3–4 kalau sudah ada), isi ulang contoh data, lalu hapus localStorage di browser itu. Data master tidak disentuh.
- Contoh data transaksi ada di 3 tempat dan harus sama: Excel, `supabase-tahap1/2/3/4.sql`, dan `reset_demo()`.
- Hanya pakai publishable/anon key di index.html. JANGAN pernah taruh secret/service_role key di kode atau repo.

## Aturan kerja
- Satu file index.html, vanilla HTML/CSS/JS. pdf.js 3.11.174 dari cdnjs (baca file sebagai ArrayBuffer).
- Event lewat atribut data-act (delegasi). Input: data-f (form), data-t (TPP), data-hc (HCIS), data-doc (upload).
- Gaya Figma JM-CLICK: font Inter, biru #08578F, navy #002A5C, tombol back #77A4C7.
- Semua data dummy. Jangan pakai data karyawan asli.
- Label UI Bahasa Indonesia. User suka penjelasan singkat dan praktis.
- Setelah mengubah kode: tes alur karyawan → HCIS sampai serah ATA, pastikan tidak ada error di console.
