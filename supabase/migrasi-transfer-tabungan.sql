-- Jalankan SEKALI di Supabase → SQL Editor (setelah schema.sql)
create table target (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  nama text not null,
  target_jumlah numeric(14,2) not null check (target_jumlah > 0),
  tenggat date,
  created_at timestamptz default now()
);
create table transfer (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  tanggal date not null default current_date,
  jumlah numeric(14,2) not null check (jumlah > 0),
  akun_asal_id uuid not null references akun on delete restrict,
  akun_tujuan_id uuid not null references akun on delete restrict,
  target_id uuid references target on delete set null,
  catatan text,
  created_at timestamptz default now(),
  check (akun_asal_id <> akun_tujuan_id)
);
create index on transfer (user_id, tanggal desc);

do $$
declare t text;
begin
  foreach t in array array['target','transfer'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "milik sendiri" on %I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
  end loop;
end $$;
