<template>
  <div class="ai-junior-capture">
    <div
      v-if="!hasAccess"
      class="notice"
    >
      <p>You need AI Junior access to scan a worksheet.</p>
    </div>

    <template v-else>
      <header class="capture-header">
        <h1>Scan your worksheet</h1>
        <p v-if="scenario">
          {{ scenario.name }}<span
            v-if="qrUserName"
            class="owner-name"
          > · {{ qrUserName }}</span>
        </p>
        <p
          v-else-if="awaitingQR"
          class="muted"
        >
          Point at any worksheet — I'll work out which one it is.
        </p>
        <p
          v-else-if="!loadError"
          class="muted"
        >
          Loading…
        </p>
        <p
          v-if="loadError"
          class="error-text"
        >
          {{ loadError }}
        </p>
      </header>

      <!-- Stage: live camera, or the photo that was taken/uploaded. -->
      <div
        v-show="stage === 'capture'"
        class="stage-wrap"
      >
        <div class="stage">
          <video
            v-show="cameraOn && !stillLoaded"
            ref="video"
            playsinline
            muted
          />
          <img
            v-show="stillLoaded"
            ref="still"
            class="still"
            alt=""
          >
          <canvas
            ref="overlay"
            class="overlay"
            @pointerdown="onPointerDown"
            @pointermove="onPointerMove"
            @pointerup="onPointerUp"
            @pointercancel="onPointerUp"
          />
          <div
            v-if="!cameraOn && !stillLoaded"
            class="stage-empty"
          >
            <p>Take a photo of your worksheet, or turn on the camera to scan it live.</p>
            <p
              v-if="!cameraSupported || !isSecure"
              class="stage-empty-note"
            >
              Live camera needs a secure (https) connection — the photo button works either way.
            </p>
          </div>
        </div>

        <p
          v-if="statusMessage"
          class="status-line"
          :class="{ warn: !!warning }"
        >
          {{ statusMessage }}
        </p>

        <div class="controls">
          <!-- With the camera live by default, the shutter leads. The photo
               path stays available for phones on plain HTTP, where
               getUserMedia does not exist at all. -->
          <button
            v-if="cameraOn && !stillLoaded"
            type="button"
            class="btn btn-big btn-primary"
            :disabled="!hasQuad || awaitingQR"
            @click="captureNow"
          >
            📸 Capture
          </button>

          <label
            class="btn btn-big file-btn"
            :class="cameraOn ? 'btn-default' : 'btn-primary'"
          >
            📷 {{ cameraOn ? 'Use a photo instead' : 'Take / upload photo' }}
            <input
              type="file"
              accept="image/*"
              capture="environment"
              @change="onFileChosen"
            >
          </label>

          <button
            v-if="!cameraOn && cameraSupported"
            type="button"
            class="btn btn-big btn-default"
            @click="startCamera"
          >
            🎥 Use live camera
          </button>

          <button
            v-if="cameraOn && !stillLoaded"
            type="button"
            class="btn btn-big btn-default"
            @click="toggleAutoCapture"
          >
            {{ autoCaptureWanted ? '⏱ Auto: on' : '⏱ Auto: off' }}
          </button>

          <button
            v-if="canAdjust"
            type="button"
            class="btn btn-big btn-default"
            @click="toggleManual"
          >
            {{ manual ? 'Done adjusting' : '✥ Adjust corners' }}
          </button>

          <button
            v-if="manual"
            type="button"
            class="btn btn-big btn-default"
            @click="snapCorners"
          >
            Snap to edges
          </button>

          <button
            v-if="stillLoaded"
            type="button"
            class="btn btn-big btn-primary"
            :disabled="awaitingQR"
            @click="captureNow"
          >
            Use this photo
          </button>
        </div>

        <p
          v-if="cameraError"
          class="error-text"
        >
          {{ cameraError }}
        </p>
      </div>

      <!-- Stage: review the straightened page before sending it. -->
      <div
        v-show="stage === 'review'"
        class="review"
      >
        <h2>Does this look right?</h2>
        <p class="muted">
          Check that the whole worksheet is here and the writing is easy to read.
          <span v-if="handsRemoved > 0.002">Fingers holding the page were painted out.</span>
        </p>

        <div class="page-preview">
          <img
            v-if="pageDataUrl"
            :src="pageDataUrl"
            alt="Straightened worksheet"
          >
        </div>

        <div
          v-if="regionThumbs.length"
          class="thumbs"
        >
          <figure
            v-for="thumb in regionThumbs"
            :key="thumb.id"
            class="thumb"
          >
            <img
              :src="thumb.dataUrl"
              :alt="thumb.id"
            >
            <figcaption>{{ thumb.label }}</figcaption>
          </figure>
        </div>

        <div class="controls">
          <button
            type="button"
            class="btn btn-big btn-default"
            :disabled="submitting"
            @click="retake"
          >
            ↺ Retake
          </button>
          <button
            type="button"
            class="btn btn-big btn-primary"
            :disabled="submitting"
            @click="submit"
          >
            <span v-if="submitting">
              <span class="spinner" /> Sending…
            </span>
            <span v-else>✨ Make my project</span>
          </button>
        </div>

        <p
          v-if="submitError"
          class="error-text"
        >
          {{ submitError }}
        </p>
      </div>

      <!-- Sheets sent this session. They generate on the server whatever this
           page is doing, so a stack can be scanned straight through. -->
      <section
        v-if="batch.length"
        class="batch"
      >
        <h3 class="batch-heading">
          {{ batch.length }} sent<span v-if="stillGenerating"> · {{ stillGenerating }} still generating</span>
        </h3>
        <div class="batch-strip">
          <a
            v-for="entry in batch"
            :key="entry.id"
            class="batch-item"
            :class="entry.status"
            :href="entry.url"
            target="_blank"
            rel="noopener"
            :title="entry.name"
          >
            <img
              v-if="entry.thumb"
              :src="entry.thumb"
              alt=""
            >
            <span class="batch-status">{{ statusIcon(entry.status) }}</span>
          </a>
        </div>
        <p class="batch-hint">
          Keep scanning — each one finishes on its own. Tap any to open it.
        </p>
      </section>
    </template>
  </div>
</template>

<script>
import { getAIJuniorScenario, getAIJuniorScenarios } from 'app/core/api/ai-junior-scenarios'
import { createNewAIJuniorProject, processAIJuniorProject, getAIJuniorProject } from 'app/core/api/ai-junior-projects'
import usersApi from 'app/core/api/users'
import { DocumentScanner, drawOverlay, pickCorner } from 'app/lib/doc-capture/capture'

// The scan is archived and vision-read server-side, so it wants to be legible
// but not enormous; JPEG at this quality keeps a 2200x1700 page near ~400KB.
const SCAN_JPEG_QUALITY = 0.85

export default {
  name: 'AIJuniorCaptureView',
  props: {
    // Optional: /ai-junior/scan with no scenario reads the worksheet's own QR
    // code to work out which activity and which student the sheet belongs to.
    scenarioHandle: {
      type: String,
      default: null,
    },
    forUserId: {
      type: String,
      default: null,
    },
  },
  data () {
    return {
      scenario: null,
      loadError: null,
      stage: 'capture',
      cameraOn: false,
      cameraError: null,
      stillLoaded: false,
      manual: false,
      hasQuad: false,
      warning: null,
      pageDataUrl: null,
      regionThumbs: [],
      submitting: false,
      submitError: null,
      // Sheets sent during this session, newest first. They generate on the
      // server independently of this page.
      batch: [],
      batchTimer: null,
      dragging: -1,
      handsRemoved: 0,
      // Filled in from the QR code when the route did not name a scenario.
      qrScenarioHandle: null,
      qrUserId: null,
      qrUserName: null,
      qrSearching: false,
      // User-facing toggle; the confidence gate below is what actually decides
      // whether any given frame is good enough to fire on.
      autoCaptureWanted: true,
      holdingSteady: false,
    }
  },
  computed: {
    hasAccess () {
      return me.hasAiJuniorAccess()
    },
    cameraSupported () {
      return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia)
    },
    isSecure () {
      return window.isSecureContext
    },
    stillGenerating () {
      return this.batch.filter((entry) => entry.status === 'processing').length
    },
    canAdjust () {
      return this.cameraOn || this.stillLoaded
    },
    imageFieldInputs () {
      return (this.scenario?.inputs || []).filter((input) => input.type === 'image-field')
    },
    // Which activity this scan belongs to, from the route or from the QR code.
    activeScenarioHandle () {
      return this.scenarioHandle || this.qrScenarioHandle
    },
    ownerId () {
      return this.forUserId || this.qrUserId || me.id
    },
    // Without a scenario there are no regions to crop, so firing the shutter
    // early would produce a page nothing could be done with.
    awaitingQR () {
      return !this.activeScenarioHandle
    },
    statusMessage () {
      if (this.awaitingQR) {
        if (this.stillLoaded) return 'No worksheet code found in that photo — try again with the code in frame.'
        if (this.cameraOn) return 'Looking for the code in the corner of the worksheet…'
        return null
      }
      if (this.warning) return this.warning
      if (this.manual) return 'Drag the four circles onto the corners of the paper.'
      if (this.stillLoaded) return this.hasQuad ? 'Found the worksheet! Tap "Use this photo".' : 'Could not find the paper edges — tap "Adjust corners" to place them yourself.'
      if (this.cameraOn) {
        if (!this.hasQuad) return 'Point the camera at the whole worksheet.'
        if (!this.holdingSteady) return 'Show all four edges of the paper — move your fingers off the edges.'
        return this.autoCaptureWanted ? 'Hold still — snapping automatically…' : 'Looks good — tap Capture.'
      }
      return null
    },
  },
  async created () {
    if (!this.scenarioHandle) return // Waiting on the QR code instead.
    await this.loadScenario(this.scenarioHandle)
  },
  mounted () {
    if (!this.hasAccess) return
    // These four stay off `data` deliberately: the scanner holds canvases and
    // typed arrays and the capture result holds a 2200x1700 canvas, so making
    // Vue observe them costs a lot and buys nothing — the template only ever
    // reads the small derived values (pageDataUrl, regionThumbs).
    this.lastCapture = null
    this.objectUrl = null
    this.overlayProgress = 0
    this.scanner = new DocumentScanner({
      video: this.$refs.video,
      wantQR: this.awaitingQR,
      // Auto-capture used to fire on frames that were not actually good, which
      // is worse than asking for a tap: a bad scan costs a whole AI run to find
      // out about. It now additionally requires that the *weakest* of the four
      // detected edges is genuinely backed by the image, which is what a hand
      // gripping the page breaks -- so a held-still-but-wrong outline no longer
      // fires. Off until a QR has named the activity, so nothing is captured
      // before we know what it is.
      autoCapture: !this.awaitingQR && this.autoCaptureWanted,
      onUpdate: this.onScannerUpdate,
      onCapture: this.onScannerCapture,
      onQR: this.onQRFound,
      onError: (err) => console.error('Scanner error:', err),
    })
    // Regions come from the scenario, which may still be loading.
    this.$watch('imageFieldInputs', (inputs) => {
      if (this.scanner) this.scanner.regions = inputs
    }, { immediate: true })
    window.addEventListener('resize', this.sizeOverlay)
    this.sizeOverlay()

    // Open the camera straight away — pointing a page at a worksheet is the
    // whole job, so making that a second tap is pure friction. Only where
    // getUserMedia can actually work: over plain HTTP it is absent, and asking
    // for it there just produces an error the user cannot do anything about.
    if (this.cameraSupported && window.isSecureContext) this.startCamera()
  },
  beforeDestroy () {
    if (this.batchTimer) clearInterval(this.batchTimer)
    window.removeEventListener('resize', this.sizeOverlay)
    if (this.scanner) {
      this.scanner.stop()
      this.scanner = null
    }
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
  },
  methods: {
    // --- scenario / QR ----------------------------------------------------

    async loadScenario (handle) {
      try {
        this.scenario = await getAIJuniorScenario({ scenarioHandle: handle })
        this.loadError = null
        return true
      } catch (error) {
        console.error('Error fetching scenario:', error)
        this.loadError = 'Could not load this activity. Please go back and try again.'
        return false
      }
    },

    // The worksheet's QR code names both the activity and the child it was
    // printed for, which is everything a bare /ai-junior/scan page needs.
    async onQRFound ({ scenarioHandle, userId, isPrefix }) {
      if (this.activeScenarioHandle) return
      // A short code names the scenario by the leading characters of its id, so
      // resolve it against the (very small) scenario list before loading.
      if (isPrefix) {
        try {
          const scenarios = await getAIJuniorScenarios()
          const match = (scenarios || []).find((s) => String(s._id).startsWith(scenarioHandle))
          if (!match) return
          scenarioHandle = match.slug || String(match._id)
        } catch (error) {
          console.error('Could not resolve the worksheet code:', error)
          return
        }
      }
      this.qrSearching = true
      const loaded = await this.loadScenario(scenarioHandle)
      this.qrSearching = false
      if (!loaded) return
      this.qrScenarioHandle = scenarioHandle
      this.qrUserId = userId
      if (this.scanner) {
        this.scanner.wantQR = false
        this.scanner.autoCapture = this.autoCaptureWanted
        this.scanner.regions = this.imageFieldInputs
        this.scanner.tracker.reset()
      }
      if (userId && userId !== me.id) this.loadOwnerName(userId)
    },

    async loadOwnerName (userId) {
      try {
        const user = await usersApi.getByHandle(userId)
        this.qrUserName = user?.name || user?.firstName || null
      } catch (error) {
        // Not fatal — the scan works whether or not we can show a name.
        this.qrUserName = null
      }
    },

    // --- camera / photo sources -------------------------------------------

    async startCamera () {
      this.cameraError = null
      try {
        await this.scanner.start()
        this.cameraOn = true
        this.$nextTick(this.sizeOverlay)
      } catch (error) {
        console.error('Could not open camera:', error)
        this.cameraError = window.isSecureContext
          ? 'Could not open the camera. You can still take a photo with the button above.'
          : 'The camera needs a secure (https) connection. Use "Take / upload photo" instead — it works the same way.'
      }
    },

    onFileChosen (event) {
      const file = event.target.files && event.target.files[0]
      if (!file) return
      this.cameraError = null
      if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
      this.objectUrl = URL.createObjectURL(file)

      const image = new Image()
      image.onload = () => {
        this.scanner.stop()
        this.cameraOn = false
        const still = this.$refs.still
        still.src = this.objectUrl
        this.stillLoaded = true
        this.$nextTick(async () => {
          this.sizeOverlay()
          this.scanner.useStill(image)
          // A photo picked on a phone is often the only shot we get, so read
          // the code straight out of it rather than asking for a live preview.
          if (this.awaitingQR) {
            this.qrSearching = true
            await this.scanner.scanQROnce()
            this.qrSearching = false
            this.scanner.detectOnce()
          }
        })
      }
      image.onerror = () => {
        this.cameraError = 'Could not read that picture. Please try taking it again.'
      }
      image.src = this.objectUrl
      // Allow re-picking the same file.
      event.target.value = ''
    },

    // --- overlay ----------------------------------------------------------

    sizeOverlay () {
      const overlay = this.$refs.overlay
      if (!overlay) return
      const rect = overlay.getBoundingClientRect()
      if (!rect.width || !rect.height) return
      const dpr = Math.min(2, window.devicePixelRatio || 1)
      const width = Math.round(rect.width * dpr)
      const height = Math.round(rect.height * dpr)
      if (overlay.width !== width || overlay.height !== height) {
        overlay.width = width
        overlay.height = height
      }
      this.redrawOverlay()
    },

    // The video/photo is letterboxed by `object-fit: contain`, so normalized
    // frame coordinates have to be mapped through the displayed rectangle or
    // the outline drifts off the paper when the aspect ratios differ.
    displayRect () {
      const overlay = this.$refs.overlay
      const frame = this.scanner ? this.scanner.frameSize : { width: 0, height: 0 }
      const fw = frame.width || 4
      const fh = frame.height || 3
      const scale = Math.min(overlay.width / fw, overlay.height / fh)
      const w = fw * scale
      const h = fh * scale
      return { x: (overlay.width - w) / 2, y: (overlay.height - h) / 2, w, h }
    },

    redrawOverlay () {
      const overlay = this.$refs.overlay
      if (!overlay || !this.scanner) return
      const ctx = overlay.getContext('2d')
      const quad = this.manual ? this.scanner.manualQuad : this.scanner.lastQuad
      if (!quad) {
        ctx.clearRect(0, 0, overlay.width, overlay.height)
        return
      }
      const rect = this.displayRect()
      const points = quad.map((p) => ({
        x: (rect.x + p.x * rect.w) / overlay.width,
        y: (rect.y + p.y * rect.h) / overlay.height,
      }))
      drawOverlay(ctx, points, {
        stable: !this.warning,
        progress: this.manual ? 0 : this.overlayProgress,
        handles: this.manual,
        handleRadius: 16,
        lineWidth: 4,
        ...(this.warning ? { lineColor: '#f0932b', searchColor: 'rgba(240,147,43,0.45)' } : {}),
      })
    },

    onScannerUpdate ({ quad, progress, warning, trustworthy }) {
      this.hasQuad = !!quad
      this.warning = warning || null
      this.overlayProgress = progress || 0
      // `trustworthy` is the scanner's own verdict on this frame: no warning,
      // every edge backed by the image, plausible size. Drives the wording so
      // the user is told to hold still only when holding still will help.
      this.holdingSteady = !!trustworthy
      this.redrawOverlay()
    },

    // --- manual corners ---------------------------------------------------

    toggleAutoCapture () {
      this.autoCaptureWanted = !this.autoCaptureWanted
      if (this.scanner) {
        this.scanner.autoCapture = this.autoCaptureWanted && !this.awaitingQR
        this.scanner.tracker.reset()
      }
    },

    toggleManual () {
      if (this.manual) {
        this.manual = false
        this.scanner.exitManualMode()
      } else {
        this.scanner.enterManualMode()
        this.manual = true
      }
      this.redrawOverlay()
    },

    snapCorners () {
      this.scanner.snapManualQuad()
      this.redrawOverlay()
    },

    pointerToFrame (event) {
      const overlay = this.$refs.overlay
      const bounds = overlay.getBoundingClientRect()
      const rect = this.displayRect()
      const dpr = overlay.width / bounds.width
      const x = (event.clientX - bounds.left) * dpr
      const y = (event.clientY - bounds.top) * dpr
      return { x: (x - rect.x) / rect.w, y: (y - rect.y) / rect.h }
    },

    onPointerDown (event) {
      if (!this.manual || !this.scanner.manualQuad) return
      this.dragging = pickCorner(this.scanner.manualQuad, this.pointerToFrame(event), 0.1)
      if (this.dragging >= 0) {
        this.$refs.overlay.setPointerCapture(event.pointerId)
        event.preventDefault()
      }
    },

    onPointerMove (event) {
      if (this.dragging < 0 || !this.scanner.manualQuad) return
      const next = this.scanner.manualQuad.map((p) => ({ ...p }))
      next[this.dragging] = this.pointerToFrame(event)
      this.scanner.setManualQuad(next)
      this.redrawOverlay()
      event.preventDefault()
    },

    onPointerUp (event) {
      if (this.dragging >= 0) {
        try { this.$refs.overlay.releasePointerCapture(event.pointerId) } catch (e) { /* already released */ }
      }
      this.dragging = -1
    },

    // --- capture / review -------------------------------------------------

    captureNow () {
      const result = this.scanner.capture(this.manual ? this.scanner.manualQuad : null, 'manual')
      if (!result) {
        this.cameraError = 'Could not find the worksheet corners. Tap "Adjust corners" and place them yourself.'
      }
    },

    onScannerCapture (result) {
      this.lastCapture = result
      this.pageDataUrl = result.dataUrl
      this.handsRemoved = result.handsRemoved || 0
      const labelFor = (id) => {
        const input = this.imageFieldInputs.find((i) => i.id === id)
        return (input && (input.label || input.text)) || id
      }
      this.regionThumbs = result.regions.map((region) => ({
        id: region.id,
        label: labelFor(region.id),
        dataUrl: region.dataUrl,
      }))
      this.stage = 'review'
      this.submitError = null
      if (this.scanner.stream) this.scanner.stop()
      this.cameraOn = false
    },

    retake () {
      this.stage = 'capture'
      this.pageDataUrl = null
      this.regionThumbs = []
      this.lastCapture = null
      this.manual = false
      if (!this.scanner) return
      this.scanner.exitManualMode()
      if (this.stillLoaded) {
        // Re-run detection on the photo that is still on screen.
        this.scanner.detectOnce()
      } else if (this.cameraSupported) {
        // Capturing stopped the stream; bring it back so retake is one tap.
        this.startCamera()
      }
      this.$nextTick(this.sizeOverlay)
    },

    async submit () {
      if (!this.lastCapture || this.submitting) return
      if (!this.scenario) {
        this.submitError = 'This activity did not finish loading. Please reload the page and try again.'
        return
      }
      this.submitting = true
      this.submitError = null
      try {
        const inputValues = {}
        for (const region of this.lastCapture.regions) {
          inputValues[region.id] = region.dataUrl
        }
        // The whole straightened page goes along as well: the server archives it
        // and vision-extracts the text/checkbox/radio answers from it, which is
        // why nothing tries to read those fields here.
        inputValues.scannedWorksheet = this.lastCapture.canvas.toDataURL('image/jpeg', SCAN_JPEG_QUALITY)
        // Diagnostics: the frame before straightening, and the corners chosen
        // for it. The archived page is already rectified, so it cannot show
        // whether the corners were right — these are what make it possible to
        // measure detection against real captures rather than synthetic ones.
        if (this.lastCapture.rawDataUrl) {
          inputValues.rawCapture = this.lastCapture.rawDataUrl
          inputValues.captureQuad = JSON.stringify(this.lastCapture.quad)
          inputValues.captureSource = this.lastCapture.source
        }

        const project = await createNewAIJuniorProject({
          scenarioId: this.scenario._id,
          // Whose sheet this was, per the QR code or the route. The server
          // decides whether the scanning account is allowed to file it under
          // that child; if not, it stays with the scanner.
          forUserId: this.ownerId,
          inputValues,
          name: this.qrUserName ? `${this.scenario.name} — ${this.qrUserName}` : `${this.scenario.name} (scanned)`,
        })
        // Kick off processing before going anywhere: the server returns 202 as
        // soon as it has queued the work, and leaving the page first would
        // abort the request. A failure here is not fatal — the project exists
        // and its page can retry — so it must not block what follows.
        try {
          await processAIJuniorProject({ projectHandle: project._id, force: true })
        } catch (error) {
          console.error('Could not start processing; the project page can retry:', error)
        }

        const url = `/ai-junior/project/${this.activeScenarioHandle}/${project.user || me.id}/${project._id}`

        // Scanning a stack is the normal case, so stay put and take the next
        // sheet. Each project generates on the server regardless of what this
        // page is doing; the strip below keeps track of them.
        this.batch.unshift({
          id: project._id,
          url,
          name: project.name,
          thumb: this.lastCapture.regions[0]?.dataUrl || this.pageDataUrl,
          status: 'processing',
        })
        this.submitting = false
        this.retake()
        this.startBatchPolling()
      } catch (error) {
        console.error('Error submitting scanned worksheet:', error)
        this.submitting = false
        this.submitError = 'Something went wrong sending your worksheet. Please try again.'
      }
    },

    statusIcon (status) {
      if (status === 'completed') return '✓'
      if (status === 'failed') return '!'
      return '…'
    },

    // --- batch ------------------------------------------------------------

    startBatchPolling () {
      if (this.batchTimer) return
      this.batchTimer = setInterval(this.refreshBatch, 5000)
    },

    async refreshBatch () {
      const pending = this.batch.filter((entry) => entry.status === 'processing')
      if (!pending.length) {
        clearInterval(this.batchTimer)
        this.batchTimer = null
        return
      }
      // One at a time: this runs while the user is lining up the next sheet,
      // and the camera loop matters more than the status dots.
      for (const entry of pending.slice(0, 3)) {
        try {
          const project = await getAIJuniorProject({ projectHandle: entry.id })
          if (project.processingStatus && project.processingStatus !== 'processing') {
            entry.status = project.processingStatus
            entry.name = project.name || entry.name
          }
        } catch (error) {
          // Leave it pending; the next tick tries again.
        }
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.ai-junior-capture {
  max-width: 720px;
  margin: 0 auto;
  padding: 1rem 1rem 3rem;
}

.capture-header {
  text-align: center;
  margin-bottom: 1.2rem;

  h1 {
    font-size: 2.6rem;
    margin: 0 0 0.3rem;
  }

  p {
    font-size: 1.7rem;
    color: #555;
    margin: 0;
  }
}

.muted { color: #777; }

.error-text {
  color: #b3261e;
  font-size: 1.5rem;
  text-align: center;
  margin-top: 1rem;
}

.notice {
  text-align: center;
  padding: 4rem 1rem;
  font-size: 1.8rem;
}

.stage {
  position: relative;
  width: 100%;
  aspect-ratio: 3 / 4;
  background: #11141a;
  border-radius: 14px;
  overflow: hidden;

  video,
  .still,
  .overlay {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
  }

  video,
  .still {
    object-fit: contain;
  }

  .overlay {
    touch-action: none;
  }
}

@media (min-width: 720px) {
  .stage { aspect-ratio: 4 / 3; }
}

// The stage is near-black, so every piece of text inside it needs its colour
// stated on the element itself. Setting it on the container alone is not
// enough: the site's global stylesheet colours `p` directly, and an explicit
// rule beats an inherited value, which left dark text on a dark background.
.stage-empty {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  text-align: center;
  font-size: 1.6rem;

  p {
    color: #eef2f8;
    margin: 0;
  }

  .stage-empty-note {
    font-size: 1.3rem;
    color: #b9c2d0;
    margin-top: 0.8rem;
  }
}

.owner-name {
  color: #2c662d;
  font-weight: bold;
}

.status-line {
  text-align: center;
  font-size: 1.6rem;
  margin: 0.9rem 0 0;
  color: #2c662d;

  &.warn { color: #a15c00; }
}

.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 0.8rem;
  justify-content: center;
  margin-top: 1.2rem;
}

.btn-big {
  font-size: 1.7rem;
  padding: 0.9rem 1.6rem;
  border-radius: 10px;
  min-height: 52px;
}

.file-btn {
  display: inline-flex;
  align-items: center;
  margin: 0;
  cursor: pointer;

  input { display: none; }
}

.review {
  h2 {
    text-align: center;
    font-size: 2.2rem;
    margin: 0 0 0.3rem;
  }

  .muted {
    text-align: center;
    font-size: 1.5rem;
    margin: 0 0 1.2rem;
  }
}

.page-preview {
  border-radius: 12px;
  overflow: hidden;
  background: #fff;
  border: 1px solid #ddd;

  img {
    display: block;
    width: 100%;
  }
}

.thumbs {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 0.8rem;
  margin-top: 1rem;
}

.thumb {
  margin: 0;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 0.4rem;
  background: #fff;

  img {
    display: block;
    width: 100%;
    border-radius: 4px;
  }

  figcaption {
    font-size: 1.2rem;
    color: #666;
    margin-top: 0.3rem;
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

.spinner {
  display: inline-block;
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  vertical-align: -2px;
}

@keyframes spin {
  100% { transform: rotate(360deg); }
}

.batch {
  margin-top: 1.6rem;
  border-top: 1px solid #e2e2e2;
  padding-top: 1rem;
}

.batch-heading {
  font-size: 1.4rem;
  color: #666;
  margin: 0 0 0.6rem;
  text-align: center;
}

.batch-strip {
  display: flex;
  gap: 0.6rem;
  overflow-x: auto;
  padding-bottom: 0.4rem;
}

.batch-item {
  position: relative;
  flex: 0 0 auto;
  width: 74px;
  height: 74px;
  border-radius: 10px;
  overflow: hidden;
  border: 2px solid #ddd;
  background: #fff;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  &.completed { border-color: #3ddc84; }
  &.failed { border-color: #d94a4a; }
}

.batch-status {
  position: absolute;
  right: 2px;
  bottom: 0;
  font-size: 1.3rem;
  line-height: 1;
  padding: 1px 5px;
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.6);
  color: #fff;
}

.batch-hint {
  text-align: center;
  font-size: 1.3rem;
  color: #888;
  margin: 0.5rem 0 0;
}
</style>
