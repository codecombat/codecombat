/**
 * geom.js -- small geometry + linear algebra helpers for document capture.
 * No DOM access and no dependencies, so this imports cleanly in Node and the browser.
 *
 * Points are plain {x, y} objects. Quads are arrays of 4 points ordered
 * top-left, top-right, bottom-right, bottom-left (clockwise in image
 * coordinates, where y grows downward).
 */

export function dist (a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y)
}

/** Signed area; positive means clockwise in image coordinates. */
export function polygonArea (pts) {
  let s = 0
  for (let i = 0; i < pts.length; i++) {
    const p = pts[i]
    const q = pts[(i + 1) % pts.length]
    s += p.x * q.y - q.x * p.y
  }
  return s / 2
}

/** Gaussian elimination with partial pivoting. Returns null if singular. */
export function solveLinear (A, b) {
  const n = b.length
  const M = A.map((row, i) => row.slice().concat(b[i]))
  for (let col = 0; col < n; col++) {
    let piv = col
    for (let r = col + 1; r < n; r++) {
      if (Math.abs(M[r][col]) > Math.abs(M[piv][col])) piv = r
    }
    if (Math.abs(M[piv][col]) < 1e-12) return null
    if (piv !== col) { const t = M[piv]; M[piv] = M[col]; M[col] = t }
    const d = M[col][col]
    for (let c = col; c <= n; c++) M[col][c] /= d
    for (let r = 0; r < n; r++) {
      if (r === col) continue
      const f = M[r][col]
      if (f === 0) continue
      for (let c = col; c <= n; c++) M[r][c] -= f * M[col][c]
    }
  }
  return M.map(row => row[n])
}

/**
 * Homography mapping the four src points onto the four dst points.
 * Returns a row-major 9-element array with h33 fixed at 1.
 */
export function solveHomography (src, dst) {
  const A = []
  const b = []
  for (let i = 0; i < 4; i++) {
    const { x, y } = src[i]
    const u = dst[i].x
    const v = dst[i].y
    A.push([x, y, 1, 0, 0, 0, -u * x, -u * y])
    b.push(u)
    A.push([0, 0, 0, x, y, 1, -v * x, -v * y])
    b.push(v)
  }
  const h = solveLinear(A, b)
  if (!h) return null
  return [h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7], 1]
}

export function applyHomography (H, x, y) {
  const w = H[6] * x + H[7] * y + H[8]
  if (Math.abs(w) < 1e-12) return { x: 0, y: 0 }
  return {
    x: (H[0] * x + H[1] * y + H[2]) / w,
    y: (H[3] * x + H[4] * y + H[5]) / w,
  }
}

export function invert3x3 (m) {
  const [a, b, c, d, e, f, g, h, i] = m
  const A = e * i - f * h
  const B = -(d * i - f * g)
  const C = d * h - e * g
  const det = a * A + b * B + c * C
  if (Math.abs(det) < 1e-12) return null
  const id = 1 / det
  return [
    A * id, (c * h - b * i) * id, (b * f - c * e) * id,
    B * id, (a * i - c * g) * id, (c * d - a * f) * id,
    C * id, (b * g - a * h) * id, (a * e - b * d) * id,
  ]
}

/**
 * Order four arbitrary points as TL, TR, BR, BL.
 * Sorts by angle about the centroid (giving a consistent ring), forces
 * clockwise winding, then rotates so the most top-left corner leads.
 */
export function orderQuad (pts) {
  const cx = (pts[0].x + pts[1].x + pts[2].x + pts[3].x) / 4
  const cy = (pts[0].y + pts[1].y + pts[2].y + pts[3].y) / 4
  const ring = pts.slice().sort(
    (p, q) => Math.atan2(p.y - cy, p.x - cx) - Math.atan2(q.y - cy, q.x - cx),
  )
  if (polygonArea(ring) < 0) ring.reverse()
  let best = 0
  let bestScore = Infinity
  for (let i = 0; i < 4; i++) {
    const s = ring[i].x + ring[i].y
    if (s < bestScore) { bestScore = s; best = i }
  }
  return [ring[best], ring[(best + 1) % 4], ring[(best + 2) % 4], ring[(best + 3) % 4]]
}

/** Interior angles of a quad, in degrees. */
export function quadAngles (quad) {
  const out = []
  for (let i = 0; i < 4; i++) {
    const p = quad[(i + 3) % 4]
    const c = quad[i]
    const n = quad[(i + 1) % 4]
    const a1 = Math.atan2(p.y - c.y, p.x - c.x)
    const a2 = Math.atan2(n.y - c.y, n.x - c.x)
    let d = Math.abs(a1 - a2) * 180 / Math.PI
    if (d > 180) d = 360 - d
    out.push(d)
  }
  return out
}

export function isConvex (pts) {
  let sign = 0
  const n = pts.length
  for (let i = 0; i < n; i++) {
    const a = pts[i]
    const b = pts[(i + 1) % n]
    const c = pts[(i + 2) % n]
    const cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
    if (Math.abs(cross) < 1e-9) continue
    const s = cross > 0 ? 1 : -1
    if (sign === 0) sign = s
    else if (s !== sign) return false
  }
  return sign !== 0
}

/** Line through two points as normalized {a, b, c} with a*x + b*y + c = 0. */
export function lineThrough (p, q) {
  const a = q.y - p.y
  const b = p.x - q.x
  const n = Math.hypot(a, b) || 1
  return { a: a / n, b: b / n, c: -(a * p.x + b * p.y) / n }
}

/** Total least squares line fit through >= 2 points. */
export function fitLine (pts) {
  const n = pts.length
  if (n < 2) return null
  let mx = 0
  let my = 0
  for (const p of pts) { mx += p.x; my += p.y }
  mx /= n
  my /= n
  let sxx = 0
  let syy = 0
  let sxy = 0
  for (const p of pts) {
    const dx = p.x - mx
    const dy = p.y - my
    sxx += dx * dx
    syy += dy * dy
    sxy += dx * dy
  }
  // Principal direction is the eigenvector of the scatter matrix with the
  // larger eigenvalue; the line normal is the perpendicular one.
  const theta = 0.5 * Math.atan2(2 * sxy, sxx - syy)
  const dx = Math.cos(theta)
  const dy = Math.sin(theta)
  const a = -dy
  const b = dx
  return { a, b, c: -(a * mx + b * my) }
}

export function lineDistance (line, p) {
  return Math.abs(line.a * p.x + line.b * p.y + line.c)
}

export function intersectLines (l1, l2) {
  const det = l1.a * l2.b - l2.a * l1.b
  if (Math.abs(det) < 1e-9) return null
  return {
    x: (l1.b * l2.c - l2.b * l1.c) / det,
    y: (l2.a * l1.c - l1.a * l2.c) / det,
  }
}

/** Andrew's monotone chain. Returns hull vertices, counter-clockwise in math coords. */
export function convexHull (points) {
  if (points.length < 3) return points.slice()
  const pts = points.slice().sort((p, q) => (p.x - q.x) || (p.y - q.y))
  const cross = (o, a, b) => (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
  const lower = []
  for (const p of pts) {
    while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) lower.pop()
    lower.push(p)
  }
  const upper = []
  for (let i = pts.length - 1; i >= 0; i--) {
    const p = pts[i]
    while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) upper.pop()
    upper.push(p)
  }
  lower.pop()
  upper.pop()
  return lower.concat(upper)
}

/**
 * Collapse a convex polygon down to its 4 best-fitting circumscribing corners.
 *
 * Repeatedly drops the vertex whose removal grows the polygon the least: the
 * two edges adjacent to it are extended until they meet, and that intersection
 * replaces it. This tolerates rounded/frayed paper corners far better than
 * picking the four extreme hull points.
 */
export function reduceHullToQuad (hull) {
  let poly = hull.slice()
  if (poly.length < 4) return null
  const triArea = (a, b, c) =>
    Math.abs((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) / 2

  while (poly.length > 4) {
    const n = poly.length
    let bestI = -1
    let bestCost = Infinity
    let bestPt = null
    for (let i = 0; i < n; i++) {
      // Drop edge (b, c) by extending its neighbouring edges until they meet.
      const a = poly[(i - 1 + n) % n]
      const b = poly[i]
      const c = poly[(i + 1) % n]
      const d = poly[(i + 2) % n]
      const p = intersectLines(lineThrough(a, b), lineThrough(c, d))
      if (!p || !isFinite(p.x) || !isFinite(p.y)) continue
      // The meeting point must lie beyond b and beyond c, otherwise the edges
      // converge inward and the "reduction" would eat into the polygon.
      const ab = { x: b.x - a.x, y: b.y - a.y }
      const dc = { x: c.x - d.x, y: c.y - d.y }
      const lab = ab.x * ab.x + ab.y * ab.y
      const ldc = dc.x * dc.x + dc.y * dc.y
      if (lab < 1e-9 || ldc < 1e-9) continue
      const t = ((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / lab
      const s = ((p.x - d.x) * dc.x + (p.y - d.y) * dc.y) / ldc
      if (t <= 1 || s <= 1) continue
      const cost = triArea(b, p, c)
      if (cost < bestCost) { bestCost = cost; bestI = i; bestPt = p }
    }
    if (bestI < 0) return null
    // Replace the two endpoints of the dropped edge with their meeting point.
    const drop = (bestI + 1) % n
    const next = []
    for (let i = 0; i < n; i++) {
      if (i === bestI) { next.push(bestPt); continue }
      if (i === drop) continue
      next.push(poly[i])
    }
    poly = next
  }
  return poly.length === 4 ? poly : null
}

/** Mean corner-to-corner distance between two quads, assumed same ordering. */
export function quadCornerError (a, b) {
  let sum = 0
  let max = 0
  for (let i = 0; i < 4; i++) {
    const d = dist(a[i], b[i])
    sum += d
    if (d > max) max = d
  }
  return { mean: sum / 4, max }
}
