<script setup>
defineProps({ size: { type: Number, default: 64 } })
</script>
<template>
  <img src="/riyu.webp" :width="size" :height="size" alt="Riyu" class="mascot" />
</template>
