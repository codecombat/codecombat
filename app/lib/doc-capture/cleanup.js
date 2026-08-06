/**
 * cleanup.js -- making a rectified worksheet photo look like a scan.
 *
 * Two passes, both on the already-warped page so they can assume a flat sheet:
 *
 *   flattenPage()  divides out the lighting gradient, so the paper reads white
 *                  and pencil reads dark wherever the photo was taken.
 *   removeHands()  paints out fingers and thumbs holding the sheet down.
 *
 * Both are pure functions over ImageData-shaped `{width, height, data}` buffers
 * with no browser dependency, matching the rest of doc-capture.
 */
import { boxBlur } from './imageops.js'

const DEFAULTS = {
  // Mask work happens on a downscaled copy: a finger is centimetres wide, so
  // sub-millimetre mask precision buys nothing and costs a lot of time.
  maskMaxDim: 640,
  // A hand has to be a real chunk of the page, not a skin-coloured crayon mark.
  minAreaFraction: 0.0016,
  // ...but a thumb on a letter page is a few percent. Anything bigger is not a
  // hand: it is the desk, because the page corners were found in the wrong
  // place and the warp pulled the surroundings in. Painting that out turns a
  // recoverable bad crop into a destroyed worksheet.
  maxAreaFraction: 0.12,
  // Likewise in total. If this much of the "page" looks like skin, the page is
  // not what we think it is, and doing nothing is much safer than guessing.
  maxTotalAreaFraction: 0.22,
  // Fingers enter from outside, so only blobs that reach the paper's edge are
  // treated as hands. A face drawn in the middle of the sheet never qualifies.
  borderMarginFraction: 0.035,
  // How much of the page edge a blob must run along before it counts as a hand
  // rather than a drawing that reaches the margin.
  minBorderContactFraction: 0.05,
  // Grow the mask to swallow the shadow and the slightly-out-of-gamut fringe
  // around a finger, in units of the downscaled mask's smaller dimension.
  dilateFraction: 0.012,
  // The background estimate runs smaller still than the hand mask: it only has
  // to describe a smooth lighting gradient, and a smaller field keeps the
  // max-filter window wide relative to the drawing without costing anything.
  backgroundMaxDim: 224,
  // Wide enough that the window reaches past a solidly coloured drawing to the
  // paper around it.
  backgroundBlurFraction: 0.12,
  // Below this the "paper" is really a dark photo and flattening would only
  // amplify noise.
  minBackground: 24,
  // What counts as paper when trimming a rectified page back to the sheet.
  paperMinBrightness: 150,
  paperMaxSaturation: 0.28,
  paperLineShare: 0.6,
  // Corrections smaller than this are noise; larger than this mean the page was
  // not really found, and cropping on a bad guess is worse than leaving it.
  minTrimFraction: 0.004,
  maxTrimFraction: 0.09,
}

function clamp255 (v) {
  return v < 0 ? 0 : (v > 255 ? 255 : v)
}

/**
 * Classic skin-tone test: the RGB rule from Kovac et al. for daylight, ORed
 * with a YCbCr chroma box. Together they cover the range of skin tones and
 * camera white balances a phone produces indoors.
 */
export function isSkin (r, g, b) {
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)

  // Warm-lit white paper passes every clause of the classic skin rule — a sheet
  // photographed under a tungsten bulb sits around (245, 225, 205), which is
  // redder than green, redder than blue, and spread more than 15 apart. On a
  // corpus of real scans that made the paper itself the biggest "hand" on the
  // page. What separates them is that paper is bright *and* almost colourless,
  // while skin at that brightness still carries real chroma.
  const saturation = max === 0 ? 0 : (max - min) / max
  if (max > 235 && saturation < 0.25) return false

  const rgbRule = r > 95 && g > 40 && b > 20 && (max - min) > 15 &&
    Math.abs(r - g) > 15 && r > g && r > b
  const cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
  const cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
  const ycbcrRule = cb >= 77 && cb <= 130 && cr >= 133 && cr <= 178 && r > g && r > b
  return rgbRule || ycbcrRule
}

/**
 * Does this pixel look like something a child deliberately put on the page?
 *
 * Used to protect drawings from the margin of tolerance around a detected hand.
 * Anything strongly coloured, or dark enough to be pencil or marker, is treated
 * as a mark and never painted over — so a purple crayon line running right up
 * to the edge of the paper survives a thumb sitting next to it.
 */
export function isDrawnMark (r, g, b) {
  if (isSkin(r, g, b)) return false
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  const saturation = max === 0 ? 0 : (max - min) / max
  if (saturation > 0.3) return true // crayon, marker, coloured pencil
  return max < 95 // graphite and black marker, but not a soft grey shadow
}

/** Nearest-neighbour downscale of an RGBA buffer into a smaller RGBA buffer. */
function downscaleRGBA (img, maxDim) {
  const scale = Math.min(1, maxDim / Math.max(img.width, img.height))
  const w = Math.max(1, Math.round(img.width * scale))
  const h = Math.max(1, Math.round(img.height * scale))
  const data = new Uint8ClampedArray(w * h * 4)
  for (let y = 0; y < h; y++) {
    const sy = Math.min(img.height - 1, Math.floor((y + 0.5) / scale))
    for (let x = 0; x < w; x++) {
      const sx = Math.min(img.width - 1, Math.floor((x + 0.5) / scale))
      const si = (sy * img.width + sx) * 4
      const di = (y * w + x) * 4
      data[di] = img.data[si]
      data[di + 1] = img.data[si + 1]
      data[di + 2] = img.data[si + 2]
      data[di + 3] = 255
    }
  }
  return { width: w, height: h, data, scale }
}

/** Label 4-connected true runs, reporting size and whether each reaches a margin. */
function components (mask, width, height, borderMargin) {
  const labels = new Int32Array(width * height).fill(-1)
  const stack = new Int32Array(width * height)
  const found = []
  for (let start = 0; start < mask.length; start++) {
    if (!mask[start] || labels[start] !== -1) continue
    const id = found.length
    let top = 0
    stack[top++] = start
    labels[start] = id
    let size = 0
    let borderContact = 0
    const sides = { left: false, right: false, top: false, bottom: false }
    const pixels = []
    while (top > 0) {
      const p = stack[--top]
      const x = p % width
      const y = (p / width) | 0
      size++
      pixels.push(p)
      if (x <= borderMargin) { sides.left = true; borderContact++ } else if (x >= width - 1 - borderMargin) { sides.right = true; borderContact++ } else if (y <= borderMargin) { sides.top = true; borderContact++ } else if (y >= height - 1 - borderMargin) { sides.bottom = true; borderContact++ }
      if (x > 0 && mask[p - 1] && labels[p - 1] === -1) { labels[p - 1] = id; stack[top++] = p - 1 }
      if (x < width - 1 && mask[p + 1] && labels[p + 1] === -1) { labels[p + 1] = id; stack[top++] = p + 1 }
      if (y > 0 && mask[p - width] && labels[p - width] === -1) { labels[p - width] = id; stack[top++] = p - width }
      if (y < height - 1 && mask[p + width] && labels[p + width] === -1) { labels[p + width] = id; stack[top++] = p + width }
    }
    const sideCount = Object.values(sides).filter(Boolean).length
    found.push({ id, size, borderContact, sideCount, touchesBorder: borderContact > 0, pixels })
  }
  return found
}

/**
 * Separable max filter over a float field: the brightest value within `radius`.
 * Used to find the paper level underneath the drawing.
 */
function maxFilter (values, width, height, radius) {
  const tmp = new Float32Array(values.length)
  for (let y = 0; y < height; y++) {
    const row = y * width
    for (let x = 0; x < width; x++) {
      let best = -Infinity
      const from = Math.max(0, x - radius)
      const to = Math.min(width - 1, x + radius)
      for (let xx = from; xx <= to; xx++) if (values[row + xx] > best) best = values[row + xx]
      tmp[row + x] = best
    }
  }
  const out = new Float32Array(values.length)
  for (let x = 0; x < width; x++) {
    for (let y = 0; y < height; y++) {
      let best = -Infinity
      const from = Math.max(0, y - radius)
      const to = Math.min(height - 1, y + radius)
      for (let yy = from; yy <= to; yy++) if (tmp[yy * width + x] > best) best = tmp[yy * width + x]
      out[y * width + x] = best
    }
  }
  return out
}

/** Grow a boolean mask by `radius` using a separable two-pass max filter. */
function dilate (mask, width, height, radius) {
  if (radius < 1) return mask
  const tmp = new Uint8Array(mask.length)
  for (let y = 0; y < height; y++) {
    const row = y * width
    for (let x = 0; x < width; x++) {
      let on = 0
      for (let d = -radius; d <= radius && !on; d++) {
        const xx = x + d
        if (xx >= 0 && xx < width && mask[row + xx]) on = 1
      }
      tmp[row + x] = on
    }
  }
  const out = new Uint8Array(mask.length)
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      let on = 0
      for (let d = -radius; d <= radius && !on; d++) {
        const yy = y + d
        if (yy >= 0 && yy < height && tmp[yy * width + x]) on = 1
      }
      out[y * width + x] = on
    }
  }
  return out
}

/**
 * Even out the lighting across a photographed page.
 *
 * The page's own illumination is estimated with a wide box blur of the
 * brightest channel, then divided out. Paper goes uniformly white, pencil and
 * crayon keep their colour, and a shadow across one corner stops looking like
 * grey paper to whatever reads the sheet next.
 *
 * @returns {{width, height, data}} a new buffer; the input is not modified
 */
export function flattenPage (img, options = {}) {
  const opts = { ...DEFAULTS, ...options }
  const { width, height, data } = img
  const out = new Uint8ClampedArray(data.length)

  // The illumination estimate is built on a small copy and sampled back up: a
  // wide blur over the full 2200x1700 page would allocate tens of megabytes on
  // a phone for an identical result.
  const scale = Math.min(1, opts.backgroundMaxDim / Math.max(width, height))
  const bw = Math.max(1, Math.round(width * scale))
  const bh = Math.max(1, Math.round(height * scale))
  const luma = new Float32Array(bw * bh)
  for (let y = 0; y < bh; y++) {
    const sy = Math.min(height - 1, Math.floor((y + 0.5) / scale))
    for (let x = 0; x < bw; x++) {
      const sx = Math.min(width - 1, Math.floor((x + 0.5) / scale))
      const i = (sy * width + sx) * 4
      luma[y * bw + x] = Math.max(data[i], data[i + 1], data[i + 2])
    }
  }

  // Estimate the paper, not the average. A mean-based background is dragged
  // down by whatever is drawn on top of it, so a large block of colour ends up
  // dividing by its own darkness and is bleached away — which is exactly what
  // happens to a drawing a child has coloured in solidly. Taking a local
  // maximum first finds the paper showing between and around the marks, so the
  // gradient still goes but the marks keep their contrast.
  const radius = Math.max(2, Math.round(Math.min(bw, bh) * opts.backgroundBlurFraction))
  const paperLevel = maxFilter(luma, bw, bh, radius)
  const bg = boxBlur({ width: bw, height: bh, data: paperLevel }, radius).data

  for (let i = 0, p = 0; i < data.length; i += 4, p++) {
    const x = p % width
    const y = (p / width) | 0
    const bx = Math.min(bw - 1, (x * scale) | 0)
    const by = Math.min(bh - 1, (y * scale) | 0)
    const base = Math.max(opts.minBackground, bg[by * bw + bx])
    const gain = 255 / base
    out[i] = clamp255(data[i] * gain)
    out[i + 1] = clamp255(data[i + 1] * gain)
    out[i + 2] = clamp255(data[i + 2] * gain)
    out[i + 3] = 255
  }
  return { width, height, data: out }
}

/**
 * Paint out hands holding the page down.
 *
 * Only skin-coloured regions that are both large and connected to the edge of
 * the sheet are removed, so a child's crayon drawing of a person survives even
 * when it is exactly the same colour as the thumb in the corner. Removed areas
 * are filled with the paper colour sampled just outside the mask, which reads
 * as blank paper rather than as an obvious white patch.
 *
 * @returns {{image: {width, height, data}, removed: number}} removed is the
 *          fraction of the page that was painted out (0 when no hand was found)
 */
export function removeHands (img, options = {}) {
  const opts = { ...DEFAULTS, ...options }
  const small = downscaleRGBA(img, opts.maskMaxDim)
  const { width: mw, height: mh } = small
  const mask = new Uint8Array(mw * mh)

  for (let i = 0, p = 0; i < small.data.length; i += 4, p++) {
    if (isSkin(small.data[i], small.data[i + 1], small.data[i + 2])) mask[p] = 1
  }

  const borderMargin = Math.round(Math.min(mw, mh) * opts.borderMarginFraction)
  const minArea = mw * mh * opts.minAreaFraction
  // A hand enters the frame, so it meets the edge along a real span. A drawing
  // that merely runs out to the edge of the paper touches it at a few pixels.
  // Requiring a span rather than a touch is what tells a thumb from a child who
  // drew all the way to the margin.
  const minBorderContact = Math.max(4, Math.round(Math.min(mw, mh) * opts.minBorderContactFraction))
  const maxArea = mw * mh * opts.maxAreaFraction
  const keep = new Uint8Array(mw * mh)
  let kept = 0
  let oversized = false
  for (const comp of components(mask, mw, mh, borderMargin)) {
    if (comp.size < minArea) continue
    if (comp.borderContact < minBorderContact) continue
    // A blob running along three or four sides of the page is not a hand, it is
    // the surface the page is lying on, included because the detected corners
    // were a little outside the paper. Painting that frame out is not merely
    // pointless: grown inward by the tolerance halo it reaches over the title
    // and the name line.
    if (comp.sideCount >= 3) { oversized = true; continue }
    if (comp.size > maxArea) { oversized = true; continue }
    for (const p of comp.pixels) keep[p] = 1
    kept += comp.size
  }
  // Either guard tripping says the same thing: this is not a page with a hand
  // on it. Report it so the capture page can suggest checking the corners.
  const TOO_MUCH = 'a large area looked like skin — the page edges may be wrong'
  if (oversized || kept > mw * mh * opts.maxTotalAreaFraction) {
    return { image: img, removed: 0, skipped: TOO_MUCH }
  }
  if (!kept) return { image: img, removed: 0 }

  const grown = dilate(keep, mw, mh, Math.max(1, Math.round(Math.min(mw, mh) * opts.dilateFraction)))

  // Paper colour: the median-ish brightness of everything the mask did not
  // claim. Using the real page keeps the patch consistent with a warm photo.
  let sum = 0
  let count = 0
  for (let p = 0; p < grown.length; p++) {
    if (grown[p]) continue
    const i = p * 4
    const v = Math.max(small.data[i], small.data[i + 1], small.data[i + 2])
    if (v > 120) { sum += v; count++ }
  }
  const paper = count ? Math.round(sum / count) : 245

  const data = new Uint8ClampedArray(img.data)
  const sx = mw / img.width
  const sy = mh / img.height
  let removed = 0
  for (let y = 0; y < img.height; y++) {
    const my = Math.min(mh - 1, (y * sy) | 0)
    for (let x = 0; x < img.width; x++) {
      const mx = Math.min(mw - 1, (x * sx) | 0)
      const m = my * mw + mx
      if (!grown[m]) continue
      const i = (y * img.width + x) * 4
      // Inside the detected hand itself, paint unconditionally. In the halo of
      // tolerance grown around it — there to swallow the shadow and the fringe —
      // leave anything that looks drawn. Painting the whole halo flat is what
      // erased the end of a drawing that ran up against a finger.
      if (!keep[m] && isDrawnMark(data[i], data[i + 1], data[i + 2])) continue
      data[i] = paper
      data[i + 1] = paper
      data[i + 2] = paper
      data[i + 3] = 255
      removed++
    }
  }
  return { image: { width: img.width, height: img.height, data }, removed: removed / (img.width * img.height) }
}

/**
 * Crop a rectified page back to the paper.
 *
 * Detected corners land a little outside the sheet often enough to matter: the
 * warp then carries a band of whatever the page was lying on around one or two
 * edges. Measured over a corpus of real scans that band, not any hand, was the
 * biggest thing the cleanup pass was painting out — and painting it reached
 * inward over the title. Cropping it away first is both more honest and
 * cheaper, and it leaves the output still meaning "exactly the sheet", which
 * everything downstream assumes when it maps field percentages onto the page.
 *
 * Only small corrections are made. A large inset means the page was not found
 * at all, and guessing then is worse than doing nothing.
 *
 * @returns {{image, trimmed: number}} trimmed is the fraction of each edge
 *   removed, 0 when the page already filled the frame
 */
export function trimToPaper (img, options = {}) {
  const opts = { ...DEFAULTS, ...options }
  const small = downscaleRGBA(img, opts.backgroundMaxDim)
  const { width: w, height: h, data } = small

  // Paper is the bright, barely-coloured majority of a rectified worksheet.
  const paper = new Uint8Array(w * h)
  for (let i = 0, p = 0; i < data.length; i += 4, p++) {
    const max = Math.max(data[i], data[i + 1], data[i + 2])
    const min = Math.min(data[i], data[i + 1], data[i + 2])
    const saturation = max === 0 ? 0 : (max - min) / max
    if (max > opts.paperMinBrightness && saturation < opts.paperMaxSaturation) paper[p] = 1
  }

  // Rows and columns that are mostly paper. Working per line rather than per
  // component keeps this to an inset on each side, which is the only correction
  // that leaves the page a rectangle.
  const edge = (length, other, at) => {
    const solid = []
    for (let a = 0; a < length; a++) {
      let count = 0
      for (let b = 0; b < other; b++) count += paper[at(a, b)]
      solid.push(count / other >= opts.paperLineShare)
    }
    let lo = 0
    while (lo < length && !solid[lo]) lo++
    let hi = length - 1
    while (hi > lo && !solid[hi]) hi--
    return { lo, hi }
  }
  const cols = edge(w, h, (x, y) => y * w + x)
  const rows = edge(h, w, (y, x) => y * w + x)
  if (cols.hi <= cols.lo || rows.hi <= rows.lo) return { image: img, trimmed: 0 }

  const inset = Math.max(
    cols.lo / w, (w - 1 - cols.hi) / w,
    rows.lo / h, (h - 1 - rows.hi) / h,
  )
  if (inset < opts.minTrimFraction || inset > opts.maxTrimFraction) return { image: img, trimmed: 0 }

  // One inset all round keeps the aspect ratio, which the page's own 11:8.5 is.
  const dx = Math.round(inset * img.width)
  const dy = Math.round(inset * img.height)
  const srcW = img.width - 2 * dx
  const srcH = img.height - 2 * dy
  if (srcW < img.width * 0.7 || srcH < img.height * 0.7) return { image: img, trimmed: 0 }

  // Rescale back to the original size so the page still means the whole sheet.
  const out = new Uint8ClampedArray(img.data.length)
  for (let y = 0; y < img.height; y++) {
    const sy = Math.min(img.height - 1, dy + Math.round((y * srcH) / img.height))
    for (let x = 0; x < img.width; x++) {
      const sx = Math.min(img.width - 1, dx + Math.round((x * srcW) / img.width))
      const si = (sy * img.width + sx) * 4
      const di = (y * img.width + x) * 4
      out[di] = img.data[si]
      out[di + 1] = img.data[si + 1]
      out[di + 2] = img.data[si + 2]
      out[di + 3] = 255
    }
  }
  return { image: { width: img.width, height: img.height, data: out }, trimmed: inset }
}

/** flattenPage + removeHands, in the order that makes each work best. */
export function cleanPage (img, options = {}) {
  // Trim first: the surroundings carried in by a slightly oversized quad look
  // like a hand to the next step, and like uneven lighting to the one after.
  const trimResult = options.trim === false ? { image: img, trimmed: 0 } : trimToPaper(img, options)
  // Hands next: flattening amplifies a shadowed finger toward skin tone and
  // makes the mask messier, while removing it first leaves flat paper behind.
  const handsResult = options.removeHands === false
    ? { image: trimResult.image, removed: 0 }
    : removeHands(trimResult.image, options)
  const image = options.flatten === false ? handsResult.image : flattenPage(handsResult.image, options)
  return { image, handsRemoved: handsResult.removed, trimmed: trimResult.trimmed, skipped: handsResult.skipped }
}

export const __debug = { components, dilate, downscaleRGBA }
