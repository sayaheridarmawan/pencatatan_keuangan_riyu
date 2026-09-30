<script setup>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../supabase'
import Combo from './Combo.vue'
import RupiahInput from './RupiahInput.vue'
import { db, loadAll, safe, rupiah, nama, tglIndo, today } from '../store'

const bulan = ref(today().slice(0, 7))
const filterTipe = ref('')
const open = ref(false), editId = ref(null), err = ref(''), saving = ref(false)
const blank = () => ({ tipe: 'pengeluaran', tanggal: today(), jumlah: '', akun_id: db.akun[0]?.id || '', kategori_id: '', anggota_id: '', catatan: '' })
const f = reactive(blank())

// kategori sesuai jenis transaksi; yang paling sering dipakai tampil paling atas
const kats = computed(() => {
  const pakai = {}
  db.transaksi.forEach((t) => (pakai[t.kategori_id] = (pakai[t.kategori_id] || 0) + 1))
  return db.kategori
    .filter((k) => k.tipe === f.tipe)
    .sort((a, b) => (pakai[b.id] || 0) - (pakai[a.id] || 0) || a.nama.localeCompare(b.nama))
})
const opsiTipe = [{ id: 'pemasukan', nama: 'Pemasukan' }, { id: 'pengeluaran', nama: 'Pengeluaran' }]
const rows = computed(() =>
  db.transaksi.filter((t) => t.tanggal.startsWith(bulan.value) && (!filterTipe.value || t.tipe === filterTipe.value))
)

function baru() { Object.assign(sisih, { target_id: '', jumlah: '' }); Object.assign(f, blank()); editId.value = null; err.value = ''; open.value = true }
function ubah(t) {
  Object.assign(f, { ...t, jumlah: Number(t.jumlah), anggota_id: t.anggota_id || '', catatan: t.catatan || '' })
  editId.value = t.id; err.value = ''; open.value = true
}
function setTipe(t) { f.tipe = t; f.kategori_id = '' }

const sisih = reactive({ target_id: '', jumlah: '' })
async function simpan() {
  if (!(f.jumlah > 0) || !f.akun_id || !f.kategori_id) { err.value = 'Isi jumlah, akun, dan kategori.'; return }
  const alokasi = f.tipe === 'pemasukan' && !editId.value && sisih.target_id ? Number(sisih.jumlah) : 0
  if (sisih.target_id && f.tipe === 'pemasukan' && !editId.value && !(alokasi > 0 && alokasi <= Number(f.jumlah))) {
    err.value = 'Jumlah yang disisihkan harus lebih dari 0 dan tidak melebihi jumlah pemasukan.'; return
  }
  err.value = ''; saving.value = true
  const payload = {
    tipe: f.tipe, tanggal: f.tanggal, jumlah: Number(f.jumlah), akun_id: f.akun_id,
    kategori_id: f.kategori_id, anggota_id: f.anggota_id || null, catatan: f.catatan || null,
  }
  let ok = await safe(() => editId.value
    ? supabase.from('transaksi').update(payload).eq('id', editId.value)
    : supabase.from('transaksi').insert(payload), 'Transaksi tersimpan')
  if (ok && alokasi > 0) {
    ok = await safe(() => supabase.from('transfer').insert({
      tanggal: f.tanggal, jumlah: alokasi, akun_asal_id: f.akun_id, akun_tujuan_id: f.akun_id,
      target_id: sisih.target_id, catatan: 'Dari pemasukan: ' + nama(db.kategori, f.kategori_id),
    }), 'Sebagian disisihkan ke target')
  }
  saving.value = false
  if (ok) { open.value = false; Object.assign(sisih, { target_id: '', jumlah: '' }) }
  await loadAll()
}
async function hapus(t) {
  if (!confirm('Hapus transaksi ini?')) return
  if (await safe(() => supabase.from('transaksi').delete().eq('id', t.id), 'Transaksi dihapus')) await loadAll()
}
</script>

<template>
  <div class="toolbar">
    <input type="month" v-model="bulan" aria-label="Bulan" />
    <Combo v-model="filterTipe" :options="opsiTipe" placeholder="Semua jenis" />
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
      <RupiahInput v-model="f.jumlah" label="Jumlah" />
      <Combo v-model="f.akun_id" :options="db.akun" label="Akun" placeholder="Cari akun…" :clearable="false" />
      <Combo v-model="f.kategori_id" :options="kats" label="Kategori" placeholder="Ketik untuk mencari…" />
      <Combo v-model="f.anggota_id" :options="db.anggota" label="Anggota" placeholder="Tidak ditentukan" />
      <label>Catatan<input v-model="f.catatan" placeholder="Opsional" maxlength="200" /></label>
    </div>
    <div v-if="f.tipe === 'pemasukan' && !editId && db.target.length" class="fields">
      <Combo v-model="sisih.target_id" :options="db.target" label="Sisihkan ke target (opsional)" placeholder="Tidak" />
      <RupiahInput v-if="sisih.target_id" v-model="sisih.jumlah" label="Jumlah disisihkan" />
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
