/**
 * warp.js -- perspective rectification and percentage-based region cropping.
 * Pure math on ImageData-shaped buffers; no DOM.
 */

import { solveHomography, applyHomography, dist } from './geom.js'

/** Landscape US Letter at ~200 dpi. */
export const LETTER_LANDSCAPE = { width: 2200, height: 1700 }

/** Region percentages measured against the whole rectified page. */
export const FULL_PAGE_FRAME = { left: 0, top: 0, width: 1, height: 1 }

/**
 * Where a worksheet's field percentages actually live.
 *
 * Scenario inputs are absolutely positioned inside `.worksheet-inner-container`,
 * so `left/top/width/height` are percentages of THAT box -- not of the sheet.
 * The inner container is inset by the page margins on three sides and by the
 * margin plus the header band on top. Mirrors the SCSS constants in
 * app/components/common/elements/AIJuniorWorksheet.vue:
 *
 *   $paper-width: 11in;  $paper-height: 8.5in;
 *   $top/bottom/left/right-margin: 0.5in;  $header-height: 0.85in;
 *
 * Treating these percentages as fractions of the full page instead shifts every
 * crop up and left and oversizes it by ~10-28%.
 *
 * (The sheet's 4px printed border sits just outside the 11x8.5in content box,
 * about 0.04in -- 0.4% of the page. That is an order of magnitude below the
 * corrections here and is deliberately ignored.)
 */
export const WORKSHEET_GEOMETRY = {
  paperWidthIn: 11,
  paperHeightIn: 8.5,
  marginIn: 0.5,
  headerHeightIn: 0.85,
}

export const WORKSHEET_CONTENT_FRAME = (() => {
  const { paperWidthIn: w, paperHeightIn: h, marginIn: m, headerHeightIn: hdr } = WORKSHEET_GEOMETRY
  return {
    left: m / w,
    top: (m + hdr) / h,
    width: (w - 2 * m) / w,
    height: (h - 2 * m - hdr) / h,
  }
})()

function makeImage (width, height) {
  return { data: new Uint8ClampedArray(width * height * 4), width, height }
}

function bilinear (src, cx, cy, out) {
  const { width: w, height: h, data } = src
  // Continuous coordinates put pixel centres at (i + 0.5); shift to texel indices.
  const x = cx - 0.5
  const y = cy - 0.5
  const x0 = Math.floor(x)
  const y0 = Math.floor(y)
  const fx = x - x0
  const fy = y - y0
  const cx0 = Math.min(w - 1, Math.max(0, x0))
  const cy0 = Math.min(h - 1, Math.max(0, y0))
  const cx1 = Math.min(w - 1, Math.max(0, x0 + 1))
  const cy1 = Math.min(h - 1, Math.max(0, y0 + 1))
  const i00 = (cy0 * w + cx0) * 4
  const i10 = (cy0 * w + cx1) * 4
  const i01 = (cy1 * w + cx0) * 4
  const i11 = (cy1 * w + cx1) * 4
  const w00 = (1 - fx) * (1 - fy)
  const w10 = fx * (1 - fy)
  const w01 = (1 - fx) * fy
  const w11 = fx * fy
  for (let c = 0; c < 4; c++) {
    out[c] = data[i00 + c] * w00 + data[i10 + c] * w10 + data[i01 + c] * w01 + data[i11 + c] * w11
  }
}

/**
 * Rectify the quad region of `src` into a fresh outW x outH image.
 *
 * Works by solving the homography from the *destination* rectangle to the
 * source quad and inverse-mapping every output pixel, so there are no holes.
 * When the source region is much larger than the output (high-res photo, small
 * target) it supersamples to avoid aliasing.
 *
 * @param {{data: Uint8ClampedArray, width, height}} src
 * @param {Array<{x,y}>} quad TL, TR, BR, BL in src pixel coordinates
 */
export function warpQuad (src, quad, outW = LETTER_LANDSCAPE.width, outH = LETTER_LANDSCAPE.height) {
  const dstCorners = [
    { x: 0, y: 0 }, { x: outW, y: 0 }, { x: outW, y: outH }, { x: 0, y: outH },
  ]
  const H = solveHomography(dstCorners, quad)
  if (!H) return null
  const out = makeImage(outW, outH)
  const od = out.data

  // Estimate minification to decide on supersampling.
  const srcArea = Math.abs(
    (quad[1].x - quad[0].x) * (quad[3].y - quad[0].y) -
    (quad[3].x - quad[0].x) * (quad[1].y - quad[0].y),
  )
  const ratio = srcArea / (outW * outH)
  const ss = ratio > 2.2 ? 3 : (ratio > 1.1 ? 2 : 1)
  const px = new Float32Array(4)
  const acc = new Float32Array(4)

  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      acc[0] = acc[1] = acc[2] = acc[3] = 0
      for (let sy = 0; sy < ss; sy++) {
        for (let sx = 0; sx < ss; sx++) {
          const u = x + (sx + 0.5) / ss
          const v = y + (sy + 0.5) / ss
          const p = applyHomography(H, u, v)
          bilinear(src, p.x, p.y, px)
          acc[0] += px[0]; acc[1] += px[1]; acc[2] += px[2]; acc[3] += px[3]
        }
      }
      const n = ss * ss
      const o = (y * outW + x) * 4
      od[o] = acc[0] / n
      od[o + 1] = acc[1] / n
      od[o + 2] = acc[2] / n
      od[o + 3] = acc[3] / n
    }
  }
  return out
}

/**
 * Suggest an output size that preserves the page's real aspect ratio, capped
 * to maxDim. Useful when the page is not letter-shaped.
 */
export function suggestOutputSize (quad, maxDim = 2200) {
  const wTop = dist(quad[0], quad[1])
  const wBottom = dist(quad[3], quad[2])
  const hLeft = dist(quad[0], quad[3])
  const hRight = dist(quad[1], quad[2])
  const w = Math.max(wTop, wBottom)
  const h = Math.max(hLeft, hRight)
  const scale = maxDim / Math.max(w, h)
  return { width: Math.round(w * scale), height: Math.round(h * scale) }
}

/**
 * Crop scenario-style regions out of a rectified page.
 *
 * @param {{data, width, height}} page rectified page image
 * @param {Array<{id, left, top, width, height}>} regions all values are
 *        PERCENTAGES (0-100) of the frame named by `frame`
 * @param {{left, top, width, height}} frame the sub-rectangle of the page those
 *        percentages are relative to, as fractions of the page. Defaults to the
 *        whole page; worksheets want WORKSHEET_CONTENT_FRAME.
 * @returns {Array<{id, image, rect}>}
 */
export function cropRegions (page, regions, frame = FULL_PAGE_FRAME) {
  const out = []
  for (const r of regions) {
    const rect = regionToPixels(r, page.width, page.height, frame)
    if (rect.width < 1 || rect.height < 1) continue
    const img = makeImage(rect.width, rect.height)
    for (let y = 0; y < rect.height; y++) {
      const sy = rect.y + y
      if (sy < 0 || sy >= page.height) continue
      let si = (sy * page.width + rect.x) * 4
      let di = y * rect.width * 4
      for (let x = 0; x < rect.width; x++, si += 4, di += 4) {
        const sx = rect.x + x
        if (sx < 0 || sx >= page.width) continue
        img.data[di] = page.data[si]
        img.data[di + 1] = page.data[si + 1]
        img.data[di + 2] = page.data[si + 2]
        img.data[di + 3] = page.data[si + 3]
      }
    }
    out.push({ id: r.id, image: img, rect })
  }
  return out
}

export function regionToPixels (r, pageW, pageH, frame = FULL_PAGE_FRAME) {
  const fx = frame.left * pageW
  const fy = frame.top * pageH
  const fw = frame.width * pageW
  const fh = frame.height * pageH
  const x = Math.round(fx + (r.left / 100) * fw)
  const y = Math.round(fy + (r.top / 100) * fh)
  const width = Math.round((r.width / 100) * fw)
  const height = Math.round((r.height / 100) * fh)
  return {
    x: Math.max(0, Math.min(pageW - 1, x)),
    y: Math.max(0, Math.min(pageH - 1, y)),
    width: Math.max(1, Math.min(pageW - x, width)),
    height: Math.max(1, Math.min(pageH - y, height)),
  }
}
