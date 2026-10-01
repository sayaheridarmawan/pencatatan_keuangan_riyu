import { supabase } from './supabase'

const BUCKET = 'lampiran'
const BATAS_AKHIR = 200 * 1024 // target ukuran gambar setelah dikompres

// Gambar → WebP maks 1280 px (turun kualitas bertahap sampai ≤ 200 KB). PDF dipakai apa adanya (maks 1 MB).
export async function kompres(file) {
  if (file.type === 'application/pdf') {
    if (file.size > 1024 * 1024) throw new Error('PDF maksimal 1 MB.')
    return { blob: file, ext: 'pdf', type: 'application/pdf' }
  }
  if (!file.type.startsWith('image/')) throw new Error('Format harus gambar (JPG, PNG, WebP) atau PDF.')
  if (file.size > 20 * 1024 * 1024) throw new Error('Ukuran file terlalu besar (maksimal 20 MB sebelum dikompres).')
  const bmp = await createImageBitmap(file, { imageOrientation: 'from-image' }).catch(() => {
    throw new Error('Gambar tidak bisa dibaca. Coba format JPG atau PNG.')
  })
  let skala = Math.min(1, 1280 / Math.max(bmp.width, bmp.height))
  let q = 0.72
  let hasil = null
  for (let i = 0; i < 6; i++) {
    const w = Math.max(1, Math.round(bmp.width * skala)), h = Math.max(1, Math.round(bmp.height * skala))
    const c = document.createElement('canvas')
    c.width = w; c.height = h
    c.getContext('2d').drawImage(bmp, 0, 0, w, h)
    let blob = await new Promise((r) => c.toBlob(r, 'image/webp', q))
    if (!blob || blob.type !== 'image/webp') blob = await new Promise((r) => c.toBlob(r, 'image/jpeg', q))
    hasil = blob
    if (blob && blob.size <= BATAS_AKHIR) break
    q = Math.max(0.4, q - 0.1); skala *= 0.85
  }
  bmp.close?.()
  if (!hasil) throw new Error('Gagal memproses gambar.')
  return { blob: hasil, ext: hasil.type === 'image/webp' ? 'webp' : 'jpg', type: hasil.type }
}

export async function unggah(blob, ext, type) {
  const { data } = await supabase.auth.getUser()
  const path = `${data.user.id}/${crypto.randomUUID()}.${ext}`
  const { error } = await supabase.storage.from(BUCKET).upload(path, blob, { contentType: type, upsert: false })
  if (error) throw error
  return path
}

export async function hapusFile(path) {
  if (!path) return
  try { await supabase.storage.from(BUCKET).remove([path]) } catch { /* sisa file tidak mengganggu */ }
}

export async function urlFile(path) {
  const { data, error } = await supabase.storage.from(BUCKET).createSignedUrl(path, 300)
  if (error) throw error
  return data.signedUrl
}
