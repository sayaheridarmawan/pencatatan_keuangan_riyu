import { reactive } from 'vue'
import { supabase } from './supabase'

export const db = reactive({ akun: [], kategori: [], anggota: [], transaksi: [], target: [], transfer: [], loading: false })
export const ui = reactive({ toasts: [] })

export function notify(text, type = 'ok') {
  const id = Date.now() + Math.random()
  ui.toasts.push({ id, text, type })
  setTimeout(() => (ui.toasts = ui.toasts.filter((t) => t.id !== id)), 4200)
}

export function pesanError(e) {
  const raw = e?.message || String(e || '')
  const m = raw.toLowerCase()
  if (m.includes('failed to fetch') || m.includes('network') || m.includes('load failed')) return 'Koneksi internet bermasalah. Coba lagi.'
  if (m.includes('invalid login')) return 'Email atau kata sandi salah.'
  if (m.includes('already registered')) return 'Email sudah terdaftar. Silakan masuk.'
  if (m.includes('email not confirmed')) return 'Email belum dikonfirmasi.'
  if (m.includes('rate limit') || m.includes('too many')) return 'Terlalu sering mencoba. Tunggu sebentar lalu ulangi.'
  if (m.includes('foreign key')) return 'Data ini masih dipakai oleh transaksi, jadi belum bisa dihapus.'
  if (m.includes('jwt') || m.includes('not authenticated')) return 'Sesi berakhir. Silakan masuk lagi.'
  if ((m.includes('relation') && m.includes('does not exist')) || m.includes('schema cache')) return 'Tabel belum dibuat. Jalankan file SQL (schema / migrasi) di Supabase.'
  return raw || 'Terjadi kesalahan. Coba lagi.'
}

// Jalankan operasi Supabase; tampilkan toast sukses/gagal. Mengembalikan true jika berhasil.
export async function safe(fn, okMsg) {
  try {
    const r = await fn()
    if (r?.error) throw r.error
    if (okMsg) notify(okMsg)
    return true
  } catch (e) {
    notify(pesanError(e), 'err')
    return false
  }
}

export async function loadAll() {
  db.loading = true
  try {
    const res = await Promise.all([
      supabase.from('akun').select('*').order('nama'),
      supabase.from('kategori').select('*').order('nama'),
      supabase.from('anggota').select('*').order('nama'),
      supabase.from('transaksi').select('*').order('tanggal', { ascending: false }).order('created_at', { ascending: false }).limit(5000),
      supabase.from('target').select('*').order('created_at'),
      supabase.from('transfer').select('*').order('tanggal', { ascending: false }).order('created_at', { ascending: false }).limit(2000),
    ])
    const bad = res.slice(0, 4).find((r) => r.error) // target/transfer boleh kosong sebelum migrasi
    if (bad) throw bad.error
    ;[db.akun, db.kategori, db.anggota, db.transaksi, db.target, db.transfer] = res.map((r) => r.data || [])
  } catch (e) {
    notify(pesanError(e), 'err')
  }
  db.loading = false
}

export const rupiah = (n) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n || 0)
export const terkumpul = (id) => db.transfer.filter((x) => x.target_id === id).reduce((s, x) => s + Number(x.jumlah), 0)
export const nama = (list, id) => list.find((x) => x.id === id)?.nama ?? '-'
export const today = () => new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 10)
export const tglIndo = (s) =>
  new Date(s + 'T00:00:00').toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
