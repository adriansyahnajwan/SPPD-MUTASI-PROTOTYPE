-- ============================================================
-- SPPD Mutasi JM-Click · Fungsi reset_demo()
-- Dipanggil tombol "Reset data demo" di halaman login (POST /rest/v1/rpc/reset_demo).
-- Jalankan SETELAH supabase-tahap1.sql dan supabase-tahap2.sql.
-- Cara pakai: Supabase > SQL Editor > New query > paste semua > Run
--
-- Yang dilakukan (dalam satu transaksi):
--  1. Hapus SEMUA data transaksi: pengajuan_sppd, dokumen, pengajuan_keluarga,
--     notifikasi, riwayat_status, dan tabel Tahap 3-4 (tiket_pp, rab, approval,
--     dokumen_pengadaan, checklist_kelengkapan) kalau tabelnya sudah ada.
--  2. Isi ulang contoh data dari Rancangan_Database_SPPD_Mutasi_fix.xlsx:
--     Budi (10234) BELUM mengajukan SPPD; Rina & Agus = contoh antrean HCIS.
--  Data master (karyawan, sk_mutasi, kantor, jarak_kantor, keluarga, tarif_*) tidak disentuh.
--  Nomor SPPD-MTS kembali ke awal karena dihitung dari nomor terbesar yang ada (00141 → berikutnya 00142).
--  Id internal (identity) sengaja tidak di-restart supaya data lama di browser lain tidak
--  tertukar dengan pengajuan baru yang kebetulan mendapat id sama.
--
-- KHUSUS PROTOTIPE (data dummy). Hapus/ganti fungsi ini di Tahap 4 sebelum ada data asli.
-- Kalau Tahap 3-4 menambah contoh data (mis. tiket_pp TPP-2026-00018), tambahkan juga di bagian 2.
-- ============================================================

create or replace function reset_demo()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  t text;
begin
  -- 1. Kosongkan transaksi (urutan: anak dulu, baru induk)
  foreach t in array array['dokumen_pengadaan','approval','rab','checklist_kelengkapan',
                           'riwayat_status','notifikasi','pengajuan_keluarga','dokumen',
                           'tiket_pp','pengajuan_sppd'] loop
    if to_regclass('public.'||t) is not null then
      execute format('delete from %I where true', t);
    end if;
  end loop;

  -- 2. Contoh data awal (sama dengan Excel)
  insert into pengajuan_sppd (id, no_pengajuan, npp, no_sk, jarak_km, bawa_keluarga, bantuan_sekolah, status, tahap_hcis, diajukan_pada, catatan) values
   (2,'SPPD-MTS-2026-00139','10871','SK-MUT/0462/DIR/XI/2026',140,true, true, 'Verifikasi HCS',         'Susun RAB',        '2026-11-18',null),
   (3,'SPPD-MTS-2026-00141','11302','SK-MUT/0469/DIR/XI/2026',770,false,false,'Proses Accounting & Tax','Diserahkan ke ATA','2026-11-19',null);

  insert into dokumen (id, pengajuan_id, tpp_id, jenis, nama_file, tipe_file, ukuran_kb, path_storage, diunggah_pada) values
   (5,3,   null,'sk',             'SK_Mutasi_Agus.pdf',  'PDF',790,'sppd/00141/sk.pdf',  '2026-11-19 10:02+07'),
   (6,null,1,   'tiket',          'Tiket_Agus.pdf',      'PDF',300,'tpp/00018/tiket.pdf','2026-11-22 15:10+07'),
   (7,null,1,   'bukti_transaksi','Bukti_Bayar_Agus.png','PNG',210,'tpp/00018/trx.png',  '2026-11-22 15:11+07');

  insert into pengajuan_keluarga (id, pengajuan_id, keluarga_id, usia_saat_pengajuan, status, alasan_tolak) values
   (5,2,5,38,'Diterima',null),
   (6,2,6, 9,'Diterima',null);

  insert into notifikasi (id, penerima_npp, judul, pesan, referensi, dibaca, dibuat_pada) values
   (1,'10234','SK Mutasi terbit','Silakan isi form SPPD Mutasi.','SK-MUT/0457/DIR/XI/2026',false,'2026-11-12 08:00+07'),
   (3,'11302','Pengingat Tiket PP','Batas pengajuan Tiket PP pertama tinggal 2 hari.','SPPD-MTS-2026-00141',true,'2026-11-24 07:00+07');

  insert into riwayat_status (id, objek, objek_id, status_lama, status_baru, oleh_npp, waktu, catatan) values
   (1,'pengajuan_sppd',3,null,'Diajukan','11302','2026-11-19 10:05+07',null),
   (2,'pengajuan_sppd',3,'Diajukan','Verifikasi HCS','20117','2026-11-19 14:00+07','Mulai diproses HCIS'),
   (3,'pengajuan_sppd',3,'Verifikasi HCS','Proses Accounting & Tax','20117','2026-11-21 15:30+07','Diserahkan ke ATA');
end;
$$;

revoke all on function reset_demo() from public;
grant execute on function reset_demo() to anon, authenticated;

-- Terapkan kondisi awal sekarang juga
select reset_demo();
