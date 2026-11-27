-- ============================================================
-- SPPD Mutasi JM-Click · Tambah kolom karyawan.file_kk
-- Untuk database yang SUDAH berjalan (Tahap 1-4 sudah dijalankan).
-- Instalasi baru tidak perlu file ini: kolomnya sudah ada di supabase-tahap1.sql.
--
-- Kartu Keluarga tidak lagi diunggah karyawan di form SPPD Mutasi; file KK diambil
-- otomatis dari data karyawan (kolom ini), sama seperti SK dari sk_mutasi.file_sk.
-- Aman dijalankan berulang kali. Data master: tidak disentuh oleh reset_demo().
-- Cara pakai: Supabase > SQL Editor > New query > paste semua > Run
-- ============================================================

alter table karyawan add column if not exists file_kk text;   -- path file Kartu Keluarga di storage

update karyawan set file_kk = 'kk/KK-' || npp || '.pdf' where file_kk is null;   -- path dummy

notify pgrst, 'reload schema';
