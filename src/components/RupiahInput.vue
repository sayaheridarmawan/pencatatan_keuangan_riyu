<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: [Number, String], default: '' },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '0' },
})
const emit = defineEmits(['update:modelValue'])

const fmt = (n) =>
  n === '' || n === null || n === undefined || Number.isNaN(Number(n))
    ? ''
    : new Intl.NumberFormat('id-ID', { maximumFractionDigits: 0 }).format(Number(n))
const tampil = computed(() => fmt(props.modelValue))

// Ketik angka → tampil "1.500.000"; yang disimpan tetap angka murni (1500000)
function ketik(e) {
  const inp = e.target
  const sebelum = inp.value.slice(0, inp.selectionStart ?? inp.value.length).replace(/\D/g, '').length
  const digit = inp.value.replace(/\D/g, '').slice(0, 11)
  const val = digit === '' ? '' : Number(digit)
  emit('update:modelValue', val)
  const teks = fmt(val)
  inp.value = teks
  let pos = 0, hitung = 0
  while (pos < teks.length && hitung < sebelum) { if (/\d/.test(teks[pos])) hitung++; pos++ }
  inp.setSelectionRange(pos, pos)
}
</script>

<template>
  <label class="field">
    <span v-if="label">{{ label }}</span>
    <div class="rp-box">
      <i>Rp</i>
      <input type="text" inputmode="numeric" autocomplete="off" :aria-label="label || 'Jumlah rupiah'" :value="tampil" :placeholder="placeholder" @input="ketik" />
    </div>
  </label>
</template>
