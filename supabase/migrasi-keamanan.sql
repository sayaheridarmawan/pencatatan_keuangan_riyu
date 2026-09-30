-- Jalankan SEKALI di Supabase → SQL Editor (aman diulang).
-- 1) Batas panjang teks, nominal, dan tanggal (validasi di sisi database)
alter table akun      drop constraint if exists akun_batas;
alter table kategori  drop constraint if exists kategori_batas;
alter table anggota   drop constraint if exists anggota_batas;
alter table target    drop constraint if exists target_batas;
alter table transaksi drop constraint if exists transaksi_batas;
alter table transfer  drop constraint if exists transfer_batas;

alter table akun      add constraint akun_batas     check (char_length(nama) between 1 and 60 and saldo_awal between -100000000000 and 100000000000);
alter table kategori  add constraint kategori_batas check (char_length(nama) between 1 and 60);
alter table anggota   add constraint anggota_batas  check (char_length(nama) between 1 and 60);
alter table target    add constraint target_batas   check (char_length(nama) between 1 and 60 and target_jumlah <= 100000000000);
alter table transaksi add constraint transaksi_batas check (jumlah <= 100000000000 and char_length(coalesce(catatan, '')) <= 200 and tanggal between '2000-01-01' and '2100-12-31');
alter table transfer  add constraint transfer_batas  check (jumlah <= 100000000000 and char_length(coalesce(catatan, '')) <= 200 and tanggal between '2000-01-01' and '2100-12-31');

-- 2) Transfer / alokasi tidak boleh melebihi saldo akun sumber (dijaga di database)
create or replace function public.cek_saldo_transfer() returns trigger
language plpgsql security invoker as $$
declare saldo numeric;
begin
  select a.saldo_awal
       + coalesce((select sum(case when t.tipe = 'pemasukan' then t.jumlah else -t.jumlah end) from transaksi t where t.akun_id = a.id), 0)
       + coalesce((select sum(x.jumlah) from transfer x where x.akun_tujuan_id = a.id and x.id is distinct from new.id), 0)
       - coalesce((select sum(x.jumlah) from transfer x where x.akun_asal_id = a.id and x.id is distinct from new.id), 0)
    into saldo
  from akun a where a.id = new.akun_asal_id;
  if new.jumlah > coalesce(saldo, 0) then
    raise exception 'Saldo akun sumber tidak cukup';
  end if;
  return new;
end $$;

drop trigger if exists trg_cek_saldo_transfer on transfer;
create trigger trg_cek_saldo_transfer before insert or update on transfer
  for each row execute function public.cek_saldo_transfer();
