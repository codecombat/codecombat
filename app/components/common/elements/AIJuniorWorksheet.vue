<script>
// import { getAIJuniorScenario } from 'core/api/ai-junior-scenarios'
import { createNewAIJuniorProject, processAIJuniorProject } from 'core/api/ai-junior-projects'
import QRCode from 'qrcode'
import { worksheetQRText } from 'lib/doc-capture/qr'
import { markedInline } from 'core/utils'

// Cap the canvas backing store resolution: sharp enough to print, small enough to submit.
const MAX_PIXEL_RATIO = 2

// Drop pointer samples closer together than this (in canvas pixels) so strokes stay small.
const MIN_POINT_DISTANCE = 1.5

// Never hand the AI a drawing narrower than this; a sketch box on a laptop can
// lay out at a few hundred pixels, which is too little for a model to follow.
const MIN_EXPORT_WIDTH = 1024

// Crayon-box colours, in place of a raw colour picker no child can aim at.
const PALETTE = [
  '#000000', '#e53935', '#fb8c00', '#fdd835', '#43a047',
  '#1e88e5', '#8e24aa', '#8d5524', '#f48fb1', '#ffffff',
]

const BRUSH_SIZES = [
  { label: 'Thin', width: 4 },
  { label: 'Medium', width: 9 },
  { label: 'Thick', width: 18 },
  { label: 'Fat', width: 32 },
]

// Injected into the page while a worksheet is mounted, so that printing yields exactly one sheet of
// paper at full size. It cannot live in the scoped styles below: it has to reach the surrounding page
// chrome, and it has to come back out again when the worksheet goes away.
const PRINT_CSS = `
@page {
  size: 11in 8.5in;
  margin: 0;
}

@media print {
  html, body {
    width: 11in;
    height: 8.5in;
    margin: 0 !important;
    padding: 0 !important;
    background: #fff !important;
    overflow: hidden;
  }

  #site-content-area, .style-flat {
    margin: 0 !important;
    padding: 0 !important;
  }

  body * {
    visibility: hidden;
  }

  .worksheet-outer-container, .worksheet-outer-container * {
    visibility: visible;
  }

  .worksheet-outer-container {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    /* scaleWorksheet() shrinks the sheet to fit the browser window; print it full size. */
    transform: none !important;
  }

  .no-print, nav#main-nav, footer#site-footer {
    display: none !important;
  }
}
`

export default Vue.extend({
  name: 'AIJuniorWorksheet',

  props: {
    slug: {
      type: String,
      required: false,
      default: null,
    },
    scenario: {
      type: Object,
      required: false,
      default: null,
    },
    // When given, the worksheet renders that project's answers instead of collecting new ones.
    project: {
      type: Object,
      required: false,
      default: null,
    },
    // When given (class printing), the QR code targets this student instead of
    // the viewing user, and their name pre-fills the name line.
    printUser: {
      type: Object,
      required: false,
      default: null,
    },
  },

  emits: ['process-project'],

  data: () => ({
    error: null,
    qrCodeUrl: '',
    styleElement: null,
    printStyleElement: null,
    PALETTE,
    BRUSH_SIZES,
    isDrawing: false,
    isErasing: false,
    currentColor: '#000000',
    lineWidth: 9,
    bigInputId: null,
    // { [inputId]: [stroke] } — undone strokes, so Undo is not a one-way door.
    redoStacks: {},
    canvasRefs: {},
    scale: 1,
    // { [inputId]: [{ color, width, erase, points: [{ x, y }] }] }, with points normalized to 0-1 so
    // that drawings survive canvas resizes and pixel ratio changes.
    strokes: {},
    activeStroke: null,
    activeInputId: null,
    pixelRatios: {},
    projectImages: {},
    projectName: '',
  }),

  computed: {
    me () {
      return me
    },

    // The editor passes `slug`, the scenario views only pass `scenario`, so fall back through both.
    scenarioSlug () {
      return this.slug || this.scenario?.slug || this.scenario?._id || null
    },

    readOnly () {
      return Boolean(this.project)
    },

    projectInputValues () {
      return this.project?.inputValues || {}
    },

    canProcessProject () {
      return this.readOnly && this.project.processingStatus === 'pending'
    },
  },

  watch: {
    scenario: {
      handler () {
        this.generateQRCode()
        this.updateDynamicCss()
        this.scaleWorksheet()
        this.initializeCanvases()
      },
      deep: true,
    },
    'scenario.inputCss': {
      handler (newCss) {
        this.updateDynamicCss(newCss)
      },
      immediate: true,
    },
    project () {
      this.initializeCanvases()
    },
    scale () {
      this.$nextTick(() => {
        Object.keys(this.canvasRefs).forEach(inputId => {
          this.initializeCanvas(inputId)
        })
      })
    },
  },

  mounted () {
    // TODO: data vs. prop, passing in slug vs. passing in scenario?
    // this.scenario = await getAIJuniorScenario({ scenarioHandle: this.slug || '' })

    // The scenario is normally handed to us fully loaded, in which case the watcher above never fires.
    // Kept off `data` deliberately: it holds a DOM node, and making Vue observe
    // one costs a deep walk of the whole element tree for no benefit.
    this.bigOverlayHome = null

    if (this.printUser) {
      this.projectName = this.printUser.name || [this.printUser.firstName, this.printUser.lastName].filter(Boolean).join(' ')
    }
    this.generateQRCode()
    this.updateDynamicCss()
    this.installPrintCss()
    this.scaleWorksheet()
    this.initializeCanvases()
    this.onResize = _.debounce(this.onResize, 100)
    window.addEventListener('resize', this.onResize)
  },

  beforeDestroy () {
    this.returnBigOverlay()
    if (this.styleElement) {
      this.styleElement.remove()
    }
    if (this.printStyleElement) {
      this.printStyleElement.remove()
    }
    window.removeEventListener('resize', this.onResize)
  },

  methods: {
    markedInline,

    async generateQRCode () {
      if (!this.scenarioSlug) { return }
      // Only a class print needs to name the child: the code says which sheet
      // belongs to whom. On a sheet printed for yourself the scanner is already
      // the owner, so leaving the id out shortens the payload enough to drop a
      // whole QR version — 25 modules instead of 29, for nothing.
      const userId = this.printUser?._id || null
      // A short uppercase code rather than the full path. It still resolves to
      // the scan flow — so a phone's own camera app lands in the right place —
      // but at a third of the characters and in QR's alphanumeric mode, which
      // between them make each printed module half as small again. On real
      // scans the previous code was landing at about two pixels per module and
      // never decoded once.
      const scenarioId = this.scenario?._id || this.scenarioSlug
      const url = worksheetQRText(window.location.origin, scenarioId, userId)
      try {
        // Printed at a fixed size, so what decides whether a phone can read it
        // is how few modules have to fit in that square. The default four-module
        // quiet zone is wider than it needs to be, and with the short payload
        // levels M and L land on the same 29-module symbol — so the stronger
        // error correction costs nothing.
        this.qrCodeUrl = await QRCode.toDataURL(url, { errorCorrectionLevel: 'M', margin: 2 })
      } catch (err) {
        console.error('Error generating QR code:', err)
      }
    },

    updateDynamicCss (newCss = this.scenario?.inputCss) {
      if (this.styleElement) {
        this.styleElement.remove()
      }

      if (newCss) {
        this.styleElement = document.createElement('style')
        this.styleElement.textContent = newCss
        document.head.appendChild(this.styleElement)
      }
    },

    installPrintCss () {
      if (this.printStyleElement) { return }
      this.printStyleElement = document.createElement('style')
      this.printStyleElement.setAttribute('data-ai-junior-worksheet-print', '')
      this.printStyleElement.textContent = PRINT_CSS
      document.head.appendChild(this.printStyleElement)
    },

    printWorksheet () {
      window.print()
    },

    scaleWorksheet () {
      const worksheet = this.$el
      if (!worksheet || !worksheet.style) { return }
      const container = $(worksheet).parent()
      const scaleX = container.width() / (11 * 96) // 11 inches * 96 pixels per inch
      const scaleY = container.height() / (8.5 * 96) // 8.5 inches * 96 pixels per inch
      const scale = Math.min(scaleX, scaleY)
      if (!(scale > 0)) { return } // Hidden or not laid out yet; leave the sheet alone
      this.scale = scale
      worksheet.style.transform = `scale(${scale})`
      worksheet.style.transformOrigin = 'top left'
    },

    initializeCanvases () {
      this.$nextTick(() => {
        for (const input of this.scenario?.inputs || []) {
          if (input.type === 'image-field') {
            this.initializeCanvas(input.id)
          }
        }
        this.loadProjectDrawings()
      })
    },

    initializeCanvas (inputId) {
      const canvasRef = this.$refs[`canvas-${inputId}`]
      const canvas = canvasRef && canvasRef[0]
      if (!canvas) { return }

      // The sheet is a fixed 11x8.5in that is only visually shrunk with a CSS transform, so size the
      // backing store from the untransformed layout box. Otherwise drawings made on a small screen
      // come out blurry when the worksheet is printed or reopened larger.
      const rect = canvas.getBoundingClientRect()
      const cssWidth = canvas.clientWidth || rect.width
      const cssHeight = canvas.clientHeight || rect.height
      if (!cssWidth || !cssHeight) { return }

      const ratio = Math.min(window.devicePixelRatio || 1, MAX_PIXEL_RATIO)
      canvas.width = Math.round(cssWidth * ratio)
      canvas.height = Math.round(cssHeight * ratio)

      this.canvasRefs[inputId] = canvas
      this.pixelRatios[inputId] = ratio
      if (!this.strokes[inputId]) {
        this.$set(this.strokes, inputId, [])
      }

      this.redrawCanvas(inputId)
    },

    // Load any drawings the student already submitted so we can paint them into the read-only sheet.
    loadProjectDrawings () {
      if (!this.readOnly) { return }
      for (const input of this.scenario?.inputs || []) {
        if (input.type !== 'image-field') { continue }
        const dataUrl = this.projectInputValues[input.id]
        if (!dataUrl || this.projectImages[input.id]) { continue }
        const image = new Image()
        image.onload = () => {
          this.projectImages[input.id] = image
          this.redrawCanvas(input.id)
        }
        image.onerror = () => console.error('Error loading project drawing for', input.id)
        image.src = dataUrl
      }
    },

    // Single source of truth for what is on a canvas: the submitted drawing, then the stroke model.
    redrawCanvas (inputId) {
      const canvas = this.canvasRefs[inputId]
      if (!canvas) { return }
      const ctx = canvas.getContext('2d')
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.globalCompositeOperation = 'source-over'
      ctx.clearRect(0, 0, canvas.width, canvas.height)

      const image = this.projectImages[inputId]
      if (image) {
        ctx.drawImage(image, 0, 0, canvas.width, canvas.height)
      }

      const ratio = this.pixelRatios[inputId] || 1
      for (const stroke of this.strokes[inputId] || []) {
        this.drawStroke(ctx, canvas, stroke, ratio)
      }
    },

    applyStrokeStyle (ctx, stroke, ratio) {
      ctx.lineJoin = 'round'
      ctx.lineCap = 'round'
      ctx.lineWidth = stroke.width * ratio
      ctx.strokeStyle = stroke.color
      ctx.fillStyle = stroke.color
      ctx.globalCompositeOperation = stroke.erase ? 'destination-out' : 'source-over'
    },

    drawStroke (ctx, canvas, stroke, ratio) {
      const points = stroke.points
      if (!points.length) { return }
      const width = canvas.width
      const height = canvas.height

      ctx.save()
      this.applyStrokeStyle(ctx, stroke, ratio)
      ctx.beginPath()
      if (points.length === 1) {
        // A single tap should still leave a dot
        ctx.arc(points[0].x * width, points[0].y * height, (stroke.width * ratio) / 2, 0, Math.PI * 2)
        ctx.fill()
      } else {
        // Smooth the sampled points by curving through the midpoints between them
        ctx.moveTo(points[0].x * width, points[0].y * height)
        for (let i = 1; i < points.length - 1; i++) {
          const midX = ((points[i].x + points[i + 1].x) / 2) * width
          const midY = ((points[i].y + points[i + 1].y) / 2) * height
          ctx.quadraticCurveTo(points[i].x * width, points[i].y * height, midX, midY)
        }
        const last = points[points.length - 1]
        ctx.lineTo(last.x * width, last.y * height)
        ctx.stroke()
      }
      ctx.restore()
    },

    // Paint only the newest piece of the stroke in progress, so drawing stays smooth on tablets.
    drawLatestSegment (inputId) {
      const canvas = this.canvasRefs[inputId]
      const stroke = this.activeStroke
      if (!canvas || !stroke) { return }
      const points = stroke.points
      const count = points.length
      if (count < 2) { return }

      const width = canvas.width
      const height = canvas.height
      const ctx = canvas.getContext('2d')
      ctx.save()
      this.applyStrokeStyle(ctx, stroke, this.pixelRatios[inputId] || 1)
      ctx.beginPath()
      if (count === 2) {
        ctx.moveTo(points[0].x * width, points[0].y * height)
        ctx.lineTo(((points[0].x + points[1].x) / 2) * width, ((points[0].y + points[1].y) / 2) * height)
      } else {
        const [previous, control, current] = points.slice(count - 3)
        ctx.moveTo(((previous.x + control.x) / 2) * width, ((previous.y + control.y) / 2) * height)
        ctx.quadraticCurveTo(control.x * width, control.y * height, ((control.x + current.x) / 2) * width, ((control.y + current.y) / 2) * height)
      }
      ctx.stroke()
      ctx.restore()
    },

    startDrawing (event, inputId) {
      if (this.readOnly) { return }
      const canvas = this.canvasRefs[inputId] || event.currentTarget
      if (!canvas) { return }
      event.preventDefault()

      // Capture the pointer so a stroke keeps going even if a finger wanders off the box
      if (event.pointerId != null && canvas.setPointerCapture) {
        try {
          canvas.setPointerCapture(event.pointerId)
        } catch (err) {
          // Some browsers throw if the pointer is already gone; drawing still works without capture
        }
      }

      if (!this.strokes[inputId]) {
        this.$set(this.strokes, inputId, [])
      }
      // A new mark is a new branch of history.
      if (this.redoCount(inputId)) { this.$set(this.redoStacks, inputId, []) }
      this.isDrawing = true
      this.activeInputId = inputId
      this.activeStroke = {
        color: this.currentColor,
        width: this.lineWidth * this.pressureScale(event),
        erase: this.isErasing,
        points: [this.getCoordinates(event, canvas)],
      }
      this.strokes[inputId].push(this.activeStroke)
    },

    draw (event, inputId) {
      if (!this.isDrawing || this.activeInputId !== inputId || !this.activeStroke) { return }
      const canvas = this.canvasRefs[inputId]
      if (!canvas) { return }
      event.preventDefault()

      const point = this.getCoordinates(event, canvas)
      const points = this.activeStroke.points
      const previous = points[points.length - 1]
      const dx = (point.x - previous.x) * canvas.width
      const dy = (point.y - previous.y) * canvas.height
      if (Math.sqrt((dx * dx) + (dy * dy)) < MIN_POINT_DISTANCE) { return }

      points.push(point)
      this.drawLatestSegment(inputId)
    },

    stopDrawing (event, inputId) {
      if (!this.isDrawing) { return }
      const drawnInputId = this.activeInputId
      const canvas = this.canvasRefs[drawnInputId]
      if (canvas && event?.pointerId != null && canvas.hasPointerCapture?.(event.pointerId)) {
        canvas.releasePointerCapture(event.pointerId)
      }

      this.isDrawing = false
      this.activeStroke = null
      this.activeInputId = null

      // Repaint from the model so what we submit matches it exactly
      this.redrawCanvas(drawnInputId)
    },

    // Stylus pressure, when there is a stylus. Mice and fingers report a flat
    // 0.5 (or 0), which must not silently halve every line, so only a real pen
    // is allowed to change the width.
    pressureScale (event) {
      if (event.pointerType !== 'pen') { return 1 }
      const pressure = typeof event.pressure === 'number' && event.pressure > 0 ? event.pressure : 0.5
      return 0.45 + pressure
    },

    // Normalized 0-1 coordinates within the canvas content box, so they stay valid whatever size the
    // canvas is drawn at. The bounding rect is the border box as it appears on screen, so back out both
    // the CSS transform that fits the sheet to the window and the canvas border.
    getCoordinates (event, canvas) {
      const rect = canvas.getBoundingClientRect()
      const shrinkX = canvas.offsetWidth ? rect.width / canvas.offsetWidth : 1
      const shrinkY = canvas.offsetHeight ? rect.height / canvas.offsetHeight : 1
      const width = canvas.clientWidth || rect.width
      const height = canvas.clientHeight || rect.height
      return Object.freeze({
        x: (((event.clientX - rect.left) / shrinkX) - canvas.clientLeft) / width,
        y: (((event.clientY - rect.top) / shrinkY) - canvas.clientTop) / height,
      })
    },

    // What actually gets sent to the AI. Two things matter beyond copying
    // pixels: the drawing canvas is transparent where nothing was drawn, and an
    // image model handed a transparent PNG has no page to reason about — the
    // same drawing on paper arrives as dark marks on white and is matched far
    // more faithfully. So composite onto white, and never send a thumbnail:
    // upscale small canvases so a rushed line still has strokes to follow.
    exportInputImage (inputId) {
      const canvas = this.canvasRefs[inputId]
      if (!canvas || !canvas.width || !canvas.height) { return null }
      const scale = Math.max(1, MIN_EXPORT_WIDTH / canvas.width)
      const out = document.createElement('canvas')
      out.width = Math.round(canvas.width * scale)
      out.height = Math.round(canvas.height * scale)
      const ctx = out.getContext('2d')
      ctx.fillStyle = '#ffffff'
      ctx.fillRect(0, 0, out.width, out.height)
      ctx.imageSmoothingQuality = 'high'
      ctx.drawImage(canvas, 0, 0, out.width, out.height)
      return out.toDataURL('image/png')
    },

    strokeCount (inputId) {
      return (this.strokes[inputId] || []).length
    },

    redoCount (inputId) {
      return (this.redoStacks[inputId] || []).length
    },

    undoStroke (inputId) {
      const strokes = this.strokes[inputId]
      if (!strokes || !strokes.length) { return }
      if (!this.redoStacks[inputId]) { this.$set(this.redoStacks, inputId, []) }
      this.redoStacks[inputId].push(strokes.pop())
      this.redrawCanvas(inputId)
    },

    redoStroke (inputId) {
      const redo = this.redoStacks[inputId]
      if (!redo || !redo.length) { return }
      if (!this.strokes[inputId]) { this.$set(this.strokes, inputId, []) }
      this.strokes[inputId].push(redo.pop())
      this.redrawCanvas(inputId)
    },

    clearCanvas (inputId) {
      const strokes = this.strokes[inputId] || []
      if (strokes.length) { this.$set(this.redoStacks, inputId, strokes.slice().reverse()) }
      this.$set(this.strokes, inputId, [])
      this.redrawCanvas(inputId)
    },

    toggleEraser () {
      this.isErasing = !this.isErasing
    },

    chooseColor (color) {
      this.currentColor = color
      this.isErasing = false
    },

    chooseWidth (width) {
      this.lineWidth = width
      this.isErasing = false
    },

    // --- draw big ---------------------------------------------------------
    // Strokes are stored in normalized 0-1 coordinates, so the same drawing can
    // be rendered into a canvas of any size. That makes a full-screen drawing
    // surface almost free: point the existing handlers at a big canvas, and the
    // small one on the sheet catches up when it closes.

    openBig (inputId) {
      if (this.readOnly) { return }
      this.bigInputId = inputId
      this.$nextTick(() => {
        // The sheet is a fixed 11x8.5in box that is scaled to fit with a CSS
        // transform and clips its overflow. `position: fixed` inside a
        // transformed ancestor resolves against that ancestor rather than the
        // viewport, so the overlay has to live on <body> while it is open.
        const overlay = this.$refs.bigOverlay
        if (overlay) {
          this.bigOverlayHome = overlay.parentNode
          document.body.appendChild(overlay)
        }
        this.initializeBigCanvas()
      })
    },

    initializeBigCanvas () {
      const canvas = this.$refs.bigCanvas
      if (!canvas) { return }
      const rect = canvas.getBoundingClientRect()
      if (!rect.width || !rect.height) { return }
      const ratio = Math.min(window.devicePixelRatio || 1, MAX_PIXEL_RATIO)
      canvas.width = Math.round(rect.width * ratio)
      canvas.height = Math.round(rect.height * ratio)
      // Standing in for the sheet's canvas means every existing pointer handler,
      // undo and colour change works in here with no duplicate code.
      this.canvasRefs[this.bigInputId] = canvas
      this.pixelRatios[this.bigInputId] = ratio
      this.redrawCanvas(this.bigInputId)
    },

    closeBig () {
      const inputId = this.bigInputId
      this.returnBigOverlay()
      this.bigInputId = null
      if (!inputId) { return }
      this.$nextTick(() => this.initializeCanvas(inputId))
    },

    // Hand the node back to the component before Vue tears it down; removing a
    // v-if element Vue no longer owns the parent of throws.
    returnBigOverlay () {
      const overlay = this.$refs.bigOverlay
      if (overlay && this.bigOverlayHome) {
        this.bigOverlayHome.appendChild(overlay)
      }
      this.bigOverlayHome = null
    },

    bigAspectRatio () {
      const input = (this.scenario?.inputs || []).find(i => i.id === this.bigInputId)
      if (!input) { return '4 / 3' }
      // The sheet is 11x8.5in, so a region's on-paper aspect is its percentage
      // box scaled by the page's own proportions.
      const w = (input.width || 40) * 11
      const h = (input.height || 40) * 8.5
      return `${w} / ${h}`
    },

    onResize () {
      this.scaleWorksheet()
      this.$nextTick(() => {
        Object.keys(this.canvasRefs).forEach(inputId => {
          this.initializeCanvas(inputId)
        })
      })
    },

    projectValue (inputId) {
      return this.projectInputValues[inputId] || ''
    },

    isChoiceSelected (input, choiceId) {
      return this.readOnly && this.projectValue(input.id) === choiceId
    },

    isFreeChoiceSelected (input) {
      const value = this.projectValue(input.id)
      return Boolean(this.readOnly && value && !(input.choices || []).some(choice => choice.id === value))
    },

    freeChoiceText (input) {
      return this.isFreeChoiceSelected(input) ? this.projectValue(input.id) : ''
    },

    async submitWorksheet () {
      if (this.readOnly) { return }
      const inputValues = {}
      // Collect input fields' values
      for (const input of this.scenario.inputs) {
        if (input.type === 'label') {
          // Ignore label type inputs
          continue
        }
        if (input.type === 'checkbox' || input.type === 'radio') {
          let selectedValue = document.querySelector(`input[name="${input.id}"]:checked`)?.value
          if (selectedValue === 'other') {
            selectedValue = document.querySelector(`input#${input.id}-free-choice-text`)?.value
          }
          inputValues[input.id] = selectedValue || ''
        } else if (input.type === 'image-field') {
          const dataUrl = this.exportInputImage(input.id)
          if (dataUrl) {
            inputValues[input.id] = dataUrl
          } else {
            console.error('No canvas for', input.id, this.canvasRefs)
          }
        } else if (input.type === 'text-field') {
          const inputElement = document.getElementById(`${input.id}-text-field`)
          if (inputElement) {
            inputValues[input.id] = inputElement.value
          } else {
            console.error('No input element found for', input.id)
          }
        } else {
          const inputElement = document.getElementById(input.id)
          if (inputElement) {
            inputValues[input.id] = inputElement.value
          }
        }
      }

      if (!this.projectName) {
        window.alert('Please enter a project name.')
        return
      }

      const projectData = {
        scenarioId: this.scenario._id,
        userId: this.me.id,
        inputValues,
        name: this.projectName,
      }

      try {
        const project = await createNewAIJuniorProject(projectData)
        processAIJuniorProject({ projectHandle: project._id, force: true })
        // TODO: I had the new page start processing, but it wasn't set up right, so starting processing here, waiting a bit, and then opening it.
        _.delay(() => window.open(`/ai-junior/project/${this.scenarioSlug}/${this.me.id}/${project._id}`, '_blank'), 500)
      } catch (error) {
        console.error('Error submitting worksheet:', error)
        alert('An error occurred while submitting the worksheet. Please try again.')
      }
    },
  },
})
</script>

<template>
  <div class="worksheet-outer-container">
    <div
      v-if="scenario"
      class="worksheet-header-container"
    >
      <div class="scenario-name-container">
        <h1 class="scenario-name">
          {{ scenario.name || 'Untitled Worksheet' }}
        </h1>
        <br>
        <h2 class="scenario-name-subhead">
          with CodeCombat AI Junior
        </h2>
      </div>
      <div class="student-name-container">
        <h2 class="student-name-header">
          <span
            v-if="readOnly"
            class="student-name"
          >Name: {{ project.name || me.broadName() }}</span>
          <span
            v-else
            class="student-name-field"
          >
            <span class="student-name-label">Name: </span>
            <input
              v-model="projectName"
              type="text"
              class="student-name-input"
            >
          </span>
        </h2>
      </div>
      <p
        v-if="error"
        class="error"
      >
        Error: {{ error }}
      </p>
      <div class="worksheet-buttons no-print">
        <button
          class="worksheet-button"
          @click="printWorksheet"
        >
          Print
        </button>
        <button
          v-if="canProcessProject"
          class="worksheet-button"
          @click="$emit('process-project')"
        >
          Process
        </button>
        <button
          v-if="!readOnly"
          class="worksheet-button"
          @click="submitWorksheet"
        >
          Submit
        </button>
      </div>
      <img
        v-if="qrCodeUrl"
        :src="qrCodeUrl"
        class="qr-code"
      >
    </div>
    <div
      v-if="scenario"
      class="worksheet-inner-container"
    >
      <div
        v-for="input in scenario?.inputs || []"
        :id="input.id"
        :key="input.id"
        :class="`scenario-input scenario-input-${input.type}`"
        :style="`left: ${input.left}%; top: ${input.top}%; width: ${input.width}%; height: ${input.height}%;`"
      >
        <!-- eslint-disable vue/no-v-html -->
        <h3
          v-if="input.label"
          class="input-label"
        >
          <span>{{ input.label }}</span>
        </h3>
        <span
          v-if="input.text"
          class="input-text"
          v-html="markedInline(input.text)"
        />
        <div
          v-if="input.type === 'checkbox' || input.type === 'radio'"
          class="input-choices"
        >
          <div
            v-for="choice in input.choices"
            :key="choice.id"
            class="input-choice"
          >
            <input
              :id="`${input.id}-choice-${choice.id}`"
              :type="input.type"
              :name="input.id"
              :value="choice.id"
              :checked="isChoiceSelected(input, choice.id)"
              :disabled="readOnly"
            >
            <label :for="`${input.id}-choice-${choice.id}`">{{ choice.text }}</label>
          </div>
          <div
            v-if="input.freeChoice"
            class="input-free-choice"
          >
            <input
              :id="`${input.id}-free-choice`"
              :type="input.type"
              :name="input.id"
              value="other"
              :checked="isFreeChoiceSelected(input)"
              :disabled="readOnly"
            >
            <label :for="`${input.id}-free-choice`">Other:</label>
            <input
              v-if="readOnly"
              :id="`${input.id}-free-choice-text`"
              type="text"
              :name="`${input.id}-free-choice-text`"
              :value="freeChoiceText(input)"
              readonly
            >
            <input
              v-else
              :id="`${input.id}-free-choice-text`"
              type="text"
              :name="`${input.id}-free-choice-text`"
            >
          </div>
        </div>
        <div
          v-if="input.type === 'text-field'"
          class="input-text-field"
        >
          <textarea
            v-if="readOnly"
            :id="`${input.id}-text-field`"
            :name="input.id"
            :value="projectValue(input.id)"
            readonly
          />
          <textarea
            v-else
            :id="`${input.id}-text-field`"
            :name="input.id"
          />
        </div>
        <!-- eslint-enable vue/no-v-html -->
        <div
          v-if="input.type === 'image-field'"
          class="drawing-container"
        >
          <canvas
            :ref="`canvas-${input.id}`"
            class="drawing-canvas"
            :class="{ 'read-only': readOnly }"
            @pointerdown="startDrawing($event, input.id)"
            @pointermove="draw($event, input.id)"
            @pointerup="stopDrawing($event, input.id)"
            @pointercancel="stopDrawing($event, input.id)"
            @pointerleave="stopDrawing($event, input.id)"
          />
          <div
            v-if="!readOnly"
            class="drawing-controls no-print"
            :style="{ transform: `scale(${1/scale})`, transformOrigin: 'bottom left' }"
          >
            <button
              class="draw-big-button"
              @click="openBig(input.id)"
            >
              ✏️ Draw Big
            </button>
            <button
              :disabled="!strokeCount(input.id)"
              @click="undoStroke(input.id)"
            >
              Undo
            </button>
            <button
              :disabled="!redoCount(input.id)"
              @click="redoStroke(input.id)"
            >
              Redo
            </button>
            <button @click="clearCanvas(input.id)">
              Clear
            </button>
            <button
              :class="{ 'control-active': isErasing }"
              @click="toggleEraser"
            >
              Eraser
            </button>
          </div>
        </div>
      </div>
    </div>
    <div
      v-else
      class="loading-container"
    >
      <h1>Loading...</h1>
    </div>

    <!-- Full-screen drawing surface. Strokes live in normalized coordinates, so
         this edits the very same drawing the small box on the sheet shows. -->
    <div
      v-if="bigInputId"
      ref="bigOverlay"
      class="draw-big-overlay no-print"
    >
      <div class="draw-big-bar">
        <div class="draw-big-palette">
          <button
            v-for="color in PALETTE"
            :key="color"
            class="swatch"
            :class="{ 'swatch-active': !isErasing && currentColor === color, 'swatch-light': color === '#ffffff' }"
            :style="{ backgroundColor: color }"
            :aria-label="color"
            @click="chooseColor(color)"
          />
        </div>
        <div class="draw-big-brushes">
          <button
            v-for="brush in BRUSH_SIZES"
            :key="brush.width"
            class="brush"
            :class="{ 'brush-active': !isErasing && lineWidth === brush.width }"
            @click="chooseWidth(brush.width)"
          >
            <span
              class="brush-dot"
              :style="{ width: `${brush.width}px`, height: `${brush.width}px`, backgroundColor: isErasing ? '#bbb' : currentColor }"
            />
          </button>
          <button
            class="brush brush-eraser"
            :class="{ 'brush-active': isErasing }"
            @click="toggleEraser"
          >
            Eraser
          </button>
        </div>
        <div class="draw-big-actions">
          <button
            :disabled="!strokeCount(bigInputId)"
            @click="undoStroke(bigInputId)"
          >
            ↶ Undo
          </button>
          <button
            :disabled="!redoCount(bigInputId)"
            @click="redoStroke(bigInputId)"
          >
            ↷ Redo
          </button>
          <button @click="clearCanvas(bigInputId)">
            Clear
          </button>
          <button
            class="draw-big-done"
            @click="closeBig"
          >
            ✓ Done
          </button>
        </div>
      </div>
      <div class="draw-big-stage">
        <canvas
          ref="bigCanvas"
          class="draw-big-canvas"
          :style="{ aspectRatio: bigAspectRatio() }"
          @pointerdown="startDrawing($event, bigInputId)"
          @pointermove="draw($event, bigInputId)"
          @pointerup="stopDrawing($event, bigInputId)"
          @pointercancel="stopDrawing($event, bigInputId)"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
$paper-width: 11in;
$paper-height: 8.5in;
$top-margin: 0.5in;
$bottom-margin: 0.5in;
$left-margin: 0.5in;
$right-margin: 0.5in;
$header-height: 0.85in;
$input-border-size: 2px;
$input-size: 30px;
$input-margin-right: 5px;
$label-font-size: 18px;
$input-text-font-size: 18px;

@mixin checkbox-radio-style {
  -webkit-appearance: none; /* Remove default appearance */
  -moz-appearance: none; /* Remove default appearance */
  appearance: none; /* Remove default appearance */
  width: $input-size;
  height: $input-size;
  min-width: $input-size;
  min-height: $input-size;
  border: $input-border-size solid #000; /* Black border */
  margin-right: $input-margin-right;
  margin-top: 0;

  &:checked {
    background-color: #000; /* Black background when checked */
  }
}

@mixin label-style {
  font-size: $label-font-size;
  line-height: $input-size;
  margin: 0;
}

.worksheet-outer-container {
  width: $paper-width;
  height: $paper-height;
  position: relative;
  background-color: white;
  border: 4px solid black;
  overflow: hidden;
}

.worksheet-header-container {
  position: absolute;
  top: $top-margin;
  left: $left-margin;
  right: $right-margin;
  width: calc(100% - #{$left-margin} - #{$right-margin});
  height: $header-height;
}

.worksheet-inner-container {
  position: absolute;
  top: calc(#{$top-margin} + #{$header-height});
  bottom: $bottom-margin;
  left: $left-margin;
  right: $right-margin;
  width: calc(100% - #{$left-margin} - #{$right-margin});
  height: calc(100% - #{$top-margin} - #{$header-height} - #{$bottom-margin});
}

.scenario-name-container {
  display: inline-block;
  text-align: right;
  margin-right: 5%;
}

.scenario-name {
  display: inline-block;
  margin-bottom: -3%;
  margin-top: -3%;
  font-size: 40px;
  font-weight: bold;
}

.scenario-name-subhead {
  display: inline-block;
  margin-top: -1%;
  font-size: 24px;
}

.student-name-container {
  width: 37%;
  top: 45%;
  right: 13%;
  position: absolute;
  display: inline-block;
}

.student-name {
  display: inline;
  font-weight: lighter;
}

h2.student-name-header {
  font-size: 24px;
  text-align: right;
}

.student-name-field {
  display: flex;
  width: 100%;
  align-items: center;

  .student-name-label {
    display: flex;
    flex-grow: 0;
  }

  .student-name-input {
    flex-grow: 1;
    border: none;
    border-bottom: 2px solid black;
    padding: 5px 5px 0 5px;
    margin-left: 8px;
    font-size: $label-font-size;
    line-height: 0em; /* Height of the underline */
    width: auto; /* Adjust width to take remaining space */
  }
}

.error {
  color: red;
  text-align: center;
}

// A code sized to the header came out around 0.85in, which at normal scanning
// distance is roughly two pixels per module — right at the edge of unreadable.
// It grows *upward* into the half-inch page margin above the header rather than
// downward: below the header is where scenarios put their fields, and a bigger
// code there silently covered an answer box on five of nine worksheets. Ending
// flush with the bottom of the header keeps it clear of every field.
// Sized for the camera, not for the header.
//
// The printed code is what decides whether a phone can read the sheet, and
// measured on real captures it was landing at about two pixels per module —
// below what any decoder manages. It now starts just inside the top edge of the
// paper and runs 1.8in square: up through the whole half-inch page margin, and
// about half an inch down into the content area.
//
// That last part is a real claim on the sheet, so scenarios must keep their
// fields clear of the top-right corner. WORKSHEET_QR_FOOTPRINT below says how
// much, checkAIJuniorWorksheetLayout enforces it, and fitScenariosAroundQR
// moved the existing scenarios out of the way.
// Percentages are of the header band ($header-height: 0.85in):
//   top    -(0.5in margin - 0.05in bleed) / 0.85in = -52.9%
//   height  1.8in / 0.85in                         = 211.8%
.qr-code {
  position: absolute;
  top: -52.9%;
  right: 0;
  height: 211.8%;
  width: auto;
}

.scenario-input {
  position: absolute;
  /* border: 1px dotted #ccc; */

  // A label above a drawing box used to sit on top of a `height: 100%` drawing
  // container, so the box overflowed its own border by the height of the label
  // and the toolbar landed outside the frame. Lay it out as a column instead
  // and let the canvas take whatever room is left.
  &.scenario-input-image-field {
    border: 4px solid black;
    display: flex;
    flex-direction: column;
    overflow: hidden;

    .input-label {
      flex: 0 0 auto;
      text-align: center;
      color: #888;
      margin: 2px 0 0;
    }

    .input-text {
      flex: 0 0 auto;
      display: block;
      text-align: center;
      font-size: 15px;
      color: #888;
    }

    .drawing-container {
      flex: 1 1 auto;
      height: auto;
      min-height: 0;
    }
  }

  &.scenario-input-label {
    .input-label {
      margin: 0 0 2px;
      font-size: 21px;
    }

    .input-text {
      display: block;
      font-size: $input-text-font-size;
      line-height: 1.3;
    }
  }

  // Text fields had no styles at all: the textarea fell back to its browser
  // default size and spilled out of the box it was given.
  &.scenario-input-text-field {
    display: flex;
    flex-direction: column;

    .input-label {
      flex: 0 0 auto;
      margin: 0 0 2px;
      font-size: 21px;
      font-weight: bold;
    }

    .input-text {
      flex: 0 0 auto;
      display: block;
      font-size: $input-text-font-size;
      line-height: 1.3;
    }

    // An outlined box, so the field reads as somewhere to write. Ruled lines
    // alone are not enough: they are a background image, and browsers drop
    // background images when printing unless told otherwise, which left a blank
    // gap on paper that children skipped straight past. The border always
    // prints; print-color-adjust keeps the rules as well where it is honoured.
    .input-text-field {
      flex: 1 1 auto;
      min-height: 0;
      margin-top: 6px;
      border: 2px solid #000;
      border-radius: 6px;
      padding: 3px 6px;
      overflow: hidden;
    }

    textarea {
      display: block;
      width: 100%;
      height: 100%;
      resize: none;
      box-sizing: border-box;
      border: none;
      padding: 0 2px;
      font-size: 22px;
      background-color: transparent;
      line-height: 34px;
      background-image: repeating-linear-gradient(
        to bottom,
        transparent 0,
        transparent 32px,
        #bbb 32px,
        #bbb 33px
      );
      print-color-adjust: exact;
      -webkit-print-color-adjust: exact;

      &:focus {
        outline: none;
      }
    }
  }

  &.scenario-input-checkbox,
  &.scenario-input-radio {
    .input-label {
      display: inline-block;
      font-weight: bold;
      margin-right: 10px;
      margin-bottom: 0;
    }

    .input-text {
      display: inline-block;
      font-weight: normal;
      font-size: $input-text-font-size;
      font-style: italic;
    }

    .input-choices {
      display: flex;
      flex-wrap: wrap;
      margin-top: 10px;

      .input-choice {
        display: flex;
        align-items: center;
        margin-right: 15px;
        margin-bottom: 5px;

        input[type="checkbox"],
        input[type="radio"] {
          @include checkbox-radio-style;
        }

        label {
          @include label-style;
        }
      }
    }

    .input-free-choice {
      display: flex;
      align-items: center;
      flex-grow: 1; /* Allow it to take up remaining space */

      input[type="checkbox"], input[type="radio"] {
        @include checkbox-radio-style;
      }

      label {
        margin-right: 10px;
        @include label-style;
      }

      input[type="text"] {
        /* flex-basis 0 + min-width 0 so the underline shrinks to fit narrow
           boxes instead of overflowing at the browser's ~20ch default size */
        flex: 1 1 0;
        min-width: 40px;
        border: none;
        border-bottom: 2px solid black;
        padding: 5px 5px 0 5px;
        margin-left: 8px;
        font-size: $input-text-font-size;
        line-height: 1.5em; /* Height of the underline */
      }
    }
  }
}

.drawing-container {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.drawing-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: 1px solid #ccc;
  cursor: crosshair;
  touch-action: none; /* Draw with a finger without scrolling the page */

  &.read-only {
    pointer-events: none;
    cursor: default;
  }
}

.draw-big-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  background: #2b2f38;
  display: flex;
  flex-direction: column;
}

.draw-big-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 1.2rem;
  padding: 0.8rem 1rem;
  background: #1e222a;
}

.draw-big-palette {
  display: flex;
  gap: 0.5rem;
}

.swatch {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 3px solid transparent;
  padding: 0;
  cursor: pointer;

  &.swatch-light {
    border-color: #8a90a0;
  }

  &.swatch-active {
    border-color: #fff;
    box-shadow: 0 0 0 3px #4a9cff;
  }
}

.draw-big-brushes,
.draw-big-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.brush {
  min-width: 48px;
  height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  border: 2px solid #464c5a;
  background: #2b303a;
  color: #dfe3ea;
  font-size: 1.3rem;
  cursor: pointer;

  &.brush-active {
    border-color: #4a9cff;
    background: #10305c;
  }
}

.brush-dot {
  display: block;
  border-radius: 50%;
  max-width: 32px;
  max-height: 32px;
}

.draw-big-actions button {
  height: 44px;
  padding: 0 1rem;
  border-radius: 10px;
  border: 2px solid #464c5a;
  background: #2b303a;
  color: #dfe3ea;
  font-size: 1.4rem;
  cursor: pointer;

  &:disabled {
    opacity: 0.4;
    cursor: default;
  }

  &.draw-big-done {
    border-color: #3ddc84;
    background: #10402a;
    color: #d6ffe8;
    font-weight: bold;
  }
}

.draw-big-stage {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.draw-big-canvas {
  max-width: 100%;
  max-height: 100%;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.45);
  touch-action: none;
  cursor: crosshair;
}

.drawing-controls {
  position: absolute;
  bottom: 10px;
  left: 10px;
  right: 10px;
  display: flex;
  flex-wrap: wrap; /* small sketch boxes get two rows of controls, not clipped ones */
  gap: 6px 10px;
  align-items: center;

  button, input {
    font-size: 14px;
    padding: 0px;
    border: 0;
    background-color: transparent;
  }

  button {
    flex: 0 0 auto;

    &:disabled {
      opacity: 0.4;
      cursor: default;
    }

    &.control-active {
      font-weight: bold;
      text-decoration: underline;
    }

    &.draw-big-button {
      font-weight: bold;
      color: #1565c0;
    }
  }

  input {
    height: 30px;
  }

  /* Styles for the range input */
  input[type="range"] {
    -webkit-appearance: none;
    width: 80px;
    height: 30px;
    background: transparent;
    padding: 0;
    margin: 0;
  }

  /* Styles for the range input thumb */
  input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none;
    height: 20px;
    width: 20px;
    border-radius: 50%;
    background: #007bff;
    cursor: pointer;
    margin-top: -5px; /* Offset to center the thumb on the track */
  }

  input[type="range"]::-moz-range-thumb {
    height: 30px;
    width: 30px;
    border-radius: 50%;
    background: #007bff;
    cursor: pointer;
  }

  /* Styles for the range input track */
  input[type="range"]::-webkit-slider-runnable-track {
    width: 100%;
    height: 10px;
    background: #ddd;
    border-radius: 5px;
  }

  input[type="range"]::-moz-range-track {
    width: 100%;
    height: 10px;
    background: #ddd;
    border-radius: 5px;
  }

  /* Focus styles */
  input[type="range"]:focus {
    outline: none;
  }

  input[type="range"]:focus::-webkit-slider-thumb {
    box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.25);
  }

  input[type="range"]:focus::-moz-range-thumb {
    box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.25);
  }
}

.worksheet-buttons {
  position: absolute;
  top: -40px;
  right: 0px; // Positioned above the QR code
  display: flex;
  gap: 8px;
  z-index: 10;
}

.worksheet-button {
  padding: 5px 8px;
  background-color: #007bff;
  color: white;
  border: none;
  cursor: pointer;
  font-size: 16px;

  &:hover {
    background-color: #0056b3;
  }
}

@media print {
  .no-print {
    display: none !important;
  }

  .worksheet-outer-container {
    /* Keep checked boxes and drawings black rather than dropping the backgrounds */
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* An empty name box should print as a blank line to write on */
  .student-name-field .student-name-input {
    -webkit-appearance: none;
    appearance: none;
    background: transparent !important;
    border: none !important;
    border-bottom: 2px solid #000 !important;
    border-radius: 0;
    height: 1.5em;
    line-height: 1.5em;
  }
}
</style>
