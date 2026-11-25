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
- Status karyawan: Draft → Diajukan → Verifikasi HCS → Proses Accounting & Tax → Selesai.

## Tiket Pulang Pergi (TPP)
- Hanya untuk SPPD yang sudah diajukan dan TIDAK membawa keluarga.
- TPP pertama maks. 7 hari setelah SPPD diajukan (pengingat H-2; lewat batas = hangus). Setelah itu 1x tiap 3 bulan, ada notifikasi.
- Rute hanya kantor BARU (tujuan SK) ↔ kampung halaman (dikonfirmasi, tidak bisa diubah).
- Skema: dipesankan kantor (tanggal & jam pergi/pulang) atau reimburse (tanggal, nominal, upload tiket & bukti transaksi).
- Nomor TPP-YYYY-NNNNN.

## Halaman HCIS (9 tahap)
Diterima → Cek kelengkapan → Susun RAB → Approval Dept Head HCIS → Buat PR → Approval OAD & Group Head → Buat PO & GR → Serahkan ke ATA → Diserahkan ke ATA.
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
- Rancangan lengkap: `Rancangan_Database_SPPD_Mutasi_fix.xlsx` (20 tabel; sheet Ringkasan & Relasi).
- SQL: `supabase-tahap1.sql` → `tahap2` → `tahap3` → `tahap4`, lalu `supabase-reset-demo.sql` (dijalankan manual di SQL Editor). Setiap ada file tahap baru, jalankan ulang `supabase-reset-demo.sql`. SQL Editor membatalkan semua isi file kalau ada satu error; cek hasilnya lewat API setelah dijalankan.
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
