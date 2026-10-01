<script setup>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../supabase'
import Combo from './Combo.vue'
import RupiahInput from './RupiahInput.vue'
import { db, loadAll, safe, notify, rupiah } from '../store'

const tabs = { akun: 'Akun / dompet', kategori: 'Kategori', anggota: 'Anggota keluarga' }
const cur = ref('akun')
const editId = ref(null), err = ref('')
const f = reactive({ nama: '', saldo_awal: 0, tipe: 'pengeluaran' })
const list = computed(() => db[cur.value])
const opsiTipe = [{ id: 'pengeluaran', nama: 'Pengeluaran' }, { id: 'pemasukan', nama: 'Pemasukan' }]

function reset() { Object.assign(f, { nama: '', saldo_awal: 0, tipe: 'pengeluaran' }); editId.value = null; err.value = '' }
function pilih(t) { cur.value = t; reset() }
function ubah(x) { Object.assign(f, { nama: x.nama, saldo_awal: x.saldo_awal ?? 0, tipe: x.tipe ?? 'pengeluaran' }); editId.value = x.id }

async function simpan() {
  if (!f.nama.trim()) { err.value = 'Nama wajib diisi.'; return }
  err.value = ''
  const p = { nama: f.nama.trim() }
  if (cur.value === 'akun') p.saldo_awal = Number(f.saldo_awal) || 0
  if (cur.value === 'kategori') p.tipe = f.tipe
  const t = supabase.from(cur.value)
  const ok = await safe(() => (editId.value ? t.update(p).eq('id', editId.value) : t.insert(p)), 'Tersimpan')
  if (ok) { reset(); await loadAll() }
}
// Hitung pemakaian master di transaksi dan transfer
function pakai(x) {
  const k = cur.value
  const kolom = k === 'akun' ? 'akun_id' : k === 'kategori' ? 'kategori_id' : 'anggota_id'
  const transaksi = db.transaksi.filter((t) => t[kolom] === x.id).length
  const transfer = k === 'akun' ? db.transfer.filter((t) => t.akun_asal_id === x.id || t.akun_tujuan_id === x.id).length : 0
  return { transaksi, transfer, total: transaksi + transfer }
}
async function hapus(x) {
  const p = pakai(x)
  if (p.total) {
    const bagian = [p.transaksi && `${p.transaksi} transaksi`, p.transfer && `${p.transfer} transfer`].filter(Boolean).join(' dan ')
    notify(`"${x.nama}" tidak bisa dihapus karena masih dipakai di ${bagian}.`, 'err')
    return
  }
  if (!confirm(`Hapus "${x.nama}"?`)) return
  if (await safe(() => supabase.from(cur.value).delete().eq('id', x.id), 'Dihapus')) await loadAll()
}
async function contoh() {
  const u = (n) => ({ nama: n })
  const ok = await safe(async () => {
    for (const r of [
      supabase.from('akun').insert([u('Tunai'), u('Rekening bank'), u('E-wallet')]),
      supabase.from('kategori').insert([
        ...['Gaji', 'Usaha', 'Pemasukan lain'].map((n) => ({ nama: n, tipe: 'pemasukan' })),
        ...['Makan & minum', 'Transportasi', 'Tagihan', 'Belanja', 'Pendidikan', 'Kesehatan', 'Hiburan', 'Pengeluaran lain'].map((n) => ({ nama: n, tipe: 'pengeluaran' })),
      ]),
      supabase.from('anggota').insert([u('Ayah'), u('Ibu')]),
    ]) { const { error } = await r; if (error) throw error }
  }, 'Data contoh ditambahkan')
  if (ok) await loadAll()
}
</script>

<template>
  <div v-if="!db.akun.length && !db.kategori.length && !db.anggota.length" class="note">
    Master data masih kosong. <button class="link" @click="contoh">Isi dengan contoh</button> atau tambahkan sendiri di bawah.
  </div>
  <div class="seg wide">
    <button v-for="(l, k) in tabs" :key="k" :class="{ on: cur === k }" @click="pilih(k)">{{ l }}</button>
  </div>
  <div class="card form">
    <div class="fields">
      <label>Nama<input v-model="f.nama" maxlength="60" @keyup.enter="simpan" /></label>
      <RupiahInput v-if="cur === 'akun'" v-model="f.saldo_awal" label="Saldo awal" />
      <Combo v-if="cur === 'kategori'" v-model="f.tipe" :options="opsiTipe" label="Jenis" placeholder="Pilih jenis…" :clearable="false" />
    </div>
    <p v-if="err" class="err">{{ err }}</p>
    <div class="actions">
      <button v-if="editId" class="btn" @click="reset">Batal</button>
      <button class="btn primary" @click="simpan">{{ editId ? 'Simpan perubahan' : 'Tambah' }}</button>
    </div>
  </div>
  <div class="card">
    <p v-if="!list.length" class="mute">Belum ada data.</p>
    <div v-for="x in list" :key="x.id" class="tx">
      <div class="grow">
        <b>{{ x.nama }}</b><small v-if="pakai(x).total" class="mute"> · dipakai {{ pakai(x).total }}×</small>
        <span v-if="cur === 'akun'" class="mute small"> · saldo awal {{ rupiah(x.saldo_awal) }}</span>
        <span v-if="cur === 'kategori'" :class="['tag', x.tipe === 'pemasukan' ? 'in' : 'out']">{{ x.tipe }}</span>
      </div>
      <button class="link" @click="ubah(x)">Ubah</button>
      <button class="link danger" @click="hapus(x)">Hapus</button>
    </div>
  </div>
</template>
