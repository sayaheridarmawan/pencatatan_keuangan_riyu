<script setup>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../supabase'
import Combo from './Combo.vue'
import RupiahInput from './RupiahInput.vue'
import Lampiran from './Lampiran.vue'
import LampiranView from './LampiranView.vue'
import { db, loadAll, safe, notify, pesanError, rupiah, nama, tglIndo, today } from '../store'
import { unggah, hapusFile } from '../lampiran'

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

function baru() { lamp.value = { file: null, hapus: false }; Object.assign(sisih, { target_id: '', jumlah: '' }); Object.assign(f, blank()); editId.value = null; err.value = ''; open.value = true }
function ubah(t) {
  Object.assign(f, { ...t, jumlah: Number(t.jumlah), anggota_id: t.anggota_id || '', catatan: t.catatan || '' })
  lamp.value = { file: null, hapus: false }
  editId.value = t.id; err.value = ''; open.value = true
}
function setTipe(t) { f.tipe = t; f.kategori_id = '' }

const sisih = reactive({ target_id: '', jumlah: '' })
const lamp = ref({ file: null, hapus: false })
const lihatPath = ref('')
const lampAda = computed(() => (editId.value ? db.transaksi.find((x) => x.id === editId.value)?.lampiran_path || '' : ''))
async function simpan() {
  if (!(f.jumlah > 0) || !f.akun_id || !f.kategori_id) { err.value = 'Isi jumlah, akun, dan kategori.'; return }
  const alokasi = f.tipe === 'pemasukan' && !editId.value && sisih.target_id ? Number(sisih.jumlah) : 0
  if (sisih.target_id && f.tipe === 'pemasukan' && !editId.value && !(alokasi > 0 && alokasi <= Number(f.jumlah))) {
    err.value = 'Jumlah yang disisihkan harus lebih dari 0 dan tidak melebihi jumlah pemasukan.'; return
  }
  err.value = ''; saving.value = true
  let pathBaru = null
  if (lamp.value.file) {
    try { pathBaru = await unggah(lamp.value.file.blob, lamp.value.file.ext, lamp.value.file.type) }
    catch (e) { notify(pesanError(e), 'err'); saving.value = false; return }
  }
  const payload = {
    tipe: f.tipe, tanggal: f.tanggal, jumlah: Number(f.jumlah), akun_id: f.akun_id,
    kategori_id: f.kategori_id, anggota_id: f.anggota_id || null, catatan: f.catatan || null,
  }
  if (pathBaru) payload.lampiran_path = pathBaru
  else if (lamp.value.hapus) payload.lampiran_path = null
  let ok = await safe(() => editId.value
    ? supabase.from('transaksi').update(payload).eq('id', editId.value)
    : supabase.from('transaksi').insert(payload), 'Transaksi tersimpan')
  if (!ok && pathBaru) await hapusFile(pathBaru)
  if (ok && editId.value && (pathBaru || lamp.value.hapus)) await hapusFile(lampAda.value)
  if (ok && alokasi > 0) {
    ok = await safe(() => supabase.from('transfer').insert({
      tanggal: f.tanggal, jumlah: alokasi, akun_asal_id: f.akun_id, akun_tujuan_id: f.akun_id,
      target_id: sisih.target_id, catatan: 'Dari pemasukan: ' + nama(db.kategori, f.kategori_id),
    }), 'Sebagian disisihkan ke target')
  }
  saving.value = false
  if (ok) { open.value = false; Object.assign(sisih, { target_id: '', jumlah: '' }); lamp.value = { file: null, hapus: false } }
  await loadAll()
}
async function hapus(t) {
  if (!confirm('Hapus transaksi ini?')) return
  if (await safe(() => supabase.from('transaksi').delete().eq('id', t.id), 'Transaksi dihapus')) {
    await hapusFile(t.lampiran_path)
    await loadAll()
  }
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
    <div class="fields"><Lampiran v-model="lamp" :ada="lampAda" @lihat="lihatPath = $event" /></div>
    <p v-if="err" class="err" role="alert">{{ err }}</p>
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
      <button v-if="t.lampiran_path" class="link" title="Lihat lampiran" aria-label="Lihat lampiran" @click="lihatPath = t.lampiran_path"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.4 11.1 12.2 20.3a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 0 1-2.8-2.8l8.5-8.5" /></svg></button>
      <button class="link" @click="ubah(t)">Ubah</button>
      <button class="link danger" @click="hapus(t)">Hapus</button>
    </div>
  </div>
  <LampiranView v-if="lihatPath" :path="lihatPath" @tutup="lihatPath = ''" />
</template>
