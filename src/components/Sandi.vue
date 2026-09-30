<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase'
import { notify, pesanError } from '../store'
import { sisaBlokir, gagalLimiter, resetLimiter } from '../limiter'
import PasswordInput from './PasswordInput.vue'

const emit = defineEmits(['tutup'])
const lama = ref(''), baru = ref(''), ulang = ref(''), err = ref(''), busy = ref(false)

async function simpan() {
  err.value = ''
  const tunggu = sisaBlokir('sandi')
  if (tunggu) { err.value = `Terlalu banyak percobaan. Coba lagi dalam ${tunggu} detik.`; return }
  if (baru.value.length < 8 || !/[A-Za-z]/.test(baru.value) || !/\d/.test(baru.value)) {
    err.value = 'Kata sandi baru minimal 8 karakter dan mengandung huruf serta angka.'; return
  }
  if (baru.value !== ulang.value) { err.value = 'Konfirmasi kata sandi tidak sama.'; return }
  if (baru.value === lama.value) { err.value = 'Kata sandi baru harus berbeda dari yang lama.'; return }
  busy.value = true
  try {
    const { data } = await supabase.auth.getUser()
    const { error: e1 } = await supabase.auth.signInWithPassword({ email: data.user.email, password: lama.value })
    if (e1) { gagalLimiter('sandi', { maks: 3 }); throw new Error('Kata sandi lama salah.') }
    const { error: e2 } = await supabase.auth.updateUser({ password: baru.value })
    if (e2) throw e2
    resetLimiter('sandi')
    notify('Kata sandi berhasil diganti')
    emit('tutup')
  } catch (e) { err.value = pesanError(e) }
  busy.value = false
}
</script>

<template>
  <div class="overlay" @click.self="emit('tutup')">
    <form class="modal login" @submit.prevent="simpan">
      <h3>Ganti kata sandi</h3>
      <PasswordInput v-model="lama" label="Kata sandi lama" autocomplete="current-password" />
      <PasswordInput v-model="baru" label="Kata sandi baru" autocomplete="new-password" :minlength="8" />
      <PasswordInput v-model="ulang" label="Ulangi kata sandi baru" autocomplete="new-password" :minlength="8" />
      <p class="mute small">Minimal 8 karakter, gabungan huruf dan angka.</p>
      <p v-if="err" class="err" role="alert">{{ err }}</p>
      <div class="actions">
        <button type="button" class="btn" @click="emit('tutup')">Batal</button>
        <button class="btn primary" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan' }}</button>
      </div>
    </form>
  </div>
</template>
