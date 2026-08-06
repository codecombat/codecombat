/**
 * capture.js -- public API for real-time worksheet capture and straightening.
 *
 * Everything below the DOM helpers (detect.js, warp.js, geom.js, imageops.js)
 * is pure math on ImageData-shaped buffers with no browser dependency, so the
 * pipeline is testable in Node. This file is the only one that touches
 * `document`, `navigator` or `canvas`.
 *
 * Typical use:
 *
 *   const scanner = new DocumentScanner({
 *     video: videoEl,
 *     regions: [{ id: 'drawing', left: 6, top: 26, width: 42, height: 56 }],
 *     onUpdate: ({ quad, stable, progress }) => drawOverlay(quad, progress),
 *     onCapture: ({ dataUrl, regions }) => show(dataUrl, regions)
 *   })
 *   await scanner.start()
 */

import { detectQuad, snapQuad, QuadTracker } from './detect.js'
import {
  warpQuad, cropRegions, regionToPixels, suggestOutputSize, LETTER_LANDSCAPE,
  FULL_PAGE_FRAME, WORKSHEET_CONTENT_FRAME, WORKSHEET_GEOMETRY,
} from './warp.js'
import { orderQuad, dist } from './geom.js'
import { cleanPage } from './cleanup.js'
import { decodeQR, parseWorksheetQR } from './qr.js'

export {
  detectQuad, snapQuad, QuadTracker,
  warpQuad, cropRegions, regionToPixels, suggestOutputSize, LETTER_LANDSCAPE,
  FULL_PAGE_FRAME, WORKSHEET_CONTENT_FRAME, WORKSHEET_GEOMETRY,
  orderQuad, cleanPage, decodeQR, parseWorksheetQR,
}

// --------------------------------------------------------------------------
// Canvas helpers
// --------------------------------------------------------------------------

export function createCanvas (width, height) {
  const c = document.createElement('canvas')
  c.width = width
  c.height = height
  return c
}

export function imageDataToCanvas (img) {
  const canvas = createCanvas(img.width, img.height)
  const ctx = canvas.getContext('2d')
  const id = ctx.createImageData(img.width, img.height)
  id.data.set(img.data)
  ctx.putImageData(id, 0, 0)
  return canvas
}

/** Draw any drawable (video, image, canvas) into a fresh ImageData buffer. */
export function readFrame (source, width, height) {
  const canvas = createCanvas(width, height)
  const ctx = canvas.getContext('2d', { willReadFrequently: true })
  ctx.drawImage(source, 0, 0, width, height)
  return ctx.getImageData(0, 0, width, height)
}

/** Rectify a quad out of an ImageData and return a canvas. */
export function warpToCanvas (img, quad, outW = LETTER_LANDSCAPE.width, outH = LETTER_LANDSCAPE.height) {
  const warped = warpQuad(img, quad, outW, outH)
  if (!warped) return null
  return imageDataToCanvas(warped)
}

/**
 * Crop percentage-defined regions out of a rectified page.
 * @returns {Array<{id, canvas, dataUrl, rect}>}
 */
export function cropRegionsToCanvases (pageImageData, regions, frame = FULL_PAGE_FRAME, type = 'image/png') {
  return cropRegions(pageImageData, regions, frame).map(r => {
    const canvas = imageDataToCanvas(r.image)
    return { id: r.id, canvas, dataUrl: canvas.toDataURL(type), rect: r.rect }
  })
}

// --------------------------------------------------------------------------
// Overlay rendering
// --------------------------------------------------------------------------

const OVERLAY_DEFAULTS = {
  lineColor: '#3ddc84',
  searchColor: 'rgba(255,255,255,0.35)',
  fillColor: 'rgba(61,220,132,0.12)',
  handleColor: '#ffffff',
  handleRadius: 11,
  lineWidth: 3,
}

/**
 * Paint the detected page outline onto an overlay canvas.
 * `quad` is in normalized 0..1 coordinates so the caller never has to think
 * about the mismatch between detection resolution and display size.
 */
export function drawOverlay (ctx, quad, options = {}) {
  const o = { ...OVERLAY_DEFAULTS, ...options }
  const { width, height } = ctx.canvas
  ctx.clearRect(0, 0, width, height)
  if (!quad) return
  const pts = quad.map(p => ({ x: p.x * width, y: p.y * height }))

  ctx.save()
  ctx.beginPath()
  ctx.moveTo(pts[0].x, pts[0].y)
  for (let i = 1; i < 4; i++) ctx.lineTo(pts[i].x, pts[i].y)
  ctx.closePath()
  ctx.fillStyle = o.fillColor
  ctx.fill()
  ctx.lineJoin = 'round'
  ctx.lineWidth = o.lineWidth
  ctx.strokeStyle = o.stable ? o.lineColor : o.searchColor
  ctx.stroke()

  // Progress toward auto-capture: trace the outline clockwise as it fills.
  if (o.progress > 0 && o.progress < 1) {
    const total = pts.reduce((sum, p, i) => sum + dist(p, pts[(i + 1) % 4]), 0)
    let remaining = total * o.progress
    ctx.beginPath()
    ctx.moveTo(pts[0].x, pts[0].y)
    for (let i = 0; i < 4 && remaining > 0; i++) {
      const a = pts[i]
      const b = pts[(i + 1) % 4]
      const seg = dist(a, b)
      const t = Math.min(1, remaining / seg)
      ctx.lineTo(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
      remaining -= seg
    }
    ctx.strokeStyle = o.lineColor
    ctx.lineWidth = o.lineWidth + 5
    ctx.lineCap = 'round'
    ctx.shadowColor = o.lineColor
    ctx.shadowBlur = 12
    ctx.stroke()
    ctx.shadowBlur = 0
  }

  if (o.handles) {
    for (const p of pts) {
      ctx.beginPath()
      ctx.arc(p.x, p.y, o.handleRadius, 0, Math.PI * 2)
      ctx.fillStyle = o.handleColor
      ctx.fill()
      ctx.lineWidth = 3
      ctx.strokeStyle = o.lineColor
      ctx.stroke()
    }
  }
  ctx.restore()
}

/**
 * Turn the detector's self-reported trouble flags into a message, or null when
 * the frame looks trustworthy. Drives both the on-screen hint and the decision
 * to hold off on auto-capture.
 */
export function warningFor (result) {
  if (!result) return null
  if (result.fillsFrame) {
    return 'Can\u2019t see all four paper edges \u2014 move the camera back, or put the sheet on a darker surface.'
  }
  if (result.clipped || result.touchesBorder) {
    return 'The page runs past the edge of the frame \u2014 move the camera back.'
  }
  return null
}

/** Index of the corner nearest to a normalized point, or -1 if none is close. */
export function pickCorner (quad, point, tolerance = 0.06) {
  let best = -1
  let bestD = tolerance
  for (let i = 0; i < 4; i++) {
    const d = Math.hypot(quad[i].x - point.x, quad[i].y - point.y)
    if (d < bestD) { bestD = d; best = i }
  }
  return best
}

// --------------------------------------------------------------------------
// Scanner
// --------------------------------------------------------------------------

/**
 * Camera session: opens the stream, runs detection on a throttled loop, tracks
 * stability, and rectifies on capture.
 *
 * Detection runs on a downscaled copy of the frame (detectSize) while capture
 * always rectifies from the full-resolution frame, so preview cost stays low
 * without giving up output quality.
 */
export class DocumentScanner {
  constructor (options = {}) {
    this.video = options.video
    // 640 rather than 480: corner accuracy is what decides whether the page
    // comes out square, and the adaptive throttle below already backs off the
    // frame rate on a device that cannot keep up.
    this.detectSize = options.detectSize ?? 640
    this.targetFps = options.targetFps ?? 12
    this.output = options.output ?? LETTER_LANDSCAPE
    this.regions = options.regions ?? []
    // Worksheet field percentages are relative to the printable area inside the
    // page margins and header, not to the sheet. See WORKSHEET_CONTENT_FRAME.
    this.contentFrame = options.contentFrame ?? WORKSHEET_CONTENT_FRAME
    this.autoCapture = options.autoCapture ?? true
    // Confidence here is the WEAKEST of the four edges, which separates the two
    // populations cleanly. Measured across the synthetic suite plus hand-grip
    // cases: every frame that rectifies correctly scores >= 0.59, every frame
    // that produces a wrong quad scores <= 0.21. 0.45 sits in that gap with
    // roughly 2x margin on both sides.
    this.autoCaptureConfidence = options.autoCaptureConfidence ?? 0.45
    this.autoCaptureMinArea = options.autoCaptureMinArea ?? 0.18
    this.detectOptions = options.detectOptions ?? {}
    this.clean = options.clean ?? true
    // Keep the unstraightened frame alongside each capture, so detection can be
    // measured against real photographs instead of synthetic ones.
    this.keepRaw = options.keepRaw ?? true
    this.rawSize = options.rawSize ?? 1400
    this.rawQuality = options.rawQuality ?? 0.72
    // When set, every few frames are also searched for a worksheet QR code, so
    // a scan page opened with no scenario can work out which sheet this is.
    this.wantQR = options.wantQR ?? false
    this.qrIntervalMs = options.qrIntervalMs ?? 250
    this.qrSize = options.qrSize ?? 1280
    this.onUpdate = options.onUpdate ?? (() => {})
    this.onCapture = options.onCapture ?? (() => {})
    this.onQR = options.onQR ?? (() => {})
    this.onError = options.onError ?? (err => console.error(err))

    // Looser than a document scanner would normally allow, because the subject
    // here is a sheet held by a child or propped in front of a laptop webcam:
    // waiting a full second for sub-2% corner stillness meant auto-capture
    // effectively never fired.
    this.tracker = new QuadTracker({
      stableMs: options.stableMs ?? 700,
      tolFraction: options.tolFraction ?? 0.035,
      minFrames: options.minFrames ?? 4,
    })
    this.lastQRText = null
    this._lastQRRun = 0
    this._qrBusy = false
    this.stream = null
    this.running = false
    this.manual = false
    this.manualQuad = null
    this.lastQuad = null
    this.lastDetectMs = 0
    this.lastWarning = null
    this.still = null
    this._raf = null
    this._lastRun = 0
    this._scratch = null
  }

  /** The element frames are read from: a loaded still takes over from the video. */
  get source () {
    return this.still ?? this.video
  }

  async start (constraints) {
    const wanted = constraints ?? {
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1920 },
        height: { ideal: 1080 },
      },
      audio: false,
    }
    try {
      this.stream = await navigator.mediaDevices.getUserMedia(wanted)
    } catch (err) {
      // Back-facing camera is only a preference; a laptop webcam is fine.
      if (constraints) throw err
      this.stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false })
    }
    this.video.srcObject = this.stream
    this.video.setAttribute('playsinline', '')
    this.video.muted = true
    await this.video.play()
    this.running = true
    this.tracker.reset()
    this._loop()
    return this.stream
  }

  stop () {
    this.running = false
    if (this._raf) cancelAnimationFrame(this._raf)
    this._raf = null
    if (this.stream) {
      for (const track of this.stream.getTracks()) track.stop()
      this.stream = null
    }
  }

  get frameSize () {
    const s = this.source
    if (!s) return { width: 0, height: 0 }
    return {
      width: s.naturalWidth ?? s.videoWidth ?? s.width ?? 0,
      height: s.naturalHeight ?? s.videoHeight ?? s.height ?? 0,
    }
  }

  /**
   * Detect against a still image instead of the live camera. Lets the whole
   * pipeline be exercised (and real photos checked) on a machine with no camera.
   */
  useStill (image) {
    this.still = image
    this.manual = false
    this.manualQuad = null
    this.tracker.reset()
    if (this.video && !this.video.paused) this.video.pause()
    return this.detectOnce()
  }

  clearStill () {
    this.still = null
    this.tracker.reset()
    if (this.running && this.video) this.video.play()
  }

  /** Single detection pass over the current source, without the tracking loop. */
  detectOnce () {
    const { width, height } = this.frameSize
    if (!width || !height) return null
    const scale = Math.min(1, this.detectSize / Math.max(width, height))
    const frame = readFrame(this.source, Math.round(width * scale), Math.round(height * scale))
    const t0 = performance.now()
    const result = detectQuad(frame, this.detectOptions)
    this.lastDetectMs = performance.now() - t0
    this.lastQuad = result ? result.quadNormalized.map(p => ({ ...p })) : null
    this.lastWarning = warningFor(result)
    this.onUpdate({
      quad: this.lastQuad,
      stable: !!result,
      progress: 0,
      score: result?.score ?? 0,
      touchesBorder: result?.touchesBorder ?? false,
      clipped: result?.clipped ?? false,
      fillsFrame: result?.fillsFrame ?? false,
      warning: this.lastWarning,
      detectMs: this.lastDetectMs,
      manual: false,
    })
    return result
  }

  /** Freeze the preview so corners can be dragged against a still frame. */
  enterManualMode () {
    const quad = this.lastQuad ?? [
      { x: 0.12, y: 0.12 }, { x: 0.88, y: 0.12 }, { x: 0.88, y: 0.88 }, { x: 0.12, y: 0.88 },
    ]
    this.manualQuad = quad.map(p => ({ ...p }))
    this.manual = true
    if (this.video && !this.video.paused) this.video.pause()
    this.onUpdate({ quad: this.manualQuad, stable: false, progress: 0, manual: true })
    return this.manualQuad
  }

  exitManualMode () {
    // Against a frozen still there is no live detection to fall back to, so the
    // hand-placed corners become the current quad instead of being discarded.
    // With the camera running, dropping them is right: tracking takes over.
    if (this.still && this.manualQuad) {
      this.lastQuad = this.manualQuad.map(p => ({ ...p }))
    }
    this.manual = false
    this.manualQuad = null
    this.tracker.reset()
    if (this.running && !this.still && this.video) this.video.play()
  }

  setManualQuad (quad) {
    this.manualQuad = quad.map(p => ({
      x: Math.min(1, Math.max(0, p.x)),
      y: Math.min(1, Math.max(0, p.y)),
    }))
    this.onUpdate({ quad: this.manualQuad, stable: false, progress: 0, manual: true })
  }

  /** Pull the manually placed corners onto the nearest real image edges. */
  snapManualQuad () {
    if (!this.manualQuad) return null
    const { width, height } = this.frameSize
    if (!width) return null
    const frame = readFrame(this.source, width, height)
    const pixels = this.manualQuad.map(p => ({ x: p.x * width, y: p.y * height }))
    const snapped = snapQuad(frame, pixels)
    if (!snapped) return this.manualQuad
    this.setManualQuad(snapped.map(p => ({ x: p.x / width, y: p.y / height })))
    return this.manualQuad
  }

  _loop () {
    if (!this.running) return
    this._raf = requestAnimationFrame(() => this._loop())
    if (this.manual || this.still) return
    const now = performance.now()
    // Adaptive throttle: never spend more than roughly half the wall clock on
    // detection, so a slow device degrades in frame rate rather than locking up.
    const interval = Math.max(1000 / this.targetFps, this.lastDetectMs * 1.8)
    if (now - this._lastRun < interval) return
    this._lastRun = now

    const { width, height } = this.frameSize
    if (!width || !height) return
    const scale = Math.min(1, this.detectSize / Math.max(width, height))
    const dw = Math.max(2, Math.round(width * scale))
    const dh = Math.max(2, Math.round(height * scale))

    let frame
    try {
      frame = this._readScratch(dw, dh)
    } catch (err) {
      this.onError(err)
      return
    }

    const t0 = performance.now()
    let result = null
    try {
      result = detectQuad(frame, this.detectOptions)
    } catch (err) {
      this.onError(err)
    }
    this.lastDetectMs = performance.now() - t0

    const diag = Math.hypot(dw, dh)
    const pixelQuad = result ? result.quad : null
    const tracked = this.tracker.update(pixelQuad, now, diag)
    const quad = tracked.quad
      ? tracked.quad.map(p => ({ x: p.x / dw, y: p.y / dh }))
      : null
    this.lastQuad = quad

    // Never auto-fire on a frame the detector has told us it cannot trust:
    // a page that overruns the viewport yields a quad around some printed box
    // inside the sheet, and silently capturing that is worse than not capturing.
    const warning = warningFor(result)
    this.lastWarning = warning

    // "Held still" is not the same as "correct" -- a wrong outline sits just as
    // still as a right one. Auto-capture additionally requires that the image
    // actually backs those edges, and that the quad covers a plausible share of
    // the frame, so a lock onto some printed box inside the page cannot fire.
    const confidence = result?.confidence ?? 0
    const areaFraction = result?.areaFraction ?? 0
    const trustworthy = !warning &&
      confidence >= this.autoCaptureConfidence &&
      areaFraction >= this.autoCaptureMinArea

    this.onUpdate({
      quad,
      stable: tracked.stable,
      progress: trustworthy ? tracked.progress : 0,
      score: result?.score ?? 0,
      confidence,
      areaFraction,
      trustworthy,
      touchesBorder: result?.touchesBorder ?? false,
      clipped: result?.clipped ?? false,
      fillsFrame: result?.fillsFrame ?? false,
      warning,
      detectMs: this.lastDetectMs,
      manual: false,
    })

    if (this.wantQR && now - this._lastQRRun > this.qrIntervalMs) this._scanQR(now)

    if (tracked.stable && this.autoCapture && trustworthy) {
      this.tracker.reset()
      this.capture(quad, 'auto')
    }
  }

  /**
   * Look for a worksheet QR code in the current frame. Runs off the detection
   * frame that was already read, and never more than one at a time, so turning
   * it on does not slow page tracking down.
   */
  _scanQR (now) {
    if (this._qrBusy) return
    const { width, height } = this.frameSize
    if (!width || !height) return
    this._qrBusy = true
    this._lastQRRun = now
    // Deliberately not the 640px detection frame: the printed code is under a
    // tenth of the page wide, which at detection resolution leaves barely one
    // pixel per QR module. This reads its own larger frame a few times a second.
    const scale = Math.min(1, this.qrSize / Math.max(width, height))
    const frame = readFrame(this.source, Math.round(width * scale), Math.round(height * scale))
    Promise.resolve(decodeQR(this.source, frame))
      .then(text => {
        if (!text || text === this.lastQRText) return
        const parsed = parseWorksheetQR(text)
        if (!parsed) return
        this.lastQRText = text
        this.onQR({ text, ...parsed })
      })
      .catch(() => {})
      .finally(() => { this._qrBusy = false })
  }

  /** One-shot QR read against the current source, at full resolution. */
  async scanQROnce () {
    const { width, height } = this.frameSize
    if (!width || !height) return null
    // Full resolution here: a printed QR is small on the page, and this runs
    // once against a still rather than every frame of a preview.
    const frame = readFrame(this.source, width, height)
    const text = await decodeQR(this.source, frame)
    if (!text) return null
    const parsed = parseWorksheetQR(text)
    if (parsed) {
      this.lastQRText = text
      this.onQR({ text, ...parsed })
    }
    return parsed
  }

  _readScratch (w, h) {
    if (!this._scratch || this._scratch.canvas.width !== w || this._scratch.canvas.height !== h) {
      const canvas = createCanvas(w, h)
      this._scratch = { canvas, ctx: canvas.getContext('2d', { willReadFrequently: true }) }
    }
    const { canvas, ctx } = this._scratch
    ctx.drawImage(this.source, 0, 0, w, h)
    return ctx.getImageData(0, 0, canvas.width, canvas.height)
  }

  /**
   * Rectify the current frame and crop the configured regions.
   * @param {Array<{x,y}>} [quad] normalized corners; defaults to the tracked quad
   * @returns {{quad, canvas, dataUrl, regions, source}|null}
   */
  capture (quad = null, source = 'manual') {
    const use = quad ?? this.manualQuad ?? this.lastQuad
    if (!use) return null
    const { width, height } = this.frameSize
    if (!width || !height) return null

    const frame = readFrame(this.source, width, height)
    const pixels = orderQuad(use.map(p => ({ x: p.x * width, y: p.y * height })))
    const warped = warpQuad(frame, pixels, this.output.width, this.output.height)
    if (!warped) return null

    // Flatten the lighting and paint out any hand holding the sheet before
    // anything downstream sees it: the region crops and the archived page
    // should both be the cleaned version, not the raw photo.
    const cleaned = this.clean ? cleanPage(warped) : { image: warped, handsRemoved: 0 }
    const page = cleaned.image

    const canvas = imageDataToCanvas(page)
    const result = {
      quad: use.map(p => ({ ...p })),
      canvas,
      dataUrl: canvas.toDataURL('image/png'),
      regions: this.regions.length ? cropRegionsToCanvases(page, this.regions, this.contentFrame) : [],
      handsRemoved: cleaned.handsRemoved,
      cleanupSkipped: cleaned.skipped || null,
      // The unstraightened frame this was made from, plus the corners we chose.
      // Only the rectified page is otherwise kept, and a rectified page cannot
      // tell you whether the corners were right — so without this there is no
      // way to measure or improve detection against real captures.
      rawDataUrl: this.keepRaw ? this._rawJpeg(frame) : null,
      source,
    }
    this.onCapture(result)
    return result
  }

  /**
   * A modest JPEG of the frame detection ran against, for later analysis.
   * Deliberately downscaled: this is diagnostic data attached to every scan, and
   * corner accuracy is judged at a far lower resolution than the page itself.
   */
  _rawJpeg (frame) {
    try {
      const scale = Math.min(1, this.rawSize / Math.max(frame.width, frame.height))
      const full = imageDataToCanvas(frame)
      if (scale >= 1) return full.toDataURL('image/jpeg', this.rawQuality)
      const small = createCanvas(Math.round(frame.width * scale), Math.round(frame.height * scale))
      const ctx = small.getContext('2d')
      ctx.imageSmoothingQuality = 'high'
      ctx.drawImage(full, 0, 0, small.width, small.height)
      return small.toDataURL('image/jpeg', this.rawQuality)
    } catch (err) {
      return null // diagnostics must never break a capture
    }
  }

  /** Run the same pipeline over a still image (file upload, testing). */
  captureFromImage (source, quad = null) {
    const width = source.naturalWidth ?? source.width
    const height = source.naturalHeight ?? source.height
    const frame = readFrame(source, width, height)
    let pixels
    if (quad) {
      pixels = orderQuad(quad.map(p => ({ x: p.x * width, y: p.y * height })))
    } else {
      const scale = Math.min(1, this.detectSize / Math.max(width, height))
      const small = readFrame(source, Math.round(width * scale), Math.round(height * scale))
      const found = detectQuad(small, this.detectOptions)
      if (!found) return null
      pixels = found.quadNormalized.map(p => ({ x: p.x * width, y: p.y * height }))
    }
    const warped = warpQuad(frame, pixels, this.output.width, this.output.height)
    if (!warped) return null
    const cleaned = this.clean ? cleanPage(warped) : { image: warped, handsRemoved: 0 }
    const page = cleaned.image
    const canvas = imageDataToCanvas(page)
    return {
      quad: pixels.map(p => ({ x: p.x / width, y: p.y / height })),
      canvas,
      dataUrl: canvas.toDataURL('image/png'),
      regions: this.regions.length ? cropRegionsToCanvases(page, this.regions, this.contentFrame) : [],
      handsRemoved: cleaned.handsRemoved,
      source: 'image',
    }
  }
}
