// Pembatas percobaan (client-side). Lapisan tambahan; batas server tetap diatur di Supabase.
const P = 'rl:'
const kosong = () => ({ n: 0, t: 0, sampai: 0 })
const baca = (k) => { try { return JSON.parse(localStorage.getItem(P + k)) || kosong() } catch { return kosong() } }
const tulis = (k, v) => { try { localStorage.setItem(P + k, JSON.stringify(v)) } catch { /* abaikan */ } }

export function sisaBlokir(k) {
  const d = baca(k)
  return d.sampai > Date.now() ? Math.ceil((d.sampai - Date.now()) / 1000) : 0
}
// 5 gagal berturut-turut → kunci 30 dtk, lalu berlipat ganda (maks 15 menit)
export function gagalLimiter(k, { maks = 5, dasar = 30, batas = 900 } = {}) {
  const d = baca(k)
  if (Date.now() - d.t > batas * 1000) d.n = 0
  d.n += 1
  d.t = Date.now()
  if (d.n >= maks) d.sampai = Date.now() + Math.min(dasar * 2 ** (d.n - maks), batas) * 1000
  tulis(k, d)
}
export function resetLimiter(k) { try { localStorage.removeItem(P + k) } catch { /* abaikan */ } }
