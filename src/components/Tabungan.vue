<script setup>
import { ref, reactive } from 'vue'
import { supabase } from '../supabase'
import { db, loadAll, safe, rupiah, nama, tglIndo, today, terkumpul } from '../store'

const err = ref(''), gErr = ref(''), saving = ref(false)
const t = reactive({ tanggal: today(), jumlah: '', asal: '', tujuan: '', target_id: '', catatan: '' })
const g = reactive({ nama: '', target_jumlah: '', tenggat: '' })
const pct = (x) => Math.min(100, (terkumpul(x.id) / x.target_jumlah) * 100)

async function simpanTransfer() {
  if (!(t.jumlah > 0) || !t.asal || !t.tujuan) { err.value = 'Isi jumlah, akun asal, dan akun tujuan.'; return }
  if (t.asal === t.tujuan) { err.value = 'Akun asal dan tujuan tidak boleh sama.'; return }
  err.value = ''; saving.value = true
  const ok = await safe(() => supabase.from('transfer').insert({
    tanggal: t.tanggal, jumlah: Number(t.jumlah), akun_asal_id: t.asal, akun_tujuan_id: t.tujuan,
    target_id: t.target_id || null, catatan: t.catatan || null,
  }), 'Transfer tersimpan')
  saving.value = false
  if (ok) { Object.assign(t, { jumlah: '', catatan: '', target_id: '' }); await loadAll() }
}
async function hapusTransfer(x) {
  if (!confirm('Hapus transfer ini?')) return
  if (await safe(() => supabase.from('transfer').delete().eq('id', x.id), 'Transfer dihapus')) await loadAll()
}
async function simpanTarget() {
  if (!g.nama.trim() || !(g.target_jumlah > 0)) { gErr.value = 'Isi nama dan nominal target.'; return }
  gErr.value = ''
  const ok = await safe(() => supabase.from('target').insert({
    nama: g.nama.trim(), target_jumlah: Number(g.target_jumlah), tenggat: g.tenggat || null,
  }), 'Target dibuat')
  if (ok) { Object.assign(g, { nama: '', target_jumlah: '', tenggat: '' }); await loadAll() }
}
async function hapusTarget(x) {
  if (!confirm(`Hapus target "${x.nama}"? Riwayat transfer tetap ada.`)) return
  if (await safe(() => supabase.from('target').delete().eq('id', x.id), 'Target dihapus')) await loadAll()
}
</script>

<template>
  <div class="card">
    <h3>Target tabungan</h3>
    <p v-if="!db.target.length" class="mute">Belum ada target. Buat yang pertama, misalnya "Dana darurat" atau "Liburan".</p>
    <div v-for="x in db.target" :key="x.id" class="bar-item">
      <div class="row">
        <span><b>{{ x.nama }}</b><small v-if="x.tenggat" class="mute"> · sampai {{ tglIndo(x.tenggat) }}</small></span>
        <button class="link danger" @click="hapusTarget(x)">Hapus</button>
      </div>
      <div class="row small"><span>{{ rupiah(terkumpul(x.id)) }} dari {{ rupiah(x.target_jumlah) }}</span><b class="in">{{ Math.floor(pct(x)) }}%</b></div>
      <div class="track"><i class="goal" :style="{ width: pct(x) + '%' }"></i></div>
    </div>
    <div class="fields">
      <label>Nama target<input v-model="g.nama" /></label>
      <label>Nominal (Rp)<input type="number" min="1" inputmode="numeric" v-model="g.target_jumlah" /></label>
      <label>Tenggat (opsional)<input type="date" v-model="g.tenggat" /></label>
    </div>
    <p v-if="gErr" class="err" role="alert">{{ gErr }}</p>
    <div class="actions"><button class="btn primary" @click="simpanTarget">Buat target</button></div>
  </div>

  <div class="card form">
    <h3>Transfer / menabung</h3>
    <p class="mute small">Pindahkan uang antar akun. Transfer tidak dihitung sebagai pemasukan maupun pengeluaran.</p>
    <p v-if="db.akun.length < 2" class="note">Buat minimal dua akun (misalnya "Tabungan") di Master data terlebih dahulu.</p>
    <div class="fields">
      <label>Tanggal<input type="date" v-model="t.tanggal" /></label>
      <label>Jumlah (Rp)<input type="number" min="1" inputmode="numeric" v-model="t.jumlah" /></label>
      <label>Dari akun<select v-model="t.asal"><option value="" disabled>Pilih…</option><option v-for="a in db.akun" :key="a.id" :value="a.id">{{ a.nama }}</option></select></label>
      <label>Ke akun<select v-model="t.tujuan"><option value="" disabled>Pilih…</option><option v-for="a in db.akun" :key="a.id" :value="a.id">{{ a.nama }}</option></select></label>
      <label>Untuk target<select v-model="t.target_id"><option value="">Tanpa target</option><option v-for="x in db.target" :key="x.id" :value="x.id">{{ x.nama }}</option></select></label>
      <label>Catatan<input v-model="t.catatan" placeholder="Opsional" /></label>
    </div>
    <p v-if="err" class="err" role="alert">{{ err }}</p>
    <div class="actions"><button class="btn primary" :disabled="saving || db.akun.length < 2" @click="simpanTransfer">{{ saving ? 'Menyimpan…' : 'Simpan transfer' }}</button></div>
  </div>

  <div class="card">
    <h3>Riwayat transfer</h3>
    <p v-if="!db.transfer.length" class="mute">Belum ada transfer.</p>
    <div v-for="x in db.transfer" :key="x.id" class="tx">
      <div class="grow">
        <b>{{ nama(db.akun, x.akun_asal_id) }} → {{ nama(db.akun, x.akun_tujuan_id) }}</b>
        <div class="mute small">{{ tglIndo(x.tanggal) }}<template v-if="x.target_id"> · {{ nama(db.target, x.target_id) }}</template><template v-if="x.catatan"> · {{ x.catatan }}</template></div>
      </div>
      <b>{{ rupiah(x.jumlah) }}</b>
      <button class="link danger" @click="hapusTransfer(x)">Hapus</button>
    </div>
  </div>
</template>
