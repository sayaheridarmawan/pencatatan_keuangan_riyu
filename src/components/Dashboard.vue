<script setup>
import { ref, computed } from 'vue'
import Mascot from './Mascot.vue'
import { db, rupiah, nama, tglIndo, today } from '../store'

const bulan = ref(today().slice(0, 7))
const sum = (rows, tipe) => rows.filter((t) => t.tipe === tipe).reduce((s, t) => s + Number(t.jumlah), 0)
const rows = computed(() => db.transaksi.filter((t) => t.tanggal.startsWith(bulan.value)))
const masuk = computed(() => sum(rows.value, 'pemasukan'))
const keluar = computed(() => sum(rows.value, 'pengeluaran'))

const saldoAkun = computed(() =>
  db.akun.map((a) => {
    const t = db.transaksi.filter((x) => x.akun_id === a.id)
    return { ...a, saldo: Number(a.saldo_awal) + sum(t, 'pemasukan') - sum(t, 'pengeluaran') }
  })
)
const sapa = computed(() => {
  if (!db.transaksi.length) return 'Halo, aku Riyu! Yuk catat transaksi pertamamu.'
  if (keluar.value > masuk.value && masuk.value > 0) return 'Hmm, pengeluaran bulan ini lebih besar dari pemasukan. Yuk dicek lagi!'
  if (masuk.value > keluar.value) return `Hebat! Bulan ini kamu menyisihkan ${rupiah(masuk.value - keluar.value)}.`
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
      <span class="hl">Total saldo keluarga</span>
      <div class="big">{{ rupiah(totalSaldo) }}</div>
      <input type="month" v-model="bulan" aria-label="Bulan" />
    </div>
    <div class="riyu"><div class="bubble">{{ sapa }}</div><Mascot :size="84" /></div>
  </section>

  <div class="grid2">
    <div class="card"><span class="mute">Pemasukan bulan ini</span><div class="num in">{{ rupiah(masuk) }}</div></div>
    <div class="card"><span class="mute">Pengeluaran bulan ini</span><div class="num out">{{ rupiah(keluar) }}</div></div>
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
    <h3>Transaksi terakhir</h3>
    <p v-if="!db.transaksi.length" class="mute">Belum ada transaksi. Mulai dari tab Transaksi.</p>
    <div v-for="t in db.transaksi.slice(0, 6)" :key="t.id" class="row">
      <span>{{ nama(db.kategori, t.kategori_id) }} <small class="mute">{{ tglIndo(t.tanggal) }}</small></span>
      <b :class="t.tipe === 'pemasukan' ? 'in' : 'out'">{{ t.tipe === 'pemasukan' ? '+' : '−' }}{{ rupiah(t.jumlah) }}</b>
    </div>
  </div>
</template>
