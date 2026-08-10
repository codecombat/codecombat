/**
 * imageops.js -- grayscale / blur / gradient / threshold primitives.
 *
 * Everything works on plain objects shaped like ImageData
 * ({ data: Uint8ClampedArray RGBA, width, height }) or on Gray buffers
 * ({ data: Float32Array, width, height }), so Node and the browser share code.
 */

/**
 * RGBA -> downscaled grayscale in a single box-filtered pass.
 * Detection never needs the full-resolution gray, and doing this in one step
 * rather than toGray()+downscaleGray() saves a full-frame intermediate.
 *
 * @returns {{gray, scale}} scale converts input pixels to working pixels
 */
export function grayFromImage (img, maxDim) {
  const { width, height, data } = img
  const longest = Math.max(width, height)
  const factor = Math.min(1, maxDim / longest)
  const w = Math.max(1, Math.round(width * factor))
  const h = Math.max(1, Math.round(height * factor))
  const out = new Float32Array(w * h)
  const sx = width / w
  const sy = height / h
  for (let y = 0; y < h; y++) {
    const y0 = Math.floor(y * sy)
    const y1 = Math.min(height, Math.max(y0 + 1, Math.floor((y + 1) * sy)))
    for (let x = 0; x < w; x++) {
      const x0 = Math.floor(x * sx)
      const x1 = Math.min(width, Math.max(x0 + 1, Math.floor((x + 1) * sx)))
      let sum = 0
      let n = 0
      for (let yy = y0; yy < y1; yy++) {
        let p = (yy * width + x0) * 4
        for (let xx = x0; xx < x1; xx++, p += 4) {
          sum += 0.299 * data[p] + 0.587 * data[p + 1] + 0.114 * data[p + 2]
          n++
        }
      }
      out[y * w + x] = sum / n
    }
  }
  return { gray: { data: out, width: w, height: h }, scale: w / width }
}

export function toGray (img) {
  const { width, height, data } = img
  const out = new Float32Array(width * height)
  for (let i = 0, p = 0; i < out.length; i++, p += 4) {
    out[i] = 0.299 * data[p] + 0.587 * data[p + 1] + 0.114 * data[p + 2]
  }
  return { data: out, width, height }
}

/** Box-average downscale so the longest side is at most maxDim. Returns {gray, scale}. */
export function downscaleGray (gray, maxDim) {
  const { width, height } = gray
  const longest = Math.max(width, height)
  if (longest <= maxDim) return { gray, scale: 1 }
  const scale = maxDim / longest
  const w = Math.max(1, Math.round(width * scale))
  const h = Math.max(1, Math.round(height * scale))
  const out = new Float32Array(w * h)
  const sx = width / w
  const sy = height / h
  for (let y = 0; y < h; y++) {
    const y0 = Math.floor(y * sy)
    const y1 = Math.min(height, Math.max(y0 + 1, Math.floor((y + 1) * sy)))
    for (let x = 0; x < w; x++) {
      const x0 = Math.floor(x * sx)
      const x1 = Math.min(width, Math.max(x0 + 1, Math.floor((x + 1) * sx)))
      let sum = 0
      let n = 0
      for (let yy = y0; yy < y1; yy++) {
        const row = yy * width
        for (let xx = x0; xx < x1; xx++) { sum += gray.data[row + xx]; n++ }
      }
      out[y * w + x] = sum / n
    }
  }
  return { gray: { data: out, width: w, height: h }, scale: w / width }
}

function gaussKernel (sigma) {
  const r = Math.max(1, Math.ceil(sigma * 3))
  const k = new Float32Array(2 * r + 1)
  let sum = 0
  for (let i = -r; i <= r; i++) {
    const v = Math.exp(-(i * i) / (2 * sigma * sigma))
    k[i + r] = v
    sum += v
  }
  for (let i = 0; i < k.length; i++) k[i] /= sum
  return { k, r }
}

export function gaussBlur (gray, sigma) {
  const { width: w, height: h, data } = gray
  const { k, r } = gaussKernel(sigma)
  const tmp = new Float32Array(w * h)
  const out = new Float32Array(w * h)
  for (let y = 0; y < h; y++) {
    const row = y * w
    for (let x = 0; x < w; x++) {
      let s = 0
      for (let i = -r; i <= r; i++) {
        const xx = Math.min(w - 1, Math.max(0, x + i))
        s += data[row + xx] * k[i + r]
      }
      tmp[row + x] = s
    }
  }
  for (let x = 0; x < w; x++) {
    for (let y = 0; y < h; y++) {
      let s = 0
      for (let i = -r; i <= r; i++) {
        const yy = Math.min(h - 1, Math.max(0, y + i))
        s += tmp[yy * w + x] * k[i + r]
      }
      out[y * w + x] = s
    }
  }
  return { data: out, width: w, height: h }
}

/** Constant-time box blur via a summed-area table. radius is in pixels. */
export function boxBlur (gray, radius) {
  const { width: w, height: h, data } = gray
  const sat = new Float64Array((w + 1) * (h + 1))
  for (let y = 0; y < h; y++) {
    let rowSum = 0
    for (let x = 0; x < w; x++) {
      rowSum += data[y * w + x]
      sat[(y + 1) * (w + 1) + (x + 1)] = sat[y * (w + 1) + (x + 1)] + rowSum
    }
  }
  const out = new Float32Array(w * h)
  for (let y = 0; y < h; y++) {
    const y0 = Math.max(0, y - radius)
    const y1 = Math.min(h - 1, y + radius)
    for (let x = 0; x < w; x++) {
      const x0 = Math.max(0, x - radius)
      const x1 = Math.min(w - 1, x + radius)
      const area = (x1 - x0 + 1) * (y1 - y0 + 1)
      const s = sat[(y1 + 1) * (w + 1) + (x1 + 1)] -
                sat[y0 * (w + 1) + (x1 + 1)] -
                sat[(y1 + 1) * (w + 1) + x0] +
                sat[y0 * (w + 1) + x0]
      out[y * w + x] = s / area
    }
  }
  return { data: out, width: w, height: h }
}

/** Sobel derivatives, scaled to approximate intensity change per pixel. */
export function sobel (gray) {
  const { width: w, height: h, data } = gray
  const gx = new Float32Array(w * h)
  const gy = new Float32Array(w * h)
  for (let y = 1; y < h - 1; y++) {
    for (let x = 1; x < w - 1; x++) {
      const i = y * w + x
      const tl = data[i - w - 1]; const tc = data[i - w]; const tr = data[i - w + 1]
      const ml = data[i - 1]; const mr = data[i + 1]
      const bl = data[i + w - 1]; const bc = data[i + w]; const br = data[i + w + 1]
      gx[i] = ((tr + 2 * mr + br) - (tl + 2 * ml + bl)) / 8
      gy[i] = ((bl + 2 * bc + br) - (tl + 2 * tc + tr)) / 8
    }
  }
  return { gx, gy, width: w, height: h }
}

export function histogram (gray, bins = 256) {
  const hist = new Float64Array(bins)
  const d = gray.data
  for (let i = 0; i < d.length; i++) {
    let v = Math.round(d[i])
    if (v < 0) v = 0
    if (v > bins - 1) v = bins - 1
    hist[v]++
  }
  return hist
}

/** Otsu's between-class-variance threshold on a 0..255 gray buffer. */
export function otsuThreshold (gray) {
  const hist = histogram(gray)
  const total = gray.data.length
  let sum = 0
  for (let i = 0; i < 256; i++) sum += i * hist[i]
  let sumB = 0
  let wB = 0
  let best = 0
  let bestVar = -1
  for (let t = 0; t < 256; t++) {
    wB += hist[t]
    if (wB === 0) continue
    const wF = total - wB
    if (wF === 0) break
    sumB += t * hist[t]
    const mB = sumB / wB
    const mF = (sum - sumB) / wF
    const between = wB * wF * (mB - mF) * (mB - mF)
    if (between > bestVar) { bestVar = between; best = t }
  }
  return best
}

/** Gray value at the given percentile (0..1). */
export function percentileThreshold (gray, p) {
  const hist = histogram(gray)
  const target = gray.data.length * p
  let acc = 0
  for (let i = 0; i < 256; i++) {
    acc += hist[i]
    if (acc >= target) return i
  }
  return 255
}

/**
 * Illumination-flattened copy: divide by a heavily blurred version so a smooth
 * lighting gradient cancels out while paper-vs-table contrast survives.
 */
export function flattenIllumination (gray) {
  const radius = Math.max(8, Math.round(Math.max(gray.width, gray.height) / 4))
  const bg = boxBlur(gray, radius)
  const out = new Float32Array(gray.data.length)
  for (let i = 0; i < out.length; i++) {
    out[i] = Math.min(255, Math.max(0, (gray.data[i] / Math.max(1, bg.data[i])) * 128))
  }
  return { data: out, width: gray.width, height: gray.height }
}

/** mask[i] = 1 where (bright ? value > t : value < t). */
export function threshold (gray, t, bright = true) {
  const out = new Uint8Array(gray.data.length)
  const d = gray.data
  if (bright) {
    for (let i = 0; i < d.length; i++) out[i] = d[i] > t ? 1 : 0
  } else {
    for (let i = 0; i < d.length; i++) out[i] = d[i] < t ? 1 : 0
  }
  return { data: out, width: gray.width, height: gray.height }
}

/**
 * Separable morphology with a square structuring element. A square min/max is
 * separable, so this is exact and much cheaper than the 2D neighbourhood scan
 * (2*(2r+1) samples per pixel instead of (2r+1)^2) -- which matters because the
 * detector runs this once per threshold candidate, per frame.
 */
function morph (mask, radius, isErode) {
  const { width: w, height: h } = mask
  const src = mask.data
  const tmp = new Uint8Array(w * h)
  const out = new Uint8Array(w * h)
  for (let y = 0; y < h; y++) {
    const row = y * w
    for (let x = 0; x < w; x++) {
      let v = isErode ? 1 : 0
      for (let d = -radius; d <= radius; d++) {
        const xx = Math.min(w - 1, Math.max(0, x + d))
        const s = src[row + xx]
        if (isErode) { if (!s) { v = 0; break } } else if (s) { v = 1; break }
      }
      tmp[row + x] = v
    }
  }
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      let v = isErode ? 1 : 0
      for (let d = -radius; d <= radius; d++) {
        const yy = Math.min(h - 1, Math.max(0, y + d))
        const s = tmp[yy * w + x]
        if (isErode) { if (!s) { v = 0; break } } else if (s) { v = 1; break }
      }
      out[y * w + x] = v
    }
  }
  return { data: out, width: w, height: h }
}

export const erode = (mask, n = 1) => morph(mask, n, true)
export const dilate = (mask, n = 1) => morph(mask, n, false)
/** Opening: knock out thin bridges between the page and bright background junk. */
export const open = (mask, n = 1) => (n <= 0 ? mask : dilate(erode(mask, n), n))

/**
 * Largest 4-connected blob of set pixels.
 *
 * `points` holds only the leftmost/rightmost pixel of each row: the convex hull
 * of those is identical to the hull of the whole blob, at a fraction of the
 * cost. `boundary` holds every pixel with a neighbour outside the blob, which
 * is what the straight-edge search fits lines to.
 */
export function largestComponent (mask) {
  const { width: w, height: h, data } = mask
  const labels = new Int32Array(w * h).fill(-1)
  const stack = new Int32Array(w * h)
  let bestSize = 0
  let bestLabel = -1
  let label = 0
  for (let start = 0; start < data.length; start++) {
    if (!data[start] || labels[start] >= 0) continue
    let sp = 0
    stack[sp++] = start
    labels[start] = label
    let size = 0
    while (sp > 0) {
      const i = stack[--sp]
      size++
      const x = i % w
      const y = (i / w) | 0
      if (x > 0 && data[i - 1] && labels[i - 1] < 0) { labels[i - 1] = label; stack[sp++] = i - 1 }
      if (x < w - 1 && data[i + 1] && labels[i + 1] < 0) { labels[i + 1] = label; stack[sp++] = i + 1 }
      if (y > 0 && data[i - w] && labels[i - w] < 0) { labels[i - w] = label; stack[sp++] = i - w }
      if (y < h - 1 && data[i + w] && labels[i + w] < 0) { labels[i + w] = label; stack[sp++] = i + w }
    }
    if (size > bestSize) { bestSize = size; bestLabel = label }
    label++
  }
  if (bestLabel < 0) return null

  // Fill holes: flood the background inward from the frame edge, then anything
  // still unvisited is enclosed by the blob. Printed text punches thousands of
  // little holes in the page mask, and their rims would otherwise swamp the
  // outer outline that the straight-edge search fits lines to.
  const filled = new Uint8Array(w * h)
  for (let i = 0; i < filled.length; i++) filled[i] = labels[i] === bestLabel ? 1 : 0
  const outside = new Uint8Array(w * h)
  let sp = 0
  const pushOut = (i) => { if (!filled[i] && !outside[i]) { outside[i] = 1; stack[sp++] = i } }
  for (let x = 0; x < w; x++) { pushOut(x); pushOut((h - 1) * w + x) }
  for (let y = 0; y < h; y++) { pushOut(y * w); pushOut(y * w + w - 1) }
  while (sp > 0) {
    const i = stack[--sp]
    const x = i % w
    const y = (i / w) | 0
    if (x > 0) pushOut(i - 1)
    if (x < w - 1) pushOut(i + 1)
    if (y > 0) pushOut(i - w)
    if (y < h - 1) pushOut(i + w)
  }
  for (let i = 0; i < filled.length; i++) if (!outside[i]) filled[i] = 1

  const pts = []
  const boundary = []
  let touchesBorder = false
  const sides = { left: false, right: false, top: false, bottom: false }
  let filledCount = 0
  for (let y = 0; y < h; y++) {
    let lo = -1
    let hi = -1
    const row = y * w
    const onFrameRow = y === 0 || y === h - 1
    for (let x = 0; x < w; x++) {
      const i = row + x
      if (!filled[i]) continue
      filledCount++
      if (lo < 0) lo = x
      hi = x
      if (x === 0) sides.left = true
      if (x === w - 1) sides.right = true
      if (y === 0) sides.top = true
      if (y === h - 1) sides.bottom = true
      // Skip pixels lying on the frame edge: a page running out of shot has an
      // apparent "edge" there that is the viewport, not the paper.
      if (onFrameRow || x === 0 || x === w - 1) continue
      if (!filled[i - 1] || !filled[i + 1] || !filled[i - w] || !filled[i + w]) {
        boundary.push({ x, y })
      }
    }
    if (lo < 0) continue
    if (lo === 0 || hi === w - 1 || onFrameRow) touchesBorder = true
    pts.push({ x: lo, y })
    if (hi !== lo) pts.push({ x: hi, y })
  }
  return {
    size: bestSize,
    points: pts,
    boundary,
    touchesBorder,
    sides,
    coverage: filledCount / (w * h),
  }
}

/** Bilinear sample of a gray buffer, clamped at the edges. */
export function sampleGray (gray, x, y) {
  const { width: w, height: h, data } = gray
  const x0 = Math.min(w - 1, Math.max(0, Math.floor(x)))
  const y0 = Math.min(h - 1, Math.max(0, Math.floor(y)))
  const x1 = Math.min(w - 1, x0 + 1)
  const y1 = Math.min(h - 1, y0 + 1)
  const fx = Math.min(1, Math.max(0, x - x0))
  const fy = Math.min(1, Math.max(0, y - y0))
  const a = data[y0 * w + x0]
  const b = data[y0 * w + x1]
  const c = data[y1 * w + x0]
  const d = data[y1 * w + x1]
  return a * (1 - fx) * (1 - fy) + b * fx * (1 - fy) + c * (1 - fx) * fy + d * fx * fy
}
