<script setup>
import { ref, computed } from 'vue'
import Mascot from './Mascot.vue'
import TargetDetail from './TargetDetail.vue'
import { db, rupiah, nama, tglIndo, today, terkumpul } from '../store'

const bulan = ref(today().slice(0, 7))
const detailId = ref(null)

// Tampilkan / sembunyikan nominal utama (pilihan diingat di perangkat ini)
const KUNCI = 'riyu_lihat_saldo'
const bacaLihat = () => { try { return localStorage.getItem(KUNCI) !== '0' } catch { return true } }
const lihat = ref(bacaLihat())
function ganti() {
  lihat.value = !lihat.value
  try { localStorage.setItem(KUNCI, lihat.value ? '1' : '0') } catch { /* abaikan */ }
}
const uang = (n) => (lihat.value ? rupiah(n) : rupiah(n).replace(/\d/g, '*')) // jumlah bintang = jumlah angka
const detail = computed(() => db.target.find((x) => x.id === detailId.value))
const sum = (rows, tipe) => rows.filter((t) => t.tipe === tipe).reduce((s, t) => s + Number(t.jumlah), 0)
const rows = computed(() => db.transaksi.filter((t) => t.tanggal.startsWith(bulan.value)))
const masuk = computed(() => sum(rows.value, 'pemasukan'))
const keluar = computed(() => sum(rows.value, 'pengeluaran'))

const jumlahTf = (key, id) => db.transfer.filter((x) => x[key] === id).reduce((s, x) => s + Number(x.jumlah), 0)
const saldoAkun = computed(() =>
  db.akun.map((a) => {
    const t = db.transaksi.filter((x) => x.akun_id === a.id)
    const saldo = Number(a.saldo_awal) + sum(t, 'pemasukan') - sum(t, 'pengeluaran') + jumlahTf('akun_tujuan_id', a.id) - jumlahTf('akun_asal_id', a.id)
    return { ...a, saldo }
  })
)
const sapa = computed(() => {
  if (!db.transaksi.length) return 'Halo, aku Riyu! Yuk catat transaksi pertamamu.'
  if (keluar.value > masuk.value && masuk.value > 0) return 'Hmm, pengeluaran bulan ini lebih besar dari pemasukan. Yuk dicek lagi!'
  if (masuk.value > keluar.value) return `Hebat! Bulan ini kamu menyisihkan ${uang(masuk.value - keluar.value)}.`
  return 'Terus semangat mencatat ya!'
})
const totalSaldo = computed(() => saldoAkun.value.reduce((s, a) => s + a.saldo, 0))

const perKategori = computed(() => {
  const m = {}
  rows.value.filter((t) => t.tipe === 'pengeluaran').forEach((t) => (m[t.kategori_id] = (m[t.kategori_id] || 0) + Number(t.jumlah)))
  const list = Object.entries(m).map(([id, v]) => ({ id, v })).sort((a, b) => b.v - a.v)
  const max = list[0]?.v || 1
  return list.map((x) => ({ ...x, pct: (x.v / max) * 100 }))
})
</script>

<template>
  <section class="hero">
    <div class="hero-main">
      <div class="hl-row"><span class="hl">Total saldo keluarga</span><button type="button" class="icon-btn" :aria-label="lihat ? 'Sembunyikan nominal' : 'Tampilkan nominal'" :title="lihat ? 'Sembunyikan nominal' : 'Tampilkan nominal'" :aria-pressed="!lihat" @click="ganti"><svg v-if="lihat" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></svg><svg v-else viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.9 17.9A10.9 10.9 0 0 1 12 19c-6.5 0-10-7-10-7a18.5 18.5 0 0 1 5.1-5.9M9.9 5.1A10.4 10.4 0 0 1 12 5c6.5 0 10 7 10 7a18.6 18.6 0 0 1-2.2 3.2M1 1l22 22M9.9 9.9a3 3 0 0 0 4.2 4.2" /></svg></button></div>
      <div class="big" :class="{ samar: !lihat }">{{ uang(totalSaldo) }}</div>
      <input type="month" v-model="bulan" aria-label="Bulan" />
    </div>
    <div class="riyu"><div class="bubble">{{ sapa }}</div><Mascot :size="84" /></div>
  </section>

  <div class="grid2">
    <div class="card"><span class="mute">Pemasukan bulan ini</span><div class="num in" :class="{ samar: !lihat }">{{ uang(masuk) }}</div></div>
    <div class="card"><span class="mute">Pengeluaran bulan ini</span><div class="num out" :class="{ samar: !lihat }">{{ uang(keluar) }}</div></div>
  </div>

  <div class="grid2">
    <div class="card">
      <h3>Saldo per akun</h3>
      <p v-if="!saldoAkun.length" class="mute">Belum ada akun. Tambahkan di Master data.</p>
      <div v-for="a in saldoAkun" :key="a.id" class="row"><span>{{ a.nama }}</span><b>{{ rupiah(a.saldo) }}</b></div>
    </div>
    <div class="card">
      <h3>Pengeluaran per kategori</h3>
      <p v-if="!perKategori.length" class="mute">Belum ada pengeluaran di bulan ini.</p>
      <div v-for="k in perKategori" :key="k.id" class="bar-item">
        <div class="row"><span>{{ nama(db.kategori, k.id) }}</span><b>{{ rupiah(k.v) }}</b></div>
        <div class="track"><i :style="{ width: k.pct + '%' }"></i></div>
      </div>
    </div>
  </div>

  <div class="card">
    <h3>Target tabungan</h3>
    <p v-if="!db.target.length" class="mute">Belum ada target. Buat di tab Tabungan.</p>
    <p v-else class="mute small">Ketuk target untuk melihat sumber dananya.</p>
    <div v-for="g in db.target" :key="g.id" class="bar-item klik" role="button" tabindex="0" @click="detailId = g.id" @keyup.enter="detailId = g.id">
      <div class="row"><span>{{ g.nama }}</span><b>{{ rupiah(terkumpul(g.id)) }} / {{ rupiah(g.target_jumlah) }}</b></div>
      <div class="track"><i class="goal" :style="{ width: Math.min(100, (terkumpul(g.id) / g.target_jumlah) * 100) + '%' }"></i></div>
    </div>
  </div>

  <div class="card">
    <h3>Transaksi terakhir</h3>
    <p v-if="!db.transaksi.length" class="mute">Belum ada transaksi. Mulai dari tab Transaksi.</p>
    <div v-for="t in db.transaksi.slice(0, 6)" :key="t.id" class="row">
      <span>{{ nama(db.kategori, t.kategori_id) }} <small class="mute">{{ tglIndo(t.tanggal) }}</small></span>
      <b :class="t.tipe === 'pemasukan' ? 'in' : 'out'">{{ t.tipe === 'pemasukan' ? '+' : '−' }}{{ rupiah(t.jumlah) }}</b>
    </div>
  </div>
  <TargetDetail v-if="detail" :target="detail" @tutup="detailId = null" />
</template>
