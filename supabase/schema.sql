-- Jalankan di Supabase → SQL Editor
create table akun (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nama text not null,
  saldo_awal numeric(14,2) not null default 0,
  created_at timestamptz default now()
);
create table kategori (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nama text not null,
  tipe text not null check (tipe in ('pemasukan','pengeluaran')),
  created_at timestamptz default now()
);
create table anggota (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nama text not null,
  created_at timestamptz default now()
);
create table transaksi (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  tanggal date not null default current_date,
  tipe text not null check (tipe in ('pemasukan','pengeluaran')),
  jumlah numeric(14,2) not null check (jumlah > 0),
  akun_id uuid not null references akun on delete restrict,
  kategori_id uuid not null references kategori on delete restrict,
  anggota_id uuid references anggota on delete set null,
  catatan text,
  created_at timestamptz default now()
);
create index on transaksi (user_id, tanggal desc);

-- Keamanan: tiap pengguna hanya bisa akses datanya sendiri
do $$
declare t text;
begin
  foreach t in array array['akun','kategori','anggota','transaksi'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "milik sendiri" on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
