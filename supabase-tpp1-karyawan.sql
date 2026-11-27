-- ============================================================
-- SPPD Mutasi JM-Click · Tiket Pulang Pergi (TPP) tahap 1: sisi karyawan
-- Jalankan SETELAH supabase-tahap1..4.sql dan supabase-file-kk.sql,
-- lalu jalankan ulang supabase-reset-demo.sql (mengisi ulang contoh TPP).
-- Cara pakai: Supabase > SQL Editor > New query > paste semua > Run
--
-- Istilah (sesuai dokumen resmi):
--   Pulang = kantor baru -> domisili (berangkat ke keluarga)   -> tgl_pulang, jam_pulang, nominal_pulang
--   Pergi  = domisili -> kantor baru (kembali bertugas)         -> tgl_pergi,  jam_pergi,  nominal_pergi
--   Jadi tgl_pergi >= tgl_pulang (kebalikan dari aturan lama).
-- Kuota: 1x per triwulan (TW I-IV) per SPPD, kecuali yang Ditolak.
--
-- PERHATIAN: semua data TPP demo dihapus (dokumen TPP ikut terhapus). Data dummy.
-- ============================================================

-- ---------- 1. JARAK DOMISILI (master; jarak tempuh kantor baru -> domisili) ----------
create table if not exists jarak_domisili (
  kantor_kode text not null references kantor(kode),   -- kantor baru (tujuan SK)
  domisili    text not null,                           -- = karyawan.kampung_halaman
  jarak_km    numeric(7,1) not null check (jarak_km > 0),
  sumber      text not null,
  dicek_pada  timestamptz not null,
  primary key (kantor_kode, domisili)
);
delete from jarak_domisili where true;
insert into jarak_domisili (kantor_kode, domisili, jarak_km, sumber, dicek_pada) values
 ('smg','Kab. Klaten, Jawa Tengah',118.0,'Google Maps (snapshot)','2026-11-16 14:15+07'),
 ('sby','Kab. Gresik, Jawa Timur',  27.4,'Google Maps (snapshot)','2026-11-16 14:15+07'),
 ('jkt','Kota Malang, Jawa Timur', 846.0,'Google Maps (snapshot)','2026-11-16 14:15+07');

alter table jarak_domisili enable row level security;
drop policy if exists "baca jarak domisili" on jarak_domisili;
create policy "baca jarak domisili" on jarak_domisili for select to authenticated using (true);
revoke all on jarak_domisili from anon;
grant select on jarak_domisili to authenticated;

-- ---------- 2. TIKET_PP ----------
delete from tiket_pp where true;   -- data TPP demo (dokumen TPP ikut terhapus lewat cascade)

-- Hapus aturan lama tanggal/jam/nominal (nama otomatis tiket_pp_check, _check1, _check2)
do $$
declare r record;
begin
  for r in select conname from pg_constraint
           where conrelid = 'public.tiket_pp'::regclass and contype = 'c' and conname ~ '^tiket_pp_check[0-9]*$' loop
    execute format('alter table tiket_pp drop constraint %I', r.conname);
  end loop;
end $$;
alter table tiket_pp drop constraint if exists tiket_pp_tanggal_check;
alter table tiket_pp drop constraint if exists tiket_pp_jam_check;
alter table tiket_pp drop constraint if exists tiket_pp_nominal_check;

alter table tiket_pp add column if not exists alat_transportasi text;
alter table tiket_pp add column if not exists triwulan int;
alter table tiket_pp add column if not exists tahun    int;
alter table tiket_pp add column if not exists jarak_km numeric(7,1);
-- Kelas otomatis: udara (Pesawat) = Ekonomi; darat (Kereta, Bus) = Eksekutif
alter table tiket_pp drop column if exists kelas;
alter table tiket_pp add column kelas text generated always as
  (case alat_transportasi when 'Pesawat' then 'Ekonomi' when 'Kereta' then 'Eksekutif' when 'Bus' then 'Eksekutif' end) stored;

alter table tiket_pp alter column alat_transportasi set not null;
alter table tiket_pp alter column triwulan set not null;
alter table tiket_pp alter column tahun    set not null;
alter table tiket_pp drop constraint if exists tiket_pp_alat_transportasi_check;
alter table tiket_pp add  constraint tiket_pp_alat_transportasi_check check (alat_transportasi in ('Pesawat','Kereta','Bus'));
alter table tiket_pp drop constraint if exists tiket_pp_triwulan_check;
alter table tiket_pp add  constraint tiket_pp_triwulan_check check (triwulan between 1 and 4);
alter table tiket_pp drop constraint if exists tiket_pp_tahun_check;
alter table tiket_pp add  constraint tiket_pp_tahun_check check (tahun between 2000 and 2100);
alter table tiket_pp drop constraint if exists tiket_pp_jarak_km_check;
alter table tiket_pp add  constraint tiket_pp_jarak_km_check check (jarak_km is null or jarak_km > 0);

alter table tiket_pp add constraint tiket_pp_tanggal_check check (tgl_pergi >= tgl_pulang);   -- pergi (kembali) setelah pulang
alter table tiket_pp add constraint tiket_pp_jam_check     check (skema <> 'dipesankan_kantor' or (jam_pulang is not null and jam_pergi is not null));
alter table tiket_pp add constraint tiket_pp_nominal_check check (skema <> 'reimburse' or (nominal_pulang is not null and nominal_pergi is not null));

-- 1x per triwulan per SPPD (pengajuan yang Ditolak tidak dihitung)
drop index if exists tiket_pp_satu_per_tw;
create unique index tiket_pp_satu_per_tw on tiket_pp (pengajuan_id, tahun, triwulan) where status <> 'Ditolak';

-- ---------- 3. DOKUMEN: jenis untuk e-ticket & bukti transaksi per perjalanan ----------
alter table dokumen drop constraint if exists dokumen_jenis_check;
alter table dokumen add constraint dokumen_jenis_check check (jenis in
  ('sk','kk','rekening','sekolah_asal','sekolah_baru',
   'tiket_pulang','bukti_pulang','tiket_pergi','bukti_pergi',   -- e-ticket & bukti transaksi (reimburse: diunggah karyawan; dipesankan kantor: e-ticket diunggah HCIS)
   'tagihan_travel'));                                            -- tagihan travel agent (dipesankan kantor, diunggah HCIS)

notify pgrst, 'reload schema';
