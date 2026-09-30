<script setup>
import { computed } from 'vue'
import { db, rupiah, nama, terkumpul } from '../store'

const props = defineProps({ target: { type: Object, required: true } })
const emit = defineEmits(['tutup'])

const total = computed(() => terkumpul(props.target.id))
const persen = computed(() => Math.min(100, (total.value / props.target.target_jumlah) * 100))
const kurang = computed(() => Math.max(0, props.target.target_jumlah - total.value))

// Sumber dana = akun tempat dana target tersimpan saat ini (akun tujuan transfer / akun tempat disisihkan)
const sumber = computed(() => {
  const m = {}
  db.transfer
    .filter((x) => x.target_id === props.target.id)
    .forEach((x) => (m[x.akun_tujuan_id] = (m[x.akun_tujuan_id] || 0) + Number(x.jumlah)))
  return Object.entries(m)
    .map(([id, v]) => ({ id, v, pct: total.value ? (v / total.value) * 100 : 0 }))
    .sort((a, b) => b.v - a.v)
})
</script>

<template>
  <div class="overlay" @click.self="emit('tutup')">
    <div class="modal" role="dialog" aria-modal="true">
      <div class="head">
        <h3>{{ target.nama }}</h3>
        <button class="link" @click="emit('tutup')">Tutup</button>
      </div>
      <div class="num in">{{ rupiah(total) }}</div>
      <div class="mute small">dari {{ rupiah(target.target_jumlah) }} · {{ Math.floor(persen) }}%<template v-if="kurang"> · kurang {{ rupiah(kurang) }}</template><template v-else> · target tercapai 🎉</template></div>
      <div class="track" style="margin:.6rem 0 1rem"><i class="goal" :style="{ width: persen + '%' }"></i></div>

      <h3>Sumber dana</h3>
      <p v-if="!sumber.length" class="mute">Belum ada dana yang masuk ke target ini.</p>
      <div v-for="s in sumber" :key="s.id" class="bar-item">
        <div class="row"><span>{{ nama(db.akun, s.id) }}</span><b>{{ rupiah(s.v) }} <small class="mute">({{ Math.round(s.pct) }}%)</small></b></div>
        <div class="track"><i class="goal" :style="{ width: s.pct + '%' }"></i></div>
      </div>
    </div>
  </div>
</template>
