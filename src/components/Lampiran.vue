<script setup>
import { ref, onBeforeUnmount } from 'vue'
import { kompres } from '../lampiran'
import { notify, pesanError } from '../store'

// modelValue: { file: { blob, ext, type, nama, awal } | null, hapus: boolean }
const props = defineProps({ modelValue: { type: Object, required: true }, ada: { type: String, default: '' } })
const emit = defineEmits(['update:modelValue', 'lihat'])
const inp = ref(null), proses = ref(false), preview = ref('')

const kb = (n) => (n < 1048576 ? Math.max(1, Math.round(n / 1024)) + ' KB' : (n / 1048576).toFixed(1) + ' MB')
const lepas = () => { if (preview.value) URL.revokeObjectURL(preview.value); preview.value = '' }

async function pilih(e) {
  const f = e.target.files[0]
  e.target.value = ''
  if (!f) return
  proses.value = true
  try {
    const r = await kompres(f)
    lepas()
    preview.value = r.type.startsWith('image/') ? URL.createObjectURL(r.blob) : ''
    emit('update:modelValue', { file: { ...r, nama: f.name, awal: f.size }, hapus: false })
  } catch (err) { notify(pesanError(err), 'err') }
  proses.value = false
}
function buang() { lepas(); emit('update:modelValue', { file: null, hapus: !!props.ada }) }
onBeforeUnmount(lepas)
</script>

<template>
  <div class="field">
    <span>Lampiran (opsional)</span>
    <div v-if="modelValue.file" class="lamp-box">
      <img v-if="preview" :src="preview" alt="Pratinjau lampiran" class="lamp-thumb" />
      <span v-else class="lamp-thumb pdf">PDF</span>
      <div class="grow small">{{ modelValue.file.nama }}<br /><span class="mute">{{ kb(modelValue.file.awal) }} → {{ kb(modelValue.file.blob.size) }}</span></div>
      <button type="button" class="link danger" @click="buang">Hapus</button>
    </div>
    <div v-else-if="ada && !modelValue.hapus" class="lamp-box">
      <span class="mute small grow">Sudah ada lampiran</span>
      <button type="button" class="link" @click="emit('lihat', ada)">Lihat</button>
      <button type="button" class="link danger" @click="buang">Hapus</button>
    </div>
    <button type="button" class="btn" :disabled="proses" @click="inp.click()">
      {{ proses ? 'Memproses…' : modelValue.file || (ada && !modelValue.hapus) ? 'Ganti file' : 'Pilih foto atau PDF' }}
    </button>
    <input ref="inp" type="file" accept="image/*,application/pdf" hidden @change="pilih" />
  </div>
</template>
