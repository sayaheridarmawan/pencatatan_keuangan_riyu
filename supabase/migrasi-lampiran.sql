-- Jalankan SEKALI di Supabase → SQL Editor (aman diulang).
-- Lampiran opsional (foto struk / bukti transfer) untuk transaksi dan transfer.
alter table transaksi add column if not exists lampiran_path text;
alter table transfer  add column if not exists lampiran_path text;
alter table transaksi drop constraint if exists transaksi_lampiran_len;
alter table transfer  drop constraint if exists transfer_lampiran_len;
alter table transaksi add constraint transaksi_lampiran_len check (lampiran_path is null or char_length(lampiran_path) <= 200);
alter table transfer  add constraint transfer_lampiran_len  check (lampiran_path is null or char_length(lampiran_path) <= 200);

-- Bucket PRIVAT: maksimal 1 MB per file, hanya gambar atau PDF
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('lampiran', 'lampiran', false, 1048576, array['image/webp','image/jpeg','image/png','application/pdf'])
on conflict (id) do update
  set public = false, file_size_limit = 1048576, allowed_mime_types = excluded.allowed_mime_types;

-- Setiap pengguna hanya bisa mengakses folder miliknya sendiri (user_id/...)
drop policy if exists "lampiran baca sendiri"  on storage.objects;
drop policy if exists "lampiran unggah sendiri" on storage.objects;
drop policy if exists "lampiran hapus sendiri" on storage.objects;
create policy "lampiran baca sendiri"   on storage.objects for select to authenticated
  using (bucket_id = 'lampiran' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "lampiran unggah sendiri" on storage.objects for insert to authenticated
  with check (bucket_id = 'lampiran' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "lampiran hapus sendiri"  on storage.objects for delete to authenticated
  using (bucket_id = 'lampiran' and (storage.foldername(name))[1] = auth.uid()::text);
