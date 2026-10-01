<script setup>
import { ref, onMounted } from 'vue'
import { urlFile } from '../lampiran'
import { pesanError } from '../store'

const props = defineProps({ path: { type: String, required: true } })
const emit = defineEmits(['tutup'])
const url = ref(''), err = ref('')
const pdf = props.path.toLowerCase().endsWith('.pdf')

onMounted(async () => {
  try { url.value = await urlFile(props.path) } catch (e) { err.value = pesanError(e) }
})
</script>

<template>
  <div class="overlay" @click.self="emit('tutup')">
    <div class="modal" role="dialog" aria-modal="true">
      <div class="head"><h3>Lampiran</h3><button class="link" @click="emit('tutup')">Tutup</button></div>
      <p v-if="err" class="err" role="alert">{{ err }}</p>
      <p v-else-if="!url" class="mute">Memuat…</p>
      <template v-else>
        <img v-if="!pdf" :src="url" alt="Lampiran" class="lamp-full" />
        <a v-if="pdf" :href="url" target="_blank" rel="noopener noreferrer" class="btn primary">Buka PDF</a>
        <p v-else class="small"><a :href="url" target="_blank" rel="noopener noreferrer">Buka ukuran penuh</a></p>
      </template>
    </div>
  </div>
</template>
