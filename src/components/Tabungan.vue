<script setup>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../supabase'
import Combo from './Combo.vue'
import RupiahInput from './RupiahInput.vue'
import Lampiran from './Lampiran.vue'
import LampiranView from './LampiranView.vue'
import { db, loadAll, safe, notify, pesanError, rupiah, nama, tglIndo, today, terkumpul, saldoAkunId } from '../store'
import { unggah, hapusFile } from '../lampiran'

const lamp = ref({ file: null, hapus: false })
const lihatPath = ref('')
const mode = ref('pindah') // 'pindah' = antar akun, 'sisih' = sisihkan ke target di akun yang sama
const err = ref(''), gErr = ref(''), saving = ref(false)
const t = reactive({ tanggal: today(), jumlah: '', asal: '', tujuan: '', target_id: '', catatan: '' })
const g = reactive({ nama: '', target_jumlah: '', tenggat: '' })
const pct = (x) => Math.min(100, (terkumpul(x.id) / x.target_jumlah) * 100)
const opsiAsal = computed(() => db.akun.map((a) => ({ id: a.id, nama: `${a.nama} · ${rupiah(saldoAkunId(a.id))}` })))
const opsiTujuan = computed(() => db.akun.filter((a) => a.id !== t.asal))
const saldoAsal = computed(() => (t.asal ? saldoAkunId(t.asal) : null))
const setMode = (m) => { mode.value = m; err.value = ''; t.tujuan = '' }

async function simpanTransfer() {
  const jumlah = Number(t.jumlah)
  const sisih = mode.value === 'sisih'
  if (!(jumlah > 0) || !t.asal) { err.value = 'Isi jumlah dan akun sumber.'; return }
  if (sisih && !t.target_id) { err.value = 'Pilih target yang akan diisi.'; return }
  if (!sisih && !t.tujuan) { err.value = 'Pilih akun tujuan.'; return }
  if (!sisih && t.asal === t.tujuan) { err.value = 'Akun sumber dan tujuan tidak boleh sama.'; return }
  if (jumlah > saldoAsal.value) {
    err.value = `Saldo ${nama(db.akun, t.asal)} hanya ${rupiah(saldoAsal.value)}, tidak cukup untuk ${rupiah(jumlah)}.`
    return
  }
  err.value = ''; saving.value = true
  let pathBaru = null
  if (lamp.value.file) {
    try { pathBaru = await unggah(lamp.value.file.blob, lamp.value.file.ext, lamp.value.file.type) }
    catch (e) { notify(pesanError(e), 'err'); saving.value = false; return }
  }
  const payload = {
    tanggal: t.tanggal, jumlah, akun_asal_id: t.asal, akun_tujuan_id: sisih ? t.asal : t.tujuan,
    target_id: t.target_id || null, catatan: t.catatan || null,
  }
  if (pathBaru) payload.lampiran_path = pathBaru
  const ok = await safe(() => supabase.from('transfer').insert(payload), sisih ? 'Dana disisihkan ke target' : 'Transfer tersimpan')
  if (!ok && pathBaru) await hapusFile(pathBaru)
  saving.value = false
  if (ok) { Object.assign(t, { jumlah: '', catatan: '', target_id: '' }); lamp.value = { file: null, hapus: false }; await loadAll() }
}
async function hapusTransfer(x) {
  if (!confirm('Hapus catatan ini?')) return
  if (await safe(() => supabase.from('transfer').delete().eq('id', x.id), 'Catatan dihapus')) {
    await hapusFile(x.lampiran_path)
    await loadAll()
  }
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
const label = (x) =>
  x.akun_asal_id === x.akun_tujuan_id
    ? `Disisihkan di ${nama(db.akun, x.akun_asal_id)}`
    : `${nama(db.akun, x.akun_asal_id)} → ${nama(db.akun, x.akun_tujuan_id)}`
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
      <label>Nama target<input v-model="g.nama" maxlength="60" /></label>
      <RupiahInput v-model="g.target_jumlah" label="Nominal target" />
      <label>Tenggat (opsional)<input type="date" v-model="g.tenggat" /></label>
    </div>
    <p v-if="gErr" class="err" role="alert">{{ gErr }}</p>
    <div class="actions"><button class="btn primary" @click="simpanTarget">Buat target</button></div>
  </div>

  <div class="card form">
    <h3>Transfer dan alokasi dana</h3>
    <div class="seg">
      <button :class="{ on: mode === 'pindah' }" @click="setMode('pindah')">Pindah antar akun</button>
      <button :class="{ on: mode === 'sisih' }" @click="setMode('sisih')">Sisihkan ke target</button>
    </div>
    <p class="mute small">{{ mode === 'pindah'
      ? 'Memindahkan uang dari satu akun ke akun lain. Tidak dihitung sebagai pemasukan atau pengeluaran.'
      : 'Menandai sebagian saldo sebuah akun untuk target tanpa memindahkan uangnya. Cocok untuk pemasukan yang langsung ingin disisihkan.' }}</p>
    <p v-if="db.akun.length < (mode === 'pindah' ? 2 : 1)" class="note">Buat akun di Master data terlebih dahulu{{ mode === 'pindah' ? ' (minimal dua akun)' : '' }}.</p>
    <div class="fields">
      <label>Tanggal<input type="date" v-model="t.tanggal" /></label>
      <RupiahInput v-model="t.jumlah" label="Jumlah" />
      <Combo v-model="t.asal" :options="opsiAsal" :label="mode === 'pindah' ? 'Dari akun' : 'Akun sumber'" placeholder="Cari akun…" :clearable="false" />
      <Combo v-if="mode === 'pindah'" v-model="t.tujuan" :options="opsiTujuan" label="Ke akun" placeholder="Cari akun…" :clearable="false" />
      <Combo v-model="t.target_id" :options="db.target" :label="mode === 'sisih' ? 'Untuk target' : 'Untuk target (opsional)'" :placeholder="mode === 'sisih' ? 'Pilih target…' : 'Tanpa target'" />
      <label>Catatan<input v-model="t.catatan" placeholder="Opsional" maxlength="200" /></label>
    </div>
    <div class="fields"><Lampiran v-model="lamp" @lihat="lihatPath = $event" /></div>
    <p v-if="saldoAsal !== null" class="mute small">Saldo tersedia: <b>{{ rupiah(saldoAsal) }}</b></p>
    <p v-if="err" class="err" role="alert">{{ err }}</p>
    <div class="actions"><button class="btn primary" :disabled="saving" @click="simpanTransfer">{{ saving ? 'Menyimpan…' : 'Simpan' }}</button></div>
  </div>

  <div class="card">
    <h3>Riwayat transfer dan alokasi</h3>
    <p v-if="!db.transfer.length" class="mute">Belum ada catatan.</p>
    <div v-for="x in db.transfer" :key="x.id" class="tx">
      <div class="grow">
        <b>{{ label(x) }}</b>
        <div class="mute small">{{ tglIndo(x.tanggal) }}<template v-if="x.target_id"> · {{ nama(db.target, x.target_id) }}</template><template v-if="x.catatan"> · {{ x.catatan }}</template></div>
      </div>
      <b>{{ rupiah(x.jumlah) }}</b>
      <button v-if="x.lampiran_path" class="link" title="Lihat lampiran" aria-label="Lihat lampiran" @click="lihatPath = x.lampiran_path"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.4 11.1 12.2 20.3a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 0 1-2.8-2.8l8.5-8.5" /></svg></button>
      <button class="link danger" @click="hapusTransfer(x)">Hapus</button>
    </div>
  </div>
  <LampiranView v-if="lihatPath" :path="lihatPath" @tutup="lihatPath = ''" />
</template>
