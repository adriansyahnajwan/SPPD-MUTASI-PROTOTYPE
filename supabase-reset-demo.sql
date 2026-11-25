-- ============================================================
-- SPPD Mutasi JM-Click · Fungsi reset_demo()
-- Dipanggil tombol "Reset data demo" di halaman login (POST /rest/v1/rpc/reset_demo).
-- Jalankan SETELAH supabase-tahap1.sql, supabase-tahap2.sql, dan (kalau ada) supabase-tahap3.sql.
-- Setiap kali file tahap baru dijalankan, jalankan ulang file ini.
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
-- Contoh data Tahap 4 (approval, dokumen_pengadaan) ikut diisi ulang. Akun & user login tidak disentuh.
-- Fungsi ini sengaja boleh dipanggil TANPA login (tombol ada di halaman login). Siapa pun yang
-- membuka situs bisa mereset data demo; hapus grant ke anon kalau tidak diinginkan.
-- Nomor TPP dan RAB juga kembali ke awal (dihitung dari nomor terbesar: TPP-2026-00018, RAB-HCIS-2026-0492).
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

  -- Tahap 3 (dilewati kalau tabelnya belum dibuat)
  if to_regclass('public.tiket_pp') is not null then
    insert into tiket_pp (id, no_tpp, pengajuan_id, skema, asal, tujuan, tgl_pergi, jam_pergi, tgl_pulang, jam_pulang, nominal_pergi, nominal_pulang, status, diajukan_pada) values
     (1,'TPP-2026-00018',3,'reimburse','sby','Kab. Gresik, Jawa Timur','2026-11-20',null,'2026-11-22',null,450000,450000,'Diajukan','2026-11-22');
  end if;
  if to_regclass('public.rab') is not null then
    insert into rab (id, no_rab, pengajuan_id, level_kelompok, jumlah_orang, jumlah_hari, tarif_harian, pengepakan, pengepakan_manual, sewa, penginapan, bantuan_sekolah, catatan, dibuat_oleh, dibuat_pada) values
     (1,'RAB-HCIS-2026-0491',3,'6/7',1,5,575000,2000000,false,10000000,3200000,0,null,'20117','2026-11-20 10:15+07'),
     (2,'RAB-HCIS-2026-0492',2,'4',3,5,650000,3500000,true,15000000,6400000,2500000,'Pengepakan diisi manual (asal Jawa Barat)','20117','2026-11-24 11:00+07');
  end if;
  if to_regclass('public.checklist_kelengkapan') is not null then
    insert into checklist_kelengkapan (id, pengajuan_id, item, wajib, hasil, catatan, dicek_oleh, dicek_pada) values
     (1,3,'form',true,'Lengkap',null,'20117','2026-11-20 09:00+07'),
     (2,3,'sk',true,'Lengkap',null,'20117','2026-11-20 09:00+07'),
     (3,3,'kk',true,'Lengkap',null,'20117','2026-11-20 09:00+07'),
     (4,3,'rekening',true,'Lengkap',null,'20117','2026-11-20 09:00+07'),
     (5,3,'sekolah_asal',false,'Tidak berlaku','Tidak mengajukan bantuan sekolah','20117','2026-11-20 09:00+07');
  end if;

  -- Tahap 4 (dilewati kalau tabelnya belum dibuat)
  if to_regclass('public.approval') is not null then
    insert into approval (id, objek, objek_no, urutan, approver_npp, peran, keputusan, catatan, waktu) values
     (1,'RAB','RAB-HCIS-2026-0491',1,'20101','dept_head_hcis','Disetujui',null,'2026-11-20 14:00+07'),
     (2,'PR', '1000310121',        1,'30045','oad',           'Disetujui',null,'2026-11-21 09:30+07'),
     (3,'PR', '1000310121',        2,'20001','group_head',    'Disetujui',null,'2026-11-21 13:45+07'),
     (4,'RAB','RAB-HCIS-2026-0492',1,'20101','dept_head_hcis','Menunggu', null,null);
  end if;
  if to_regclass('public.dokumen_pengadaan') is not null and to_regclass('public.rab') is not null then
    insert into dokumen_pengadaan (id, jenis, nomor, rab_id, referensi_id, tanggal, nilai, status, dibuat_oleh, path_storage) values
     (1,'PR','1000310121',  1,null,'2026-11-20',18075000,'Final','20117','pengadaan/pr-1000310121.pdf'),
     (2,'PO','4000301041',  1,1,   '2026-11-21',18075000,'Final','20117','pengadaan/po-4000301041.pdf'),
     (3,'GR','5000392721',  1,2,   '2026-11-21',18075000,'Final','20117','pengadaan/gr-5000392721.pdf'),
     (4,'ND','EB.KU06.3451',1,3,   '2026-11-21',18075000,'Final','20117','pengadaan/nd-3451.pdf');
  end if;

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
