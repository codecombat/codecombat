<template>
  <div class="ai-junior-project-output">
    <div
      v-if="isFailed"
      class="failed"
    >
      <h3>😿 Something went wrong</h3>
      <p>Processing failed. Please try again.</p>
      <p
        v-if="project.processingError"
        class="processing-error"
      >
        {{ project.processingError }}
      </p>
      <button
        v-if="!hideReprocessButton"
        class="btn btn-primary"
        @click="$emit('reprocess-project')"
      >
        Try Again
      </button>
    </div>

    <template v-else>
      <div
        v-if="isProcessing"
        class="processing"
      >
        <p class="processing-message">
          {{ processingMessage }}
        </p>
        <div
          class="progress-track"
          role="progressbar"
          :aria-valuenow="Math.round(progress * 100)"
          aria-valuemin="0"
          aria-valuemax="100"
        >
          <div
            class="progress-fill"
            :class="{ stalled: isStalled }"
            :style="{ width: `${(progress * 100).toFixed(1)}%` }"
          />
        </div>
        <p class="processing-elapsed">
          {{ elapsedLabel }}
        </p>

        <div
          v-if="isStalled"
          class="stalled-note"
        >
          <p>This is taking longer than it should. It may have got stuck.</p>
          <button
            v-if="!hideReprocessButton"
            class="btn btn-primary"
            @click="$emit('reprocess-project')"
          >
            Start it again
          </button>
        </div>
      </div>

      <!-- The creation itself. Exactly one canonical rendering: the scenario's
           own output template when it has one, otherwise the generated images.
           Anything the template does not reference is shown underneath, so a
           multi-image scenario still surfaces every image without the single
           `<img>` scenarios rendering their picture twice. -->
      <div
        class="creation-layout"
        :class="{ 'with-original': isCompleted && originals.length }"
      >
        <div class="creation">
          <!-- A creation that is only the generated picture: the scenario's
               template is a bare <img> around it, so the iframe adds nothing.
               The slider takes its place — identical at rest, comparable
               without a detour through a button, and something the reveal can
               actually animate. -->
          <div
            v-if="creationComparison && !showCompare"
            class="project-preview"
          >
            <ImageCompareSlider
              :original="creationComparison.original"
              :generated="creationComparison.generated"
              :original-label="creationComparison.originalLabel"
              generated-label="Your creation"
              auto-reveal
            />
          </div>

          <div
            v-else-if="hasPreview && !showCompare"
            class="project-preview"
          >
            <div
              ref="previewWrap"
              class="preview-wrap"
              @mouseenter="focusPreview"
              @pointerdown="focusPreview"
            >
              <iframe
                ref="previewFrame"
                :key="compiledOutput"
                :srcdoc="compiledOutput"
                class="preview-frame"
                allow="fullscreen"
                @load="onPreviewLoad"
              />
            </div>
          </div>

          <!-- Compare replaces the preview rather than sitting beside it: the
               slider already shows the finished picture at rest, so rendering
               both would just be the same creation twice. -->
          <div
            v-if="showCompare"
            class="comparisons"
          >
            <div
              v-for="comparison in previewComparisons"
              :key="`compare-${comparison.promptId}`"
              class="comparison"
            >
              <ImageCompareSlider
                :original="comparison.original"
                :generated="comparison.generated"
                :original-label="comparison.originalLabel"
                generated-label="Your creation"
              />
            </div>
          </div>

          <div
            v-for="(item, index) in unreferencedItems"
            :key="item.promptId"
            class="response-image"
          >
            <!-- Where the generated image is shown on its own, the slider is
                 that image — it rests fully on the generated side — so it costs
                 nothing to make it draggable. -->
            <!-- A row of sprites cascades rather than sweeping in unison,
                 which reads as one effect instead of three collisions. -->
            <ImageCompareSlider
              v-if="item.comparison"
              :original="item.comparison.original"
              :generated="item.comparison.generated"
              :original-label="item.comparison.originalLabel"
              generated-label="Your creation"
              auto-reveal
              :reveal-delay="index * 180"
            />
            <a
              v-else
              :href="item.image"
              target="_blank"
              rel="noopener"
              title="Open full size"
            >
              <img
                :src="item.image"
                :alt="item.promptId"
              >
            </a>
          </div>

          <div
            v-if="showCreationActions"
            class="creation-actions no-print"
          >
            <button
              v-if="hasPreview && !showCompare && !creationComparison"
              class="btn btn-default"
              @click="fullscreenPreview"
            >
              ⛶ Fullscreen
            </button>
            <button
              v-if="canCompare"
              class="btn btn-default"
              @click="showCompare = !showCompare"
            >
              {{ showCompare ? '🖼 Your creation' : '↔ Compare' }}
            </button>
            <a
              v-for="response in imageResponses"
              :key="`dl-${response.promptId}`"
              class="btn btn-default"
              :href="response.image"
              :download="downloadName(response)"
            >⬇ Download{{ imageResponses.length > 1 ? ` ${response.promptId}` : '' }}</a>
            <button
              v-if="canShare"
              class="btn btn-primary"
              @click="showShare = !showShare"
            >
              🔗 Share
            </button>
            <button
              v-if="!hideReprocessButton"
              class="btn btn-default"
              @click="$emit('reprocess-project')"
            >
              🔁 Remake It
            </button>
          </div>
        </div>

        <!-- What the child actually made, beside what it became rather than far
             below it, so a wide screen shows the before and after together. -->
        <aside
          v-if="isCompleted && originals.length"
          class="originals"
        >
          <h4 class="originals-heading">
            {{ originalsHeading }}
          </h4>
          <figure
            v-for="original in originals"
            :key="original.id"
            class="original"
          >
            <a
              :href="original.src"
              target="_blank"
              rel="noopener"
              title="Open full size"
            >
              <img
                :src="original.src"
                :alt="original.label"
              >
            </a>
            <figcaption>{{ original.label }}</figcaption>
          </figure>
        </aside>
      </div>

      <AIJuniorShareBox
        v-if="showShare && canShare"
        :project="project"
        class="no-print"
        @shared="onShared"
      />

      <div
        v-if="isCompleted && !hideReprocessButton"
        class="details-toggle no-print"
      >
        <button
          class="btn btn-link btn-sm"
          @click="showDetails = !showDetails"
        >
          {{ showDetails ? 'Hide' : 'Show' }} Details
        </button>
      </div>

      <div
        v-if="showDetails"
        class="details"
      >
        <div
          v-for="response in project.promptResponses"
          :key="`detail-${response.promptId}`"
          class="detail-response"
        >
          <h5>{{ response.promptId }} <span class="detail-time">({{ responseSeconds(response) }}s)</span></h5>
          <pre>{{ response.text }}</pre>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import compileTemplate from 'lodash-4/template'
import AIJuniorShareBox from './AIJuniorShareBox.vue'
import ImageCompareSlider from './ImageCompareSlider.vue'

// Simple `<%= name %>` interpolations, which is all scenario outputs use.
// Declared with the `g` flag but only ever used via matchAll, which does not
// carry lastIndex between calls.
const TEMPLATE_IDENTIFIER = /<%[=-]?\s*([A-Za-z_$][\w$]*)\s*%>/g

// Past this, and past a multiple of the scenario's own estimate, a run is
// treated as stuck rather than slow.
const STALL_SECONDS = 240

const PROCESSING_MESSAGES = [
  'Reading your worksheet…',
  'Imagining your creation…',
  'Painting the pictures…',
  'Adding the finishing touches…',
  'Almost there…',
]

export default {
  name: 'AIJuniorProjectOutput',
  components: {
    AIJuniorShareBox,
    ImageCompareSlider,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    scenario: {
      type: Object,
      required: true,
    },
    hideReprocessButton: {
      type: Boolean,
      default: false,
    },
    // Public share pages render the same creation but must not offer owner-only
    // actions (re-share, remake, details).
    readOnly: {
      type: Boolean,
      default: false,
    },
  },
  data () {
    return {
      showDetails: false,
      showShare: false,
      showCompare: false,
      elapsedSeconds: 0,
      // Reactive clock, so the progress bar keeps easing forward between polls
      // rather than only moving when a prompt finishes.
      nowMs: Date.now(),
      elapsedTimer: null,
    }
  },
  computed: {
    isProcessing () {
      const status = this.project.processingStatus
      return status === 'processing' || status === 'pending' || !status
    },
    isCompleted () {
      return this.project.processingStatus === 'completed'
    },
    isFailed () {
      return this.project.processingStatus === 'failed'
    },
    imageResponses () {
      return (this.project.promptResponses || []).filter((r) => r.image)
    },
    // Everything the output templates interpolate, so the preview can tell
    // whether it has enough to render.
    templateNames () {
      const output = this.scenario.output || {}
      const names = new Set()
      for (const template of [output.html, output.css, output.js]) {
        for (const match of String(template || '').matchAll(TEMPLATE_IDENTIFIER)) names.add(match[1])
      }
      return [...names]
    },
    // Wait for every referenced value before showing the preview. Rendering it
    // half-finished turns `<img src="<%= characterImage %>">` into an empty
    // `<img src="">` — a broken-image dot in a big empty frame — while the
    // image prompt is still running. Until then the generated images appear on
    // their own as they arrive, which is the progressive behaviour we want.
    previewReady () {
      if (!this.scenario.output?.html) return false
      // Once the run is finished, render whatever there is: a blank field the
      // child chose not to fill in is a real answer, and waiting on it forever
      // would mean never showing the creation at all.
      if (!this.isProcessing) return true
      return this.templateNames.every((name) => {
        const value = this.templateContext[name]
        return value != null && value !== ''
      })
    },
    hasPreview () {
      return this.previewReady
    },
    // Images the scenario's output template already puts on screen. Rendering
    // these again above the preview is what made every result appear twice.
    unreferencedImages () {
      if (!this.hasPreview) return this.imageResponses
      return this.imageResponses.filter((response) => !this.templateNames.includes(response.promptId))
    },
    // Each generated image beside the drawing it was made from. A prompt's
    // `files` names the image fields it was shown; a prompt without one is
    // shown every drawing, so the first it could have used is the fair match.
    comparisons () {
      if (!this.isCompleted || !this.drawings.length) return []
      const pairs = []
      for (const response of this.imageResponses) {
        const prompt = (this.scenario.prompts || []).find((p) => p.id === response.promptId)
        const wanted = Array.isArray(prompt?.files) ? prompt.files : this.drawings.map((drawing) => drawing.id)
        const drawing = this.drawings.find((candidate) => wanted.includes(candidate.id))
        if (!drawing) continue
        pairs.push({
          promptId: response.promptId,
          generated: response.image,
          original: drawing.src,
          originalLabel: drawing.label,
          drawingId: drawing.id,
        })
      }
      return pairs
    },
    comparisonByPromptId () {
      return Object.fromEntries(this.comparisons.map((comparison) => [comparison.promptId, comparison]))
    },
    // The images shown on their own, each carrying the drawing it came from so
    // the slider can stand in for a plain `<img>` wherever there is one.
    unreferencedItems () {
      return this.unreferencedImages.map((response) => ({
        promptId: response.promptId,
        image: response.image,
        comparison: this.comparisonByPromptId[response.promptId] || null,
      }))
    },
    // Comparisons for images the output template renders itself. Those live
    // inside the preview iframe and cannot be slid over there, so comparing
    // them swaps the preview out for the sliders instead.
    previewComparisons () {
      if (!this.hasPreview) return []
      return this.comparisons.filter((comparison) => this.templateNames.includes(comparison.promptId))
    },
    // A creation the scenario renders as nothing but the generated image. Its
    // template contributes only the `<img>` tag, which the slider already is,
    // so the iframe is pure overhead — and a picture inside an iframe cannot
    // be compared or swept.
    creationComparison () {
      if (!this.hasPreview) return null
      const html = String(this.scenario.output?.html || '').trim()
      const bareImage = html.match(/^<img\b[^>]*\bsrc\s*=\s*["']?<%[=-]?\s*([A-Za-z_$][\w$]*)\s*%>["']?[^>]*>$/i)
      if (!bareImage) return null
      return this.comparisonByPromptId[bareImage[1]] || null
    },
    canCompare () {
      // Pointless where the creation is already the slider.
      if (this.creationComparison) return false
      return this.isCompleted && this.previewComparisons.length > 0
    },
    showCreationActions () {
      return this.isCompleted && (this.hasPreview || this.imageResponses.length)
    },
    // Auto-focusing is right for something interactive and wrong for a picture,
    // where stealing focus would just scroll the page down to the iframe.
    isGameLike () {
      const output = this.scenario.output || {}
      return /<canvas|addEventListener|requestAnimationFrame/i.test(`${output.html || ''}${output.js || ''}`)
    },
    canShare () {
      return !this.readOnly && this.isCompleted && Boolean(this.project._id)
    },
    // The child's own work. A scanned project has both the whole page and the
    // cropped drawing, and showing both means showing the same drawing twice —
    // the page already contains it — so the page wins when it exists. Only an
    // on-screen drawing, which has no page, falls back to the crops.
    // The drawings themselves, one per image field the child filled in. A
    // scanned project has these as crops of the page as well as the page.
    drawings () {
      const items = []
      const inputValues = this.project.inputValues || {}
      for (const input of this.scenario.inputs || []) {
        if (input.type !== 'image-field') continue
        const value = inputValues[input.id]
        if (typeof value !== 'string' || !value) continue
        const src = value.startsWith('data:') || value.startsWith('/') ? value : `/file/${value}`
        items.push({ id: input.id, label: input.label || input.text || 'What you drew', src })
      }
      return items
    },
    // Drawings already on screen inside a slider, which the aside would
    // otherwise show a second time.
    comparedDrawingIds () {
      const shownInline = new Set(this.unreferencedItems.filter((item) => item.comparison).map((item) => item.comparison.drawingId))
      return shownInline
    },
    originals () {
      if (this.project.uploadedWorksheet) {
        return [{ id: 'worksheet', label: 'Your worksheet', src: `/file/${this.project.uploadedWorksheet}` }]
      }
      return this.drawings.filter((drawing) => !this.comparedDrawingIds.has(drawing.id))
    },
    originalsHeading () {
      return this.originals.length === 1 && this.originals[0].id === 'worksheet'
        ? 'Made from your worksheet'
        : 'Made from your drawing'
    },
    processingMessage () {
      if (this.isStalled) return 'Still waiting…'
      const doneCount = (this.project.promptResponses || []).length
      const index = Math.min(doneCount + Math.floor(this.elapsedSeconds / 25), PROCESSING_MESSAGES.length - 1)
      return PROCESSING_MESSAGES[index]
    },
    // Rough seconds per prompt, from measured runs: gemini image ~15-20s,
    // opus writing a game ~35-45s, sonnet reading a sketch ~15s. Only the
    // ratios really matter — they decide how much of the bar each step is
    // worth — and the easing below absorbs a step that runs long.
    promptWeights () {
      const weights = (this.scenario.prompts || []).map((prompt) => {
        const model = String(prompt.model || '')
        if (/image/.test(model)) return /gemini/.test(model) ? 18 : 45
        if (/opus/.test(model)) return 45
        if (/haiku/.test(model)) return 10
        if (/sonnet|^gpt-/.test(model)) return 15
        return 25
      })
      // A scanned worksheet is read by a vision pass before any prompt runs,
      // which is real time the bar should account for.
      if (weights.length && this.project.uploadedWorksheet) weights[0] += 10
      return weights
    },
    /**
     * A bar that behaves like it knows something, because it does: finished
     * prompts contribute their full share, and the one still running eases
     * toward its share on 1 - e^-t/estimate. That approaches its ceiling
     * without ever arriving, so the bar keeps creeping when a step runs long
     * instead of either sticking or claiming to be finished.
     */
    progress () {
      const weights = this.promptWeights
      if (!weights.length) return Math.min(0.9, this.elapsedSeconds / 90)
      const total = weights.reduce((sum, w) => sum + w, 0)
      const responses = this.project.promptResponses || []
      const doneCount = Math.min(responses.length, weights.length)

      let doneWeight = 0
      for (let i = 0; i < doneCount; i++) doneWeight += weights[i]

      if (doneCount >= weights.length) return 0.97

      // Time spent on the step currently running, measured from when the last
      // one finished rather than from the start of the whole run.
      const lastEnd = responses.length ? new Date(responses[responses.length - 1].endDate).getTime() : null
      const start = this.project.processingStartTime ? new Date(this.project.processingStartTime).getTime() : Date.now()
      const since = (this.nowMs - (lastEnd && !isNaN(lastEnd) ? lastEnd : start)) / 1000
      const current = weights[doneCount]
      const currentProgress = 1 - Math.exp(-Math.max(0, since) / current)

      return Math.max(0.02, Math.min(0.97, (doneWeight + current * currentProgress) / total))
    },
    estimatedTotalSeconds () {
      const weights = this.promptWeights
      return weights.length ? weights.reduce((sum, w) => sum + w, 0) : 90
    },
    elapsedLabel () {
      const remaining = Math.round(this.estimatedTotalSeconds - this.elapsedSeconds)
      if (this.isStalled) return `${this.elapsedSeconds}s elapsed`
      if (remaining > 5) return `${this.elapsedSeconds}s — about ${remaining}s to go`
      return `${this.elapsedSeconds}s — almost there`
    },
    // Long past any plausible finish. The server also fails a run that overruns,
    // but a server that was restarted mid-run leaves a project marked
    // "processing" for ever, and only the page is around to notice.
    isStalled () {
      return this.isProcessing && this.elapsedSeconds > Math.max(STALL_SECONDS, this.estimatedTotalSeconds * 4)
    },
    templateContext () {
      const context = { ...this.project.inputValues }
      for (const promptResponse of this.project.promptResponses || []) {
        context[promptResponse.promptId] = promptResponse.image || promptResponse.text
        // Text prompts respond with JSON objects; expose their keys to the
        // output templates just like the server exposes them to later prompts.
        if (!promptResponse.image && promptResponse.text) {
          try {
            const parsed = JSON.parse(promptResponse.text.replace(/^```(?:json)?\s*|```\s*$/g, ''))
            if (parsed && typeof parsed === 'object') Object.assign(context, parsed)
          } catch (err) {
            // Not JSON — leave the raw text mapping
          }
        }
      }
      return context
    },
    compiledOutput () {
      let { html, css, js } = this.scenario.output
      const context = this.templateContext
      // Compiled lodash templates run inside `with (data)`, so any name the
      // context is missing — an unticked radio, a prompt that has not finished
      // yet — throws and leaves the whole creation unrendered. Fill the gaps
      // with blanks first so a partial project still shows what it has.
      const render = (template) => {
        if (!template) return template
        const filled = { ...context }
        for (const match of template.matchAll(TEMPLATE_IDENTIFIER)) {
          if (filled[match[1]] == null) filled[match[1]] = ''
        }
        try {
          return compileTemplate(template)(filled)
        } catch (err) {
          console.log('Template context error:', err, template, filled)
          return ''
        }
      }
      html = render(html)
      css = render(css)
      js = render(js)
      // `.aij-fullscreen` is added to the iframe body while the preview is
      // fullscreen: inline the preview is measured and sized to its content,
      // but fullscreen it has to fill and centre inside a fixed viewport.
      const baseCss = `
        body { margin: 8px; font-family: sans-serif; }
        img { max-width: 100%; height: auto; }
        body.aij-fullscreen {
          margin: 0; width: 100vw; height: 100vh; background: #111;
          display: flex; align-items: center; justify-content: center; overflow: hidden;
        }
        body.aij-fullscreen > * { margin: 0 !important; }
        body.aij-fullscreen img, body.aij-fullscreen canvas, body.aij-fullscreen video {
          max-width: 100vw; max-height: 100vh; width: auto; height: auto; object-fit: contain;
        }
      `
      // eslint-disable-next-line no-useless-escape
      return `<html>\n  <head>\n    <style>${baseCss}</style>\n    <style>${css}</style>\n  </head>\n  <body>\n    ${html}\n    <script>${js}<\/script>\n  </body>\n</html>`
    },
  },
  watch: {
    isProcessing: {
      immediate: true,
      handler (processing) {
        if (processing && !this.elapsedTimer) {
          const start = this.project.processingStartTime ? new Date(this.project.processingStartTime).getTime() : Date.now()
          this.elapsedTimer = setInterval(() => {
            this.nowMs = Date.now()
            this.elapsedSeconds = Math.max(0, Math.round((this.nowMs - start) / 1000))
          }, 500)
        } else if (!processing && this.elapsedTimer) {
          clearInterval(this.elapsedTimer)
          this.elapsedTimer = null
        }
      },
    },
  },
  mounted () {
    document.addEventListener('fullscreenchange', this.onFullscreenChange)
    document.addEventListener('webkitfullscreenchange', this.onFullscreenChange)
  },
  beforeDestroy () {
    if (this.elapsedTimer) clearInterval(this.elapsedTimer)
    document.removeEventListener('fullscreenchange', this.onFullscreenChange)
    document.removeEventListener('webkitfullscreenchange', this.onFullscreenChange)
  },
  methods: {
    onPreviewLoad () {
      this.sizePreview()
      // A game listens for arrow keys inside the iframe, but an iframe receives
      // no key events until it has focus — so without this the keys go to the
      // page behind it and just scroll it. Hovering or touching the game hands
      // focus over, which is what a player does before pressing anything.
      if (this.isGameLike) this.focusPreview()
    },
    focusPreview () {
      const iframe = this.$refs.previewFrame
      try {
        iframe?.contentWindow?.focus()
      } catch (err) {
        // Nothing to do if focusing is refused; the game still plays by touch.
      }
    },
    // Size the preview iframe to its content so any scenario output — square
    // image, 800x500 game, multi-page story — displays without inner scrollbars.
    sizePreview () {
      const iframe = this.$refs.previewFrame
      if (!iframe) return
      try {
        const contentHeight = iframe.contentDocument.body.scrollHeight
        const maxHeight = Math.round(window.innerHeight * 0.85)
        iframe.style.height = `${Math.min(Math.max(contentHeight + 24, 240), maxHeight)}px`
      } catch (err) {
        iframe.style.height = '600px'
      }
    },
    // Fullscreen the wrapper rather than the iframe itself: an iframe made
    // fullscreen keeps whatever width/height it was given, so the page ended up
    // letterboxed in the corner instead of covering the screen.
    fullscreenPreview () {
      const wrap = this.$refs.previewWrap
      if (!wrap) return
      const request = wrap.requestFullscreen || wrap.webkitRequestFullscreen
      if (request) request.call(wrap)
    },
    onFullscreenChange () {
      const iframe = this.$refs.previewFrame
      const wrap = this.$refs.previewWrap
      if (!iframe || !wrap) return
      const element = document.fullscreenElement || document.webkitFullscreenElement
      const isFull = element === wrap
      iframe.style.height = isFull ? '100%' : ''
      try {
        iframe.contentDocument.body.classList.toggle('aij-fullscreen', isFull)
      } catch (err) {
        // Cross-origin srcdoc should not happen, but never let it break exit.
      }
      if (isFull) this.focusPreview()
      else this.sizePreview()
    },
    onShared (shared) {
      this.$emit('shared', shared)
    },
    downloadName (response) {
      const base = (this.project.name || 'ai-junior').replace(/[^\w-]+/g, '-').toLowerCase()
      const extension = (response.image || '').split('.').pop().split('?')[0] || 'png'
      return `${base}-${response.promptId}.${extension}`
    },
    responseSeconds (response) {
      if (!response.startDate || !response.endDate) return '?'
      return ((new Date(response.endDate) - new Date(response.startDate)) / 1000).toFixed(0)
    },
  },
}
</script>

<style scoped>
.ai-junior-project-output {
  max-width: 1200px;
  margin: 0 auto;
}

/* Creation and original side by side where there is room for both, stacked
   where there is not. The creation gets the space; the worksheet is a
   companion, not an equal. */
.creation-layout.with-original {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 1.5rem;
  align-items: start;
}

@media (min-width: 1000px) {
  .creation-layout.with-original {
    grid-template-columns: minmax(0, 1fr) minmax(200px, 300px);
  }
}

.creation {
  min-width: 0;
}

.processing {
  text-align: center;
  padding: 3rem 0;
}

.processing-message {
  font-size: 1.8rem;
  margin-bottom: 1.2rem;
}

.progress-track {
  max-width: 460px;
  height: 14px;
  margin: 0 auto;
  background: #e9edf2;
  border-radius: 999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4a9cff, #3ddc84);
  border-radius: 999px;
  /* Matches the timer tick, so the bar creeps rather than stepping. */
  transition: width 0.5s linear;
}

.progress-fill.stalled {
  background: #d9a441;
}

.processing-elapsed {
  color: #888;
  font-size: 1.3rem;
  margin-top: 0.8rem;
}

.stalled-note {
  margin-top: 1.5rem;
}

.stalled-note p {
  color: #8a6d3b;
  font-size: 1.5rem;
}

.response-image,
.comparison {
  text-align: center;
  margin-bottom: 1.5rem;
}

.response-image img {
  max-width: 100%;
  max-height: 75vh;
  border-radius: 12px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.15);
}

.project-preview {
  margin: 0 0 1rem;
  /* Centres the slider when it stands in for the preview; the iframe is a
     full-width block and is unaffected. */
  text-align: center;
}

.preview-wrap {
  background: #fff;
  border-radius: 12px;
}

.preview-wrap:fullscreen {
  background: #111;
  border-radius: 0;
  width: 100vw;
  height: 100vh;
}

.preview-frame {
  display: block;
  width: 100%;
  border: 1px solid #ddd;
  border-radius: 12px;
  background: #fff;
}

.preview-wrap:fullscreen .preview-frame {
  border: none;
  border-radius: 0;
  height: 100%;
}

.creation-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.8rem;
  justify-content: center;
  margin: 1.2rem 0 0;
}

.originals {
  min-width: 0;
}

.originals-heading {
  color: #777;
  font-size: 1.3rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin: 0 0 0.7rem;
  text-align: center;
}

.original {
  margin: 0 0 1rem;
  max-width: 100%;
}

.original img {
  display: block;
  width: 100%;
  max-height: 45vh;
  object-fit: contain;
  border-radius: 8px;
  border: 1px solid #e3e3e3;
  background: #fff;
}

.original figcaption {
  text-align: center;
  font-size: 1.2rem;
  color: #999;
  margin-top: 0.3rem;
}

/* Stacked, the worksheet should not dominate the creation above it. */
@media (max-width: 999px) {
  .originals {
    border-top: 1px solid #eee;
    padding-top: 1.2rem;
    max-width: 460px;
    margin: 1.5rem auto 0;
  }
}

.details-toggle {
  text-align: center;
  margin-top: 1rem;
}

.failed {
  text-align: center;
  padding: 3rem 0;
}

.processing-error {
  font-family: monospace;
  font-size: 12px;
  color: #a94442;
  background: #f2dede;
  padding: 8px;
  border-radius: 4px;
  max-width: 600px;
  margin: 1rem auto;
  text-align: left;
}

.details {
  border-top: 1px solid #eee;
  padding-top: 1rem;
}

.detail-response pre {
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 11px;
  max-height: 300px;
  overflow: auto;
}

.detail-time {
  color: #999;
  font-weight: normal;
  font-size: 1.2rem;
}
</style>
