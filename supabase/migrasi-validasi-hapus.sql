-- Jalankan SEKALI di Supabase → SQL Editor (aman diulang).
-- Anggota yang sudah dipakai transaksi tidak boleh dihapus (sebelumnya otomatis dilepas dari transaksi).
-- Akun dan kategori sudah ditolak oleh database sejak awal (on delete restrict).
alter table transaksi drop constraint if exists transaksi_anggota_id_fkey;
alter table transaksi
  add constraint transaksi_anggota_id_fkey
  foreign key (anggota_id) references anggota (id) on delete restrict;
