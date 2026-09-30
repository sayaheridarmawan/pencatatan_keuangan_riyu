<script setup>
defineProps({ size: { type: Number, default: 64 } })
</script>
<template>
  <svg :width="size" :height="size" viewBox="0 0 100 100" role="img" aria-label="Riyu">
    <path d="M17 42 L13 9 L42 27Z" fill="#FF9147" />
    <path d="M83 42 L87 9 L58 27Z" fill="#FF9147" />
    <path d="M21 36 L19 18 L34 28Z" fill="#FFD3B0" />
    <path d="M79 36 L81 18 L66 28Z" fill="#FFD3B0" />
    <circle cx="50" cy="57" r="37" fill="#FFAA66" />
    <ellipse cx="50" cy="70" rx="23" ry="17" fill="#FFF4E6" />
    <circle cx="36" cy="53" r="5.2" fill="#2A2058" />
    <circle cx="64" cy="53" r="5.2" fill="#2A2058" />
    <circle cx="37.7" cy="51.2" r="1.7" fill="#fff" />
    <circle cx="65.7" cy="51.2" r="1.7" fill="#fff" />
    <ellipse cx="25" cy="65" rx="5.5" ry="3.4" fill="#FF7E9A" opacity=".65" />
    <ellipse cx="75" cy="65" rx="5.5" ry="3.4" fill="#FF7E9A" opacity=".65" />
    <ellipse cx="50" cy="62" rx="3.2" ry="2.4" fill="#2A2058" />
    <path d="M43.5 68 Q50 75 56.5 68" stroke="#2A2058" stroke-width="2.8" fill="none" stroke-linecap="round" />
    <circle cx="50" cy="33" r="8.5" fill="#FFD666" stroke="#E0A526" stroke-width="2" />
    <text x="50" y="36.6" text-anchor="middle" font-size="9.5" font-weight="800" fill="#9A6A0B" font-family="sans-serif">Rp</text>
  </svg>
</template>
