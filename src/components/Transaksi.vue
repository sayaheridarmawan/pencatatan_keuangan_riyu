<script setup>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../supabase'
import { db, loadAll, safe, rupiah, nama, tglIndo, today } from '../store'

const bulan = ref(today().slice(0, 7))
const filterTipe = ref('')
const open = ref(false), editId = ref(null), err = ref(''), saving = ref(false)
const blank = () => ({ tipe: 'pengeluaran', tanggal: today(), jumlah: '', akun_id: db.akun[0]?.id || '', kategori_id: '', anggota_id: '', catatan: '' })
const f = reactive(blank())

const kats = computed(() => db.kategori.filter((k) => k.tipe === f.tipe))
const rows = computed(() =>
  db.transaksi.filter((t) => t.tanggal.startsWith(bulan.value) && (!filterTipe.value || t.tipe === filterTipe.value))
)

function baru() { Object.assign(f, blank()); editId.value = null; err.value = ''; open.value = true }
function ubah(t) {
  Object.assign(f, { ...t, jumlah: Number(t.jumlah), anggota_id: t.anggota_id || '', catatan: t.catatan || '' })
  editId.value = t.id; err.value = ''; open.value = true
}
function setTipe(t) { f.tipe = t; f.kategori_id = '' }

async function simpan() {
  if (!(f.jumlah > 0) || !f.akun_id || !f.kategori_id) { err.value = 'Isi jumlah, akun, dan kategori.'; return }
  err.value = ''; saving.value = true
  const payload = {
    tipe: f.tipe, tanggal: f.tanggal, jumlah: Number(f.jumlah), akun_id: f.akun_id,
    kategori_id: f.kategori_id, anggota_id: f.anggota_id || null, catatan: f.catatan || null,
  }
  const ok = await safe(() => editId.value
    ? supabase.from('transaksi').update(payload).eq('id', editId.value)
    : supabase.from('transaksi').insert(payload), 'Transaksi tersimpan')
  saving.value = false
  if (ok) { open.value = false; await loadAll() }
}
async function hapus(t) {
  if (!confirm('Hapus transaksi ini?')) return
  if (await safe(() => supabase.from('transaksi').delete().eq('id', t.id), 'Transaksi dihapus')) await loadAll()
}
</script>

<template>
  <div class="toolbar">
    <input type="month" v-model="bulan" aria-label="Bulan" />
    <select v-model="filterTipe" aria-label="Jenis">
      <option value="">Semua</option><option value="pemasukan">Pemasukan</option><option value="pengeluaran">Pengeluaran</option>
    </select>
    <span class="grow"></span>
    <button class="btn primary" @click="baru" :disabled="!db.akun.length || !db.kategori.length">Tambah transaksi</button>
  </div>
  <p v-if="!db.akun.length || !db.kategori.length" class="note">Lengkapi akun dan kategori di Master data sebelum mencatat transaksi.</p>

  <div v-if="open" class="card form">
    <h3>{{ editId ? 'Ubah transaksi' : 'Transaksi baru' }}</h3>
    <div class="seg">
      <button :class="{ on: f.tipe === 'pengeluaran', out: true }" @click="setTipe('pengeluaran')">Pengeluaran</button>
      <button :class="{ on: f.tipe === 'pemasukan', inn: true }" @click="setTipe('pemasukan')">Pemasukan</button>
    </div>
    <div class="fields">
      <label>Tanggal<input type="date" v-model="f.tanggal" /></label>
      <label>Jumlah (Rp)<input type="number" min="1" inputmode="numeric" v-model="f.jumlah" /></label>
      <label>Akun<select v-model="f.akun_id"><option v-for="a in db.akun" :key="a.id" :value="a.id">{{ a.nama }}</option></select></label>
      <label>Kategori<select v-model="f.kategori_id"><option value="" disabled>Pilih…</option><option v-for="k in kats" :key="k.id" :value="k.id">{{ k.nama }}</option></select></label>
      <label>Anggota<select v-model="f.anggota_id"><option value="">Tidak ditentukan</option><option v-for="m in db.anggota" :key="m.id" :value="m.id">{{ m.nama }}</option></select></label>
      <label>Catatan<input v-model="f.catatan" placeholder="Opsional" /></label>
    </div>
    <p v-if="err" class="err">{{ err }}</p>
    <div class="actions"><button class="btn" @click="open = false">Batal</button><button class="btn primary" :disabled="saving" @click="simpan">{{ saving ? 'Menyimpan…' : 'Simpan' }}</button></div>
  </div>

  <div class="card">
    <p v-if="!rows.length" class="mute">Tidak ada transaksi pada filter ini.</p>
    <div v-for="t in rows" :key="t.id" class="tx">
      <div class="grow">
        <b>{{ nama(db.kategori, t.kategori_id) }}</b>
        <div class="mute small">{{ tglIndo(t.tanggal) }} · {{ nama(db.akun, t.akun_id) }}<template v-if="t.anggota_id"> · {{ nama(db.anggota, t.anggota_id) }}</template><template v-if="t.catatan"> · {{ t.catatan }}</template></div>
      </div>
      <b :class="t.tipe === 'pemasukan' ? 'in' : 'out'">{{ t.tipe === 'pemasukan' ? '+' : '−' }}{{ rupiah(t.jumlah) }}</b>
      <button class="link" @click="ubah(t)">Ubah</button>
      <button class="link danger" @click="hapus(t)">Hapus</button>
    </div>
  </div>
</template>
