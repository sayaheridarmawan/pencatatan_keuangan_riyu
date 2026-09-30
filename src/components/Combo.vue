<script setup>
import { ref, computed, nextTick } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  options: { type: Array, default: () => [] }, // [{ id, nama }]
  label: { type: String, default: '' },
  clearable: { type: Boolean, default: true },
  placeholder: { type: String, default: 'Cari…' },
})
const emit = defineEmits(['update:modelValue'])

const uid = 'cb' + Math.random().toString(36).slice(2, 8)
const el = ref(null)
const buka = ref(false), q = ref(''), aktif = ref(0)

const terpilih = computed(() => props.options.find((o) => o.id === props.modelValue))
const hasil = computed(() => {
  const k = q.value.trim().toLowerCase()
  if (!k) return props.options
  const awal = [], isi = []
  props.options.forEach((o) => {
    const n = o.nama.toLowerCase()
    if (n.startsWith(k)) awal.push(o)
    else if (n.includes(k)) isi.push(o)
  })
  return [...awal, ...isi]
})
const tampil = computed(() => (buka.value ? q.value : terpilih.value?.nama || ''))

function fokus() {
  buka.value = true; q.value = ''; aktif.value = 0
  // di HP: tunggu papan ketik muncul, lalu geser kolom ke tengah layar
  setTimeout(() => el.value?.scrollIntoView({ block: 'center', behavior: 'smooth' }), 300)
}
function ketik(e) { q.value = e.target.value; buka.value = true; aktif.value = 0 }
function tutup() { buka.value = false; q.value = '' }
function pilih(o) { emit('update:modelValue', o.id); tutup(); el.value?.blur() }
function kosongkan() { emit('update:modelValue', ''); nextTick(() => el.value?.focus()) }
function gulir() { nextTick(() => document.getElementById(`${uid}-${aktif.value}`)?.scrollIntoView({ block: 'nearest' })) }
function tombol(e) {
  if (e.key === 'ArrowDown') { e.preventDefault(); buka.value = true; aktif.value = Math.min(aktif.value + 1, hasil.value.length - 1); gulir() }
  else if (e.key === 'ArrowUp') { e.preventDefault(); aktif.value = Math.max(aktif.value - 1, 0); gulir() }
  else if (e.key === 'Enter' && buka.value && hasil.value[aktif.value]) { e.preventDefault(); pilih(hasil.value[aktif.value]) }
  else if (e.key === 'Escape') tutup()
}
</script>

<template>
  <div class="field">
    <span v-if="label">{{ label }}</span>
    <div class="combo-box">
      <input
        ref="el" type="text" role="combobox" autocomplete="off" autocapitalize="off" spellcheck="false"
        :aria-expanded="buka" :aria-controls="uid" aria-autocomplete="list"
        :placeholder="placeholder" :value="tampil" :aria-label="label || placeholder" maxlength="60"
        @focus="fokus" @input="ketik" @keydown="tombol" @blur="tutup"
      />
      <button v-if="clearable && modelValue && !buka" type="button" class="combo-x" aria-label="Kosongkan pilihan" @mousedown.prevent="kosongkan">×</button>
      <ul v-if="buka" :id="uid" class="combo-list" role="listbox">
        <li
          v-for="(o, i) in hasil" :id="`${uid}-${i}`" :key="o.id" role="option"
          :aria-selected="o.id === modelValue"
          :class="{ aktif: i === aktif, dipilih: o.id === modelValue }"
          @mousedown.prevent="pilih(o)" @mousemove="aktif = i"
        >{{ o.nama }}</li>
        <li v-if="!hasil.length" class="kosong">Tidak ditemukan</li>
      </ul>
    </div>
  </div>
</template>
