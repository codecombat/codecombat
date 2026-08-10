/**
 * detect.js -- hand-rolled page-quadrilateral detection.
 *
 * Pipeline, per frame:
 *   1. grayscale, downscale to ~320px on the long side, light Gaussian blur
 *   2. build several binary masks (Otsu, percentile sweep, illumination-
 *      flattened Otsu, plus the inverted polarity for dark-page-on-light)
 *   3. per mask: morphological open, largest connected blob, convex hull,
 *      collapse the hull to 4 circumscribing corners
 *   4. refine each of the 4 edges by walking the local intensity gradient,
 *      robustly fitting a line to the found edge points, and re-intersecting
 *   5. score every candidate on edge support / edge straightness / area /
 *      corner angles, and keep the winner
 *
 * Step 4 is what makes this accurate: the mask only has to be roughly right,
 * because the corners come from sub-pixel line fits, not from the blob outline.
 */

import {
  grayFromImage, gaussBlur, sobel, otsuThreshold,
  percentileThreshold, flattenIllumination, threshold, open, largestComponent,
} from './imageops.js'
import {
  convexHull, reduceHullToQuad, orderQuad, polygonArea, quadAngles, isConvex,
  fitLine, lineDistance, lineThrough, intersectLines, dist,
} from './geom.js'

const DEFAULTS = {
  workingSize: 320,
  blurSigma: 1.2,
  searchRadius: 10,
  samplesPerEdge: 40,
  minAreaFraction: 0.06,
  minAngle: 45,
  maxAngle: 135,
  openLevels: [1, 3],
  // Stop sweeping thresholds once a candidate is this convincing, and only pay
  // for the straight-edge search when the best candidate is below the second.
  earlyExitScore: 0.97,
  lineSearchScore: 0.9,
  fillsFrameCoverage: 0.3,
  lineSearchBlobs: 3,
  lineTolerance: 1.7,
  maxLines: 6,
  ransacIterations: 220,
}

/** Unit inward normal of edge a->b for a quad with the given centroid. */
function inwardNormal (a, b, centroid) {
  const dx = b.x - a.x
  const dy = b.y - a.y
  const len = Math.hypot(dx, dy) || 1
  let nx = -dy / len
  let ny = dx / len
  const mx = (a.x + b.x) / 2
  const my = (a.y + b.y) / 2
  if ((centroid.x - mx) * nx + (centroid.y - my) * ny < 0) { nx = -nx; ny = -ny }
  return { x: nx, y: ny }
}

function sampleField (field, w, h, x, y) {
  const x0 = Math.min(w - 1, Math.max(0, Math.floor(x)))
  const y0 = Math.min(h - 1, Math.max(0, Math.floor(y)))
  const x1 = Math.min(w - 1, x0 + 1)
  const y1 = Math.min(h - 1, y0 + 1)
  const fx = x - x0
  const fy = y - y0
  return field[y0 * w + x0] * (1 - fx) * (1 - fy) +
         field[y0 * w + x1] * fx * (1 - fy) +
         field[y1 * w + x0] * (1 - fx) * fy +
         field[y1 * w + x1] * fx * fy
}

/**
 * One refinement pass: walk each edge's normal looking for the intensity step
 * of the expected polarity, then fit a line through the hits.
 *
 * The search is weighted by a Gaussian centred on the current edge estimate.
 * Without that prior the strongest step near a page border is often *printed
 * content* -- a title bar or a border rule a few millimetres inside the paper
 * has far more contrast than paper-against-table -- and the fit slides inward.
 * The blob outline is already accurate to a couple of pixels, so trusting it
 * as a prior and only letting the gradient nudge the line is much steadier.
 *
 * Returns { quad, edgeSupport, straightness } or null.
 */
function refinePass (quad, grads, polarity, R, priorSigma, maxSamples) {
  const { gx, gy, width: w, height: h } = grads
  const cx = (quad[0].x + quad[1].x + quad[2].x + quad[3].x) / 4
  const cy = (quad[0].y + quad[1].y + quad[2].y + quad[3].y) / 4
  const centroid = { x: cx, y: cy }
  const lines = []
  const supports = []
  const straightnesses = []
  const twoSigmaSq = 2 * priorSigma * priorSigma

  const deriv = (px, py, n, o) => {
    const sx = px + n.x * o
    const sy = py + n.y * o
    if (sx < 1 || sy < 1 || sx > w - 2 || sy > h - 2) return 0
    return polarity * (sampleField(gx, w, h, sx, sy) * n.x + sampleField(gy, w, h, sx, sy) * n.y)
  }

  for (let e = 0; e < 4; e++) {
    const a = quad[e]
    const b = quad[(e + 1) % 4]
    const n = inwardNormal(a, b, centroid)
    const len = dist(a, b)
    const count = Math.max(8, Math.min(maxSamples, Math.round(len / 2)))
    const hits = []
    let supportSum = 0
    for (let s = 0; s < count; s++) {
      const t = 0.06 + 0.88 * (s / (count - 1))
      const px = a.x + (b.x - a.x) * t
      const py = a.y + (b.y - a.y) * t
      let bestScore = -Infinity
      let bestVal = 0
      let bestOff = 0
      for (let o = -R; o <= R; o += 0.5) {
        const dd = deriv(px, py, n, o)
        if (dd <= 0) continue
        const sc = dd * Math.exp(-(o * o) / twoSigmaSq)
        if (sc > bestScore) { bestScore = sc; bestVal = dd; bestOff = o }
      }
      if (bestVal < 2.5) continue
      // Parabolic sub-pixel peak from the neighbours of the winning offset.
      const vm = deriv(px, py, n, bestOff - 0.5)
      const vp = deriv(px, py, n, bestOff + 0.5)
      const denom = vm - 2 * bestVal + vp
      const shift = Math.abs(denom) > 1e-6 ? 0.25 * (vm - vp) / denom : 0
      const off = bestOff + Math.max(-0.5, Math.min(0.5, shift))
      hits.push({ x: px + n.x * off, y: py + n.y * off })
      supportSum += bestVal
    }
    if (hits.length < 6) return null

    // Robust fit: two rounds of trimming the worst residuals.
    let line = fitLine(hits)
    if (!line) return null
    let keep = hits
    for (let round = 0; round < 2; round++) {
      const withRes = keep.map(p => ({ p, r: lineDistance(line, p) })).sort((u, v) => u.r - v.r)
      keep = withRes.slice(0, Math.max(5, Math.round(withRes.length * 0.75))).map(o => o.p)
      line = fitLine(keep) || line
    }
    const residuals = keep.map(p => lineDistance(line, p)).sort((u, v) => u - v)
    const median = residuals[Math.floor(residuals.length / 2)]
    lines.push(line)
    supports.push(supportSum / hits.length)
    straightnesses.push(Math.exp(-median / 1.2) * (hits.length / count))
  }

  const corners = []
  for (let i = 0; i < 4; i++) {
    const p = intersectLines(lines[(i + 3) % 4], lines[i])
    if (!p || !isFinite(p.x) || !isFinite(p.y)) return null
    corners.push(p)
  }
  return {
    quad: corners,
    edgeSupport: supports.reduce((a, b) => a + b, 0) / 4,
    straightness: straightnesses.reduce((a, b) => a + b, 0) / 4,
  }
}

/**
 * Iterated edge refinement. Each pass re-centres on the previous estimate with
 * a tighter search window, so the lines converge onto the paper boundary
 * without ever being able to jump to high-contrast content further inside.
 */
function refineQuad (quad, grads, polarity, opts) {
  const diag = Math.hypot(grads.width, grads.height)
  let cur = quad
  let best = null
  for (const factor of [1, 0.6, 0.4]) {
    const R = Math.max(2.5, opts.searchRadius * factor)
    const pass = refinePass(cur, grads, polarity, R, R / 2.5, opts.samplesPerEdge)
    if (!pass) break
    // Reject a pass that ran away (near-parallel lines, mostly-missing hits).
    let ran = false
    for (let i = 0; i < 4; i++) {
      if (dist(pass.quad[i], quad[i]) > diag * 0.12) ran = true
    }
    if (ran) break
    cur = pass.quad
    best = pass
  }
  return best ? { ...best, quad: cur } : null
}

/**
 * Measure how much image evidence actually sits on a quad's edges, without
 * moving them. Every candidate is scored through this, refined or not, so the
 * comparison between candidates is apples to apples.
 *
 * `support` is the mean strength of the intensity step found on the edge;
 * `straightness` falls off when the hits scatter away from the edge line,
 * which is what exposes a quad that cuts across background clutter.
 */
function measureEdges (quad, grads, polarity, maxSamples) {
  const { gx, gy, width: w, height: h } = grads
  const cx = (quad[0].x + quad[1].x + quad[2].x + quad[3].x) / 4
  const cy = (quad[0].y + quad[1].y + quad[2].y + quad[3].y) / 4
  const centroid = { x: cx, y: cy }
  const R = 2.5
  let supportSum = 0
  let straightSum = 0
  let worstEdge = Infinity

  for (let e = 0; e < 4; e++) {
    const a = quad[e]
    const b = quad[(e + 1) % 4]
    const n = inwardNormal(a, b, centroid)
    const line = lineThrough(a, b)
    const len = dist(a, b)
    const count = Math.max(8, Math.min(maxSamples, Math.round(len / 2)))
    let found = 0
    let sum = 0
    const residuals = []
    for (let s = 0; s < count; s++) {
      const t = 0.06 + 0.88 * (s / (count - 1))
      const px = a.x + (b.x - a.x) * t
      const py = a.y + (b.y - a.y) * t
      let bestVal = 0
      let bestOff = 0
      for (let o = -R; o <= R; o += 0.5) {
        const sx = px + n.x * o
        const sy = py + n.y * o
        if (sx < 1 || sy < 1 || sx > w - 2 || sy > h - 2) continue
        const dd = polarity * (sampleField(gx, w, h, sx, sy) * n.x + sampleField(gy, w, h, sx, sy) * n.y)
        if (dd > bestVal) { bestVal = dd; bestOff = o }
      }
      if (bestVal < 2.5) { residuals.push(R + 1); continue }
      found++
      sum += bestVal
      residuals.push(Math.abs(lineDistance(line, { x: px + n.x * bestOff, y: py + n.y * bestOff })))
    }
    residuals.sort((u, v) => u - v)
    const median = residuals.length ? residuals[Math.floor(residuals.length / 2)] : R + 1
    const edgeSupport = found ? sum / count : 0
    const edgeStraight = Math.exp(-median / 1.2) * (found / count)
    supportSum += edgeSupport
    straightSum += edgeStraight
    // Per-edge quality, kept separately: see minEdgeQuality below.
    worstEdge = Math.min(worstEdge, Math.min(1, edgeSupport / 18) * edgeStraight)
  }
  return {
    edgeSupport: supportSum / 4,
    straightness: straightSum / 4,
    // The weakest of the four edges. Averaging hides exactly the case that
    // matters here: a hand gripping one edge leaves three perfect edges and one
    // bad one, which still averages high enough to look trustworthy. A page is
    // only truly located when *every* edge is backed by the image.
    minEdgeQuality: worstEdge,
  }
}

function scoreQuad (quad, w, h, edgeSupport, straightness, opts) {
  if (!isConvex(quad)) return 0
  const area = Math.abs(polygonArea(quad))
  const areaFrac = area / (w * h)
  if (areaFrac < opts.minAreaFraction || areaFrac > 1.6) return 0
  const angles = quadAngles(quad)
  for (const a of angles) {
    if (a < opts.minAngle || a > opts.maxAngle) return 0
  }
  // Opposite sides of a rectangle stay similar in length under mild perspective.
  const sides = [dist(quad[0], quad[1]), dist(quad[1], quad[2]), dist(quad[2], quad[3]), dist(quad[3], quad[0])]
  const ratioA = Math.min(sides[0], sides[2]) / Math.max(sides[0], sides[2])
  const ratioB = Math.min(sides[1], sides[3]) / Math.max(sides[1], sides[3])
  const shape = Math.min(1, (ratioA * ratioB + 0.35))
  const areaScore = 0.35 + 0.65 * Math.min(1, areaFrac / 0.45)
  const supportScore = Math.min(1, edgeSupport / 18)
  return supportScore * straightness * areaScore * shape
}

/**
 * Find the dominant straight lines in a set of blob-boundary points by
 * repeated RANSAC, removing each line's inliers before searching for the next.
 *
 * This is what rescues the case where the page is touching or overlapping
 * another sheet: thresholding merges them into one blob, and a circumscribing
 * hull-to-quad fit then bulges out to swallow the intruder. The page's own
 * edges are still the *longest straight runs* on that merged boundary, so
 * fitting lines finds them and ignores the appendage.
 */
function dominantLines (points, opts) {
  const step = Math.max(1, Math.ceil(points.length / 700))
  const pts = step === 1 ? points.slice() : points.filter((_, i) => i % step === 0)
  if (pts.length < 40) return []
  let minX = Infinity; let minY = Infinity; let maxX = -Infinity; let maxY = -Infinity
  for (const p of pts) {
    if (p.x < minX) minX = p.x
    if (p.x > maxX) maxX = p.x
    if (p.y < minY) minY = p.y
    if (p.y > maxY) maxY = p.y
  }
  const diag = Math.hypot(maxX - minX, maxY - minY)
  const minSep = diag * 0.15
  const tol = opts.lineTolerance
  // A straight run of length L contributes about L/step sampled points, so the
  // inlier floor has to be expressed in the subsampled pool's units.
  const minInliers = Math.max(14, Math.round(diag * 0.25 / step))

  // A cheap deterministic PRNG keeps detection reproducible frame to frame.
  let seed = 0x2f6e2b1 ^ pts.length
  const rnd = () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0
    return seed / 4294967296
  }

  const lines = []
  let pool = pts
  for (let round = 0; round < opts.maxLines && pool.length >= minInliers; round++) {
    let bestLine = null
    let bestCount = 0
    for (let it = 0; it < opts.ransacIterations; it++) {
      const a = pool[(rnd() * pool.length) | 0]
      const b = pool[(rnd() * pool.length) | 0]
      if (dist(a, b) < minSep) continue
      const line = lineThrough(a, b)
      let count = 0
      for (let i = 0; i < pool.length; i++) {
        if (lineDistance(line, pool[i]) < tol) count++
      }
      if (count > bestCount) { bestCount = count; bestLine = line }
    }
    if (!bestLine || bestCount < minInliers) break
    const inliers = pool.filter(p => lineDistance(bestLine, p) < tol)
    const refit = fitLine(inliers) || bestLine
    // Span matters more than raw count: a long edge beats a dense short one.
    let lo = Infinity
    let hi = -Infinity
    const dx = -refit.b
    const dy = refit.a
    for (const p of inliers) {
      const t = p.x * dx + p.y * dy
      if (t < lo) lo = t
      if (t > hi) hi = t
    }
    lines.push({ line: refit, count: inliers.length, span: hi - lo })
    pool = pool.filter(p => lineDistance(refit, p) >= tol * 1.6)
  }
  return lines.sort((a, b) => b.span - a.span)
}

/** Circular difference between two line-normal angles, in radians (0..PI/2). */
function angleDelta (l1, l2) {
  const a1 = Math.atan2(l1.a, l1.b)
  const a2 = Math.atan2(l2.a, l2.b)
  let d = Math.abs(a1 - a2) % Math.PI
  if (d > Math.PI / 2) d = Math.PI - d
  return d
}

/**
 * Build quads from pairs of near-parallel lines: two lines from each of the
 * two orientation families, intersected crosswise.
 */
function quadsFromLines (found, w, h) {
  if (found.length < 4) return []
  const top = found.slice(0, 6)
  const famA = []
  const famB = []
  for (const entry of top) {
    if (!famA.length || angleDelta(famA[0].line, entry.line) < 0.61) famA.push(entry)
    else famB.push(entry)
  }
  if (famA.length < 2 || famB.length < 2) return []
  const quads = []
  const pick = (arr) => arr.slice(0, 3)
  const A = pick(famA)
  const B = pick(famB)
  for (let i = 0; i < A.length; i++) {
    for (let j = i + 1; j < A.length; j++) {
      for (let k = 0; k < B.length; k++) {
        for (let l = k + 1; l < B.length; l++) {
          const corners = []
          let ok = true
          for (const p of [A[i], A[j]]) {
            for (const q of [B[k], B[l]]) {
              const c = intersectLines(p.line, q.line)
              if (!c || !isFinite(c.x) || !isFinite(c.y) ||
                  c.x < -w * 0.6 || c.x > w * 1.6 || c.y < -h * 0.6 || c.y > h * 1.6) { ok = false } else corners.push(c)
            }
          }
          if (!ok || corners.length !== 4) continue
          const quad = orderQuad(corners)
          if (!isConvex(quad)) continue
          quads.push(quad)
        }
      }
    }
  }
  return quads
}

function quadsSimilar (a, b, tol) {
  for (let i = 0; i < 4; i++) if (dist(a[i], b[i]) > tol) return false
  return true
}

/**
 * @param {{data: Uint8ClampedArray, width: number, height: number}} img RGBA frame
 * @returns {{quad, quadNormalized, score, touchesBorder, workingSize, candidates}|null}
 *          quad corners are in the input image's pixel coordinates, ordered
 *          TL, TR, BR, BL.
 */
export function detectQuad (img, options = {}) {
  const opts = { ...DEFAULTS, ...options }
  const { gray: small, scale } = grayFromImage(img, opts.workingSize)
  const blurred = gaussBlur(small, opts.blurSigma)
  const grads = sobel(blurred)
  const w = blurred.width
  const h = blurred.height

  const otsu = otsuThreshold(blurred)
  const flat = flattenIllumination(blurred)
  const otsuFlat = otsuThreshold(flat)
  const sources = [
    { gray: blurred, t: otsu, bright: true, tag: 'otsu' },
    { gray: blurred, t: otsu - 14, bright: true, tag: 'otsu-14' },
    { gray: blurred, t: otsu + 14, bright: true, tag: 'otsu+14' },
    { gray: blurred, t: percentileThreshold(blurred, 0.35), bright: true, tag: 'p35' },
    { gray: blurred, t: percentileThreshold(blurred, 0.55), bright: true, tag: 'p55' },
    { gray: flat, t: otsuFlat, bright: true, tag: 'flat-otsu' },
    { gray: flat, t: otsuFlat - 10, bright: true, tag: 'flat-otsu-10' },
    { gray: blurred, t: otsu, bright: false, tag: 'otsu-dark' },
  ]

  const candidates = []
  /**
   * Score a candidate and file it. Returns the *confidence* -- how strongly the
   * image backs these particular edges -- which is deliberately separate from
   * the ranking score. The score also folds in shape plausibility, and a page
   * seen at a steep angle is legitimately less rectangular, so ranking by score
   * but stopping early on confidence keeps skewed pages from being re-searched
   * to no purpose.
   */
  const consider = (quad, rough, polarity, tag, refined, touchesBorder) => {
    const ordered = orderQuad(quad)
    const m = measureEdges(ordered, grads, polarity, opts.samplesPerEdge)
    const score = scoreQuad(ordered, w, h, m.edgeSupport, m.straightness, opts)
    if (score <= 0) return 0
    const confidence = m.minEdgeQuality
    const dup = candidates.find(c => quadsSimilar(c.quad, ordered, 2.5))
    if (dup) {
      if (score > dup.score) { dup.score = score; dup.quad = ordered; dup.tag = tag; dup.refined = refined }
      return confidence
    }
    candidates.push({ quad: ordered, rough, score, confidence, tag, refined, touchesBorder })
    return confidence
  }

  const blobs = []
  let bestConfidence = 0
  let fillsFrame = false
  const rawMasks = new Map()

  // Cheap openings for every threshold first, stronger (and pricier) openings
  // only if nothing convincing turned up. A clean shot of paper on a contrasting
  // surface is settled by the first source or two, so most frames stop early.
  for (const level of opts.openLevels) {
    for (const src of sources) {
      let raw = rawMasks.get(src.tag)
      if (!raw) { raw = threshold(src.gray, src.t, src.bright); rawMasks.set(src.tag, raw) }
      const polarity = src.bright ? 1 : -1
      const mask = open(raw, level)
      const comp = largestComponent(mask)
      if (!comp) continue
      // A bright region reaching all four frame edges means no page border is
      // visible anywhere -- either the sheet overruns the viewport, or it is
      // indistinguishable from the surface under it. Either way the quad that
      // comes back will be some printed box inside the page, so flag it.
      if (src.bright && comp.coverage > opts.fillsFrameCoverage &&
          comp.sides.left && comp.sides.right && comp.sides.top && comp.sides.bottom) {
        fillsFrame = true
      }
      if (comp.size < w * h * opts.minAreaFraction * 0.6) continue
      const hull = convexHull(comp.points)
      if (hull.length < 4) continue
      const rough = reduceHullToQuad(hull)
      if (!rough) continue
      const ordered = orderQuad(rough)
      const tag = level === 1 ? src.tag : `${src.tag}/o${level}`
      const refined = refineQuad(ordered, grads, polarity, opts)
      // Keep both the refined and the raw blob quad as competing candidates:
      // refinement usually wins, but it can be dragged by printed content.
      const refConf = refined
        ? consider(refined.quad, ordered, polarity, tag, true, comp.touchesBorder)
        : 0
      const rawConf = consider(ordered, ordered, polarity, `${tag}=raw`, false, comp.touchesBorder)
      blobs.push({ comp, polarity, tag, confidence: Math.max(refConf, rawConf) })
      bestConfidence = Math.max(bestConfidence, refConf, rawConf)
      if (bestConfidence >= opts.earlyExitScore) break
    }
    if (bestConfidence >= opts.earlyExitScore) break
  }

  // Straight-edge pass, for blobs that swallowed something they should not
  // have. Only worth its cost when no threshold produced a convincing quad.
  if (bestConfidence < opts.lineSearchScore) {
    blobs.sort((a, b) => b.confidence - a.confidence)
    for (const blob of blobs.slice(0, opts.lineSearchBlobs)) {
      const lines = dominantLines(blob.comp.boundary, opts)
      for (const quad of quadsFromLines(lines, w, h)) {
        const refined = refineQuad(quad, grads, blob.polarity, opts)
        if (refined) consider(refined.quad, quad, blob.polarity, `${blob.tag}/lines`, true, blob.comp.touchesBorder)
        consider(quad, quad, blob.polarity, `${blob.tag}/lines=raw`, false, blob.comp.touchesBorder)
      }
    }
  }

  if (!candidates.length) return null
  candidates.sort((a, b) => b.score - a.score)
  const best = candidates[0]
  const inv = 1 / scale
  // Working-grid index -> input-image continuous coordinate. Working pixel X
  // covers input span [X*inv, (X+1)*inv), so its centre sits at (X+0.5)*inv;
  // dropping that half-pixel biases every corner up and to the left.
  const toInput = p => ({ x: (p.x + 0.5) * inv, y: (p.y + 0.5) * inv })
  const quad = best.quad.map(toInput)
  // Corners at or past the frame edge mean the page is cropped by the viewport.
  const margin = 0.004
  const clipped = quad.some(p =>
    p.x < img.width * margin || p.x > img.width * (1 - margin) ||
    p.y < img.height * margin || p.y > img.height * (1 - margin))
  return {
    quad,
    quadNormalized: quad.map(p => ({ x: p.x / img.width, y: p.y / img.height })),
    score: best.score,
    // How strongly the image backs these edges (step strength x straightness),
    // independent of shape plausibility. Auto-capture gates on this: "the
    // outline stopped moving" is not the same as "the outline is right".
    confidence: best.confidence ?? 0,
    areaFraction: Math.abs(polygonArea(best.quad)) / (w * h),
    tag: best.tag,
    refined: best.refined,
    touchesBorder: best.touchesBorder,
    clipped,
    fillsFrame,
    workingSize: { width: w, height: h },
    candidates: candidates.map(c => ({
      tag: c.tag,
      score: c.score,
      quad: c.quad.map(toInput),
      rough: c.rough.map(toInput),
    })),
  }
}

/** Internals exposed for the test harness only. */
export const __debug = { dominantLines, quadsFromLines, measureEdges, refineQuad, scoreQuad, DEFAULTS }

/**
 * Snap a user-dragged quad onto nearby image edges. Used by the manual corner
 * handles so hand placement still lands on the true paper boundary.
 */
export function snapQuad (img, quad, options = {}) {
  // A wider search than live detection uses: this runs once, on demand, from a
  // hand-placed quad that may be several percent of the frame off. Measured on
  // the synthetic suite, radius 22 is never worse than a tighter search and is
  // markedly better once the hand placement is more than ~3% off.
  const opts = { ...DEFAULTS, searchRadius: 22, ...options }
  const { gray: small, scale } = grayFromImage(img, opts.workingSize)
  const blurred = gaussBlur(small, opts.blurSigma)
  const grads = sobel(blurred)
  const inv = 1 / scale
  const scaled = orderQuad(quad.map(p => ({ x: p.x / inv - 0.5, y: p.y / inv - 0.5 })))
  const refined = refineQuad(scaled, grads, 1, opts)
  if (!refined) return null
  return orderQuad(refined.quad.map(p => ({ x: (p.x + 0.5) * inv, y: (p.y + 0.5) * inv })))
}

/**
 * Fires once the detected quad has held still long enough.
 * Corners are also exponentially smoothed so the overlay does not jitter.
 */
export class QuadTracker {
  constructor (options = {}) {
    this.stableMs = options.stableMs ?? 1000
    this.tolFraction = options.tolFraction ?? 0.02
    this.minFrames = options.minFrames ?? 5
    this.smoothing = options.smoothing ?? 0.45
    this.reset()
  }

  reset () {
    this.smoothed = null
    this.stableSince = null
    this.frames = 0
    this.lastSeen = 0
  }

  /**
   * @param {Array|null} quad detected corners, or null when nothing was found
   * @param {number} now timestamp in ms
   * @param {number} frameDiag diagonal of the frame in the same units as quad
   */
  update (quad, now, frameDiag) {
    if (!quad) {
      // Tolerate a couple of dropped frames before giving up on stability.
      if (this.lastSeen && now - this.lastSeen < 400) {
        return { quad: this.smoothed, stable: false, progress: 0 }
      }
      this.reset()
      return { quad: null, stable: false, progress: 0 }
    }
    this.lastSeen = now
    const tol = frameDiag * this.tolFraction
    if (!this.smoothed) {
      this.smoothed = quad.map(p => ({ ...p }))
      this.stableSince = now
      this.frames = 1
      return { quad: this.smoothed, stable: false, progress: 0 }
    }
    let moved = 0
    for (let i = 0; i < 4; i++) moved = Math.max(moved, dist(quad[i], this.smoothed[i]))
    const k = this.smoothing
    this.smoothed = this.smoothed.map((p, i) => ({
      x: p.x + (quad[i].x - p.x) * k,
      y: p.y + (quad[i].y - p.y) * k,
    }))
    if (moved > tol) {
      this.stableSince = now
      this.frames = 1
    } else {
      this.frames++
    }
    const held = now - this.stableSince
    const stable = held >= this.stableMs && this.frames >= this.minFrames
    return {
      quad: this.smoothed,
      stable,
      progress: Math.min(1, held / this.stableMs),
    }
  }
}
