<script setup>
import { ref } from 'vue'
defineProps({
  modelValue: { type: String, default: '' },
  label: { type: String, default: 'Kata sandi' },
  autocomplete: { type: String, default: 'current-password' },
  minlength: { type: Number, default: 1 },
})
defineEmits(['update:modelValue'])
const lihat = ref(false)
</script>

<template>
  <label class="field">
    <span>{{ label }}</span>
    <div class="pw-box">
      <input
        :type="lihat ? 'text' : 'password'" :value="modelValue" :autocomplete="autocomplete"
        :minlength="minlength" maxlength="72" required autocapitalize="off" spellcheck="false"
        @input="$emit('update:modelValue', $event.target.value)"
      />
      <button type="button" class="pw-eye" :aria-label="lihat ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'" :aria-pressed="lihat" @click="lihat = !lihat">
        <svg v-if="!lihat" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></svg>
        <svg v-else viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.9 17.9A10.9 10.9 0 0 1 12 19c-6.5 0-10-7-10-7a18.5 18.5 0 0 1 5.1-5.9M9.9 5.1A10.4 10.4 0 0 1 12 5c6.5 0 10 7 10 7a18.6 18.6 0 0 1-2.2 3.2M1 1l22 22M9.9 9.9a3 3 0 0 0 4.2 4.2" /></svg>
      </button>
    </div>
  </label>
</template>
