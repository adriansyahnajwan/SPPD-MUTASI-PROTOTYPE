# Prototipe Digitalisasi SPPD Mutasi (JM-Click)

## Tujuan
Prototipe konsep (web, tampilan laptop) untuk digitalisasi SPPD Mutasi dan Tiket Pulang Pergi di JM-Click (Jasa Marga). Dipakai untuk demo konsep ke atasan dan tim IT, bukan aplikasi produksi. Di-hosting di GitHub Pages: https://adriansyahnajwan.github.io/SPPD-MUTASI-PROTOTYPE/ (nama file wajib `index.html`).

## Aktor (lane flowchart)
1. Karyawan: pemohon SPPD Mutasi & Tiket PP (SUDAH)
2. System: notifikasi, validasi, baca KK, nomor otomatis, ubah status
3. HCS: HCIS (SUDAH, halaman terpisah) dan Office Administration/OAD (BELUM; approval masih disimulasikan)
4. Accounting & Tax (ATA): BELUM

## Login & role
Satu halaman login, pilih role Karyawan atau HCIS. NPP 5 digit angka, password bebas (simulasi).
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
- SQL: `supabase-tahap1.sql`, `supabase-tahap2.sql`, `supabase-tahap3.sql`, lalu `supabase-reset-demo.sql` (dijalankan manual di SQL Editor; termasuk GRANT untuk anon). Setiap ada file tahap baru, jalankan ulang `supabase-reset-demo.sql`.
- Bertahap:
  - Tahap 1 (SUDAH): kantor, karyawan, sk_mutasi, pengajuan_sppd, dokumen (form karyawan muncul di antrean HCIS lintas laptop)
  - Tahap 2 (SUDAH): jarak_kantor, keluarga, pengajuan_keluarga, notifikasi, riwayat_status
  - Tahap 3 (SUDAH): tarif_* (dibaca saat HCIS login), rab (no RAB-HCIS-YYYY-NNNN, upsert per pengajuan), checklist_kelengkapan, tiket_pp (+ dokumen.tpp_id)
  - Tahap 4: approval, dokumen_pengadaan, login beneran (Supabase Auth, NPP → email dummy `npp@jmclick.test`) + Row Level Security per role
- index.html memanggil REST API Supabase lewat `fetch` (fungsi `sb()`), tanpa library. Data Supabase dipetakan ke `S.subs` / `S.notifs` supaya tampilan tidak berubah.
- Masih di localStorage (key `sppd-mutasi-proto-v5`): PR, PO, GR, Nota Dinas, tanggal approval (Tahap 4), draft form, konfirmasi kampung halaman TPP. Ganti bertahap jadi baca/tulis Supabase; tampilan & alur JANGAN berubah.
- Kondisi awal demo: Budi (10234) BELUM mengajukan SPPD untuk SK-MUT/0457 (tombol "Isi Form", notifikasi "SK Mutasi terbit" belum dibaca); Rina & Agus = contoh antrean HCIS.
- Tombol "Reset data demo" (halaman login) memanggil fungsi database `reset_demo()` (`supabase-reset-demo.sql`): hapus semua transaksi (termasuk tabel Tahap 3–4 kalau sudah ada), isi ulang contoh data, lalu hapus localStorage di browser itu. Data master tidak disentuh.
- Contoh data transaksi ada di 3 tempat dan harus sama: Excel, `supabase-tahap1/2/3.sql`, dan `reset_demo()`. Kalau Tahap 4 menambah contoh data, tambahkan juga ke `reset_demo()`.
- Hanya pakai publishable/anon key di index.html. JANGAN pernah taruh secret/service_role key di kode atau repo.

## Aturan kerja
- Satu file index.html, vanilla HTML/CSS/JS. pdf.js 3.11.174 dari cdnjs (baca file sebagai ArrayBuffer).
- Event lewat atribut data-act (delegasi). Input: data-f (form), data-t (TPP), data-hc (HCIS), data-doc (upload).
- Gaya Figma JM-CLICK: font Inter, biru #08578F, navy #002A5C, tombol back #77A4C7.
- Semua data dummy. Jangan pakai data karyawan asli.
- Label UI Bahasa Indonesia. User suka penjelasan singkat dan praktis.
- Setelah mengubah kode: tes alur karyawan → HCIS sampai serah ATA, pastikan tidak ada error di console.
