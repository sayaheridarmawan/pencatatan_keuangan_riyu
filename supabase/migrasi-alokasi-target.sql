-- Jalankan SEKALI di Supabase → SQL Editor.
-- Mengizinkan "Sisihkan ke target" pada akun yang sama (akun asal = akun tujuan).
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.transfer'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) like '%akun_asal_id%'
  loop
    execute format('alter table public.transfer drop constraint %I', c);
  end loop;
end $$;
