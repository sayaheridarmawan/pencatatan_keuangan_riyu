<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase'
import { notify, pesanError } from '../store'

const emit = defineEmits(['tutup'])
const lama = ref(''), baru = ref(''), ulang = ref(''), err = ref(''), busy = ref(false)

async function simpan() {
  err.value = ''
  if (baru.value.length < 6) { err.value = 'Kata sandi baru minimal 6 karakter.'; return }
  if (baru.value !== ulang.value) { err.value = 'Konfirmasi kata sandi tidak sama.'; return }
  if (baru.value === lama.value) { err.value = 'Kata sandi baru harus berbeda dari yang lama.'; return }
  busy.value = true
  try {
    const { data } = await supabase.auth.getUser()
    const { error: e1 } = await supabase.auth.signInWithPassword({ email: data.user.email, password: lama.value })
    if (e1) throw new Error('Kata sandi lama salah.')
    const { error: e2 } = await supabase.auth.updateUser({ password: baru.value })
    if (e2) throw e2
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
      <label>Kata sandi lama<input v-model="lama" type="password" required autocomplete="current-password" /></label>
      <label>Kata sandi baru<input v-model="baru" type="password" minlength="6" required autocomplete="new-password" /></label>
      <label>Ulangi kata sandi baru<input v-model="ulang" type="password" minlength="6" required autocomplete="new-password" /></label>
      <p v-if="err" class="err" role="alert">{{ err }}</p>
      <div class="actions">
        <button type="button" class="btn" @click="emit('tutup')">Batal</button>
        <button class="btn primary" :disabled="busy">{{ busy ? 'Menyimpan…' : 'Simpan' }}</button>
      </div>
    </form>
  </div>
</template>
