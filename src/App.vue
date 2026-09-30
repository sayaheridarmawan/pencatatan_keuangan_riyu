<script setup>
import { ref, onMounted, onErrorCaptured } from 'vue'
import { supabase, envOk } from './supabase'
import { loadAll, ui, db, notify, pesanError, bersihkan } from './store'
import { sisaBlokir, gagalLimiter, resetLimiter } from './limiter'
import Mascot from './components/Mascot.vue'
import Dashboard from './components/Dashboard.vue'
import Transaksi from './components/Transaksi.vue'
import Master from './components/Master.vue'
import Tabungan from './components/Tabungan.vue'
import Sandi from './components/Sandi.vue'
import PasswordInput from './components/PasswordInput.vue'

const session = ref(null)
const ready = ref(false)
const online = ref(navigator.onLine)
const tab = ref('ringkasan')
const tabs = [
  ['ringkasan', 'Ringkasan', 'M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z'],
  ['transaksi', 'Transaksi', 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01'],
  ['tabungan', 'Tabungan', 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12zM12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4z'],
  ['master', 'Master', 'M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6'],
]
const sandi = ref(false)
// Pendaftaran disembunyikan. Set VITE_ALLOW_SIGNUP=true jika suatu saat ingin menampilkannya.
const bolehDaftar = import.meta.env.VITE_ALLOW_SIGNUP === 'true'
const email = ref(''), password = ref(''), mode = ref('masuk'), msg = ref(''), busy = ref(false)

onErrorCaptured((e) => { notify(pesanError(e), 'err'); return false })

onMounted(async () => {
  window.addEventListener('online', () => { online.value = true; if (session.value) loadAll() })
  window.addEventListener('offline', () => (online.value = false))
  ;['click', 'keydown', 'touchstart', 'scroll'].forEach((ev) => window.addEventListener(ev, resetIdle, { passive: true }))
  mulaiHitung()
  try {
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    if (session.value) { loadAll(); resetIdle() }
  } catch (e) { msg.value = pesanError(e) }
  ready.value = true
  supabase.auth.onAuthStateChange((_e, s) => {
    const was = !!session.value
    session.value = s
    if (s && !was) setTimeout(loadAll, 0)
    if (!s) bersihkan()
    resetIdle()
  })
})

const generik = 'Email atau kata sandi salah.'
const blokir = ref(0)
let hitung = null
function mulaiHitung() {
  clearInterval(hitung)
  blokir.value = sisaBlokir('login')
  if (!blokir.value) return
  hitung = setInterval(() => { blokir.value = sisaBlokir('login'); if (!blokir.value) clearInterval(hitung) }, 1000)
}
// Keluar otomatis setelah 30 menit tanpa aktivitas
const IDLE_MS = 30 * 60 * 1000
let idleTimer = null
function resetIdle() {
  clearTimeout(idleTimer)
  if (!session.value) return
  idleTimer = setTimeout(async () => {
    await supabase.auth.signOut()
    notify('Sesi berakhir karena tidak aktif. Silakan masuk lagi.', 'err')
  }, IDLE_MS)
}

async function submit() {
  if (blokir.value || busy.value) return
  busy.value = true
  msg.value = ''
  try {
    const creds = { email: email.value.trim().toLowerCase(), password: password.value }
    const { data, error } =
      mode.value === 'masuk' ? await supabase.auth.signInWithPassword(creds) : await supabase.auth.signUp(creds)
    if (error) throw error
    resetLimiter('login')
    if (mode.value === 'daftar' && !data.session) msg.value = 'Akun dibuat. Konfirmasi email dulu, lalu masuk.'
  } catch (e) {
    const p = pesanError(e)
    if (mode.value === 'masuk' && (p === generik || p === 'Email belum dikonfirmasi.')) {
      msg.value = generik // pesan seragam agar email tidak bisa ditebak
      gagalLimiter('login')
      mulaiHitung()
    } else msg.value = p
  }
  busy.value = false
}
async function keluar() {
  await supabase.auth.signOut()
  email.value = ''; password.value = ''; tab.value = 'ringkasan'
}
</script>

<template>
  <div v-if="!envOk" class="center">
    <div class="card login">
      <Mascot :size="84" />
      <h1>Riyu belum tersambung</h1>
      <p class="mute">File <b>.env</b> belum berisi <b>VITE_SUPABASE_URL</b> dan <b>VITE_SUPABASE_ANON_KEY</b>. Isi keduanya (atau tambahkan di Environment Variables Vercel), lalu jalankan ulang.</p>
    </div>
  </div>

  <div v-else-if="!ready" class="center"><Mascot :size="72" class="bob" /></div>

  <div v-else-if="!session" class="center">
    <form class="card login" @submit.prevent="submit">
      <Mascot :size="92" class="bob" />
      <h1>Riyu Family</h1>
      <p class="mute">Catat uang keluarga bareng Riyu.</p>
      <label>Email<input v-model="email" type="email" required autocomplete="email" maxlength="254" /></label>
      <PasswordInput v-model="password" label="Kata sandi" :autocomplete="mode === 'masuk' ? 'current-password' : 'new-password'" />
      <p v-if="msg" class="err" role="alert">{{ msg }}</p>
      <button class="btn primary" :disabled="busy || !online || blokir > 0">{{ blokir ? `Coba lagi ${blokir} detik` : busy ? 'Tunggu ya…' : mode === 'masuk' ? 'Masuk' : 'Buat akun' }}</button>
      <button v-if="bolehDaftar" type="button" class="link" @click="mode = mode === 'masuk' ? 'daftar' : 'masuk'; msg = ''">
        {{ mode === 'masuk' ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk' }}
      </button>
    </form>
  </div>

  <template v-else>
    <header class="top">
      <div class="wrap bar">
        <div class="brand"><Mascot :size="36" /><span>Riyu Family</span></div>
        <nav aria-label="Menu utama">
          <button v-for="[k, l, d] in tabs" :key="k" :class="{ on: tab === k }" @click="tab = k">
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path :d="d" /></svg>
            <span>{{ l }}</span>
          </button>
        </nav>
        <div class="akun-aksi">
          <button class="icon-btn" title="Ganti kata sandi" aria-label="Ganti kata sandi" @click="sandi = true"><svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="15" r="4" /><path d="M10.85 12.15 19 4M18 5l2 2M15 8l2 2" /></svg></button>
          <button class="link light" @click="keluar">Keluar</button>
        </div>
      </div>
    </header>
    <div v-if="!online" class="offline" role="status">Kamu sedang offline. Perubahan baru bisa disimpan setelah tersambung.</div>
    <main class="wrap">
      <p v-if="db.loading && !db.transaksi.length" class="mute">Riyu sedang menghitung…</p>
      <Dashboard v-if="tab === 'ringkasan'" />
      <Transaksi v-else-if="tab === 'transaksi'" />
      <Tabungan v-else-if="tab === 'tabungan'" />
      <Master v-else />
    </main>
  </template>

  <Sandi v-if="session && sandi" @tutup="sandi = false" />

  <div class="toasts" aria-live="polite">
    <div v-for="t in ui.toasts" :key="t.id" :class="['toast', t.type]">{{ t.text }}</div>
  </div>
</template>
