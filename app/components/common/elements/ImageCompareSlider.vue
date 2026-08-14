<template>
  <div
    class="image-compare"
    :class="{ revealing }"
  >
    <!-- The generated image sits in normal flow and gives the box its size, so
         the two pictures are compared at the same scale and position however
         differently shaped the source drawing was. -->
    <img
      ref="afterImage"
      class="compare-after"
      :src="generated"
      :alt="generatedLabel"
      @load="afterLoaded = true"
      @error="afterLoaded = true"
    >

    <img
      ref="beforeImage"
      class="compare-before"
      :src="original"
      :alt="originalLabel"
      :style="{ clipPath: `inset(0 ${(100 - position).toFixed(2)}% 0 0)` }"
      @load="beforeLoaded = true"
      @error="beforeLoaded = true"
    >

    <!-- A real range input, invisible over the picture: dragging, tapping,
         arrow keys, Home/End and screen-reader announcement all come free, and
         `touch-action: pan-y` leaves vertical scrolling to the page. -->
    <input
      v-model.number="position"
      class="compare-range"
      type="range"
      min="0"
      max="100"
      step="0.1"
      :aria-label="`Slide to compare ${originalLabel} with ${generatedLabel}`"
      :aria-valuetext="valueText"
      @pointerdown="onUserInput"
      @keydown="onUserInput"
    >

    <div
      class="compare-divider"
      :style="{ left: `${position}%` }"
    />
    <!-- Held back from the edges so the grip stays whole at either end — the
         resting position is an end, and half a button reads as broken. -->
    <span
      class="compare-handle"
      :style="handleStyle"
    >↔</span>

    <!-- Until the slider has been touched it is just a picture, so it says what
         it does; after that it says which side you are looking at. During the
         reveal it says neither — the animation is the explanation. -->
    <span
      v-if="!hasMoved && !revealing"
      class="compare-hint"
    >↔ Slide to see {{ originalLabel.toLowerCase() }}</span>
    <template v-else-if="hasMoved">
      <span
        v-if="position > 6"
        class="compare-tag compare-tag-before"
      >{{ originalLabel }}</span>
      <span
        v-if="position < 94"
        class="compare-tag compare-tag-after"
      >{{ generatedLabel }}</span>
    </template>

    <a
      v-if="fullSizeHref"
      class="compare-fullsize"
      :href="fullSizeHref"
      target="_blank"
      rel="noopener"
      title="Open full size"
    >⤢</a>
  </div>
</template>

<script>
// Half the grip's width, matching .compare-handle in the styles below.
const HANDLE_RADIUS = 17

// The reveal: long enough to read as a deliberate sweep, short enough that
// nobody waits on it before they can use the page.
const REVEAL_MS = 850
// A beat holding on the drawing first, so there is something to be revealed
// *from* rather than a wipe that starts before the eye has landed.
const REVEAL_HOLD_MS = 280
// Scrolled far enough into view that the sweep will actually be watched.
const REVEAL_VISIBLE_RATIO = 0.35
// Backstop: past this, show the creation whether or not the sweep ever ran.
const REVEAL_GIVE_UP_MS = 8000

/**
 * Slide-to-compare: one picture laid exactly over another, revealed by a
 * divider you drag across them. Starts fully on the `generated` side, so at
 * rest it looks like — and stands in for — plainly showing that image.
 */
export default {
  name: 'ImageCompareSlider',
  props: {
    // Revealed from the left as the divider moves right.
    original: {
      type: String,
      required: true,
    },
    generated: {
      type: String,
      required: true,
    },
    originalLabel: {
      type: String,
      default: 'Your drawing',
    },
    generatedLabel: {
      type: String,
      default: 'Your creation',
    },
    // Percentage of the original revealed; 0 means all generated.
    startPosition: {
      type: Number,
      default: 0,
    },
    // Open on the drawing and sweep to the creation once, when first seen.
    autoReveal: {
      type: Boolean,
      default: false,
    },
    // Staggers a row of sliders so they cascade instead of firing at once.
    revealDelay: {
      type: Number,
      default: 0,
    },
  },
  data () {
    return {
      // An auto-revealing slider opens on the drawing; everything else opens
      // on the creation. Set here rather than in mounted so the drawing is the
      // first thing painted — starting at 0 and jumping to 100 would flash the
      // creation before the reveal that is supposed to lead up to it.
      position: this.autoReveal ? 100 : this.startPosition,
      hasMoved: false,
      revealing: false,
      revealed: false,
      afterLoaded: false,
      beforeLoaded: false,
    }
  },
  computed: {
    valueText () {
      if (this.position <= 0) return this.generatedLabel
      if (this.position >= 100) return this.originalLabel
      return `${Math.round(this.position)}% ${this.originalLabel}`
    },
    handleStyle () {
      return { left: `clamp(${HANDLE_RADIUS}px, ${this.position}%, calc(100% - ${HANDLE_RADIUS}px))` }
    },
    // Whichever side is mostly on screen, so the button opens what you are
    // looking at. A drawing kept as a data URL has no page to open — browsers
    // refuse to navigate to one — so there is nothing to offer for it.
    fullSizeHref () {
      const href = this.position >= 50 ? this.original : this.generated
      return href.startsWith('data:') ? null : href
    },
    // Sweeping over a picture that has not arrived yet reveals nothing.
    imagesReady () {
      return this.afterLoaded && this.beforeLoaded
    },
  },
  watch: {
    imagesReady (ready) {
      if (ready) this.maybeReveal()
    },
  },
  mounted () {
    if (!this.autoReveal) return

    // Someone who has asked for less motion gets the creation, not a sweep.
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      this.position = this.startPosition
      this.revealed = true
      return
    }

    // Cached images can finish before Vue binds the load handlers.
    if (this.$refs.afterImage && this.$refs.afterImage.complete) this.afterLoaded = true
    if (this.$refs.beforeImage && this.$refs.beforeImage.complete) this.beforeLoaded = true

    // Opening on the drawing means a reveal that never fires leaves the wrong
    // picture on screen for good. Nothing below is guaranteed — an image can
    // fail, an observer can be stubbed out by a test harness — so settle on the
    // creation regardless after long enough that the sweep has plainly missed
    // its moment.
    // Covers a stalled sweep as well as one that never armed: animation frames
    // stop entirely in a background tab, and a sweep frozen part-way is just as
    // wrong to leave behind as one that never started. Well past the sweep's
    // own duration, so this can only fire on something genuinely stuck.
    this.revealFallback = setTimeout(() => {
      if (!this.revealed) this.finishReveal()
    }, REVEAL_GIVE_UP_MS)

    document.addEventListener('visibilitychange', this.maybeReveal)
    if (window.IntersectionObserver) {
      this.observer = new window.IntersectionObserver((entries) => {
        this.onScreen = entries.some((entry) => entry.intersectionRatio >= REVEAL_VISIBLE_RATIO)
        this.maybeReveal()
      }, { threshold: [REVEAL_VISIBLE_RATIO] })
      this.observer.observe(this.$el)
    } else {
      this.onScreen = true
      this.maybeReveal()
    }
  },
  beforeDestroy () {
    if (this.observer) this.observer.disconnect()
    if (this.revealTimer) clearTimeout(this.revealTimer)
    if (this.revealFallback) clearTimeout(this.revealFallback)
    if (this.revealFrame) cancelAnimationFrame(this.revealFrame)
    document.removeEventListener('visibilitychange', this.maybeReveal)
  },
  methods: {
    // Every precondition in one place, because each of them can become true
    // last: the images can arrive after the slider is scrolled to, the tab can
    // be in the background the whole time it is on screen, and a slider below
    // the fold may not be looked at for a while.
    maybeReveal () {
      if (!this.autoReveal || this.revealed || this.revealing) return
      if (!this.imagesReady || !this.onScreen) return
      if (document.visibilityState === 'hidden') return
      this.revealing = true
      this.revealTimer = setTimeout(this.runReveal, REVEAL_HOLD_MS + this.revealDelay)
    },
    runReveal () {
      const from = this.position
      // Timed from the first frame rather than from now: a rAF callback is
      // stamped with the frame's start, which can precede a performance.now()
      // taken moments earlier. That makes the first step's elapsed time
      // negative, and easeInOutCubic of a negative t is itself negative — so
      // `from * (1 - eased)` overshoots past 100 and throws the divider off
      // the edge of the picture before the sweep begins.
      let start = null
      const step = (now) => {
        if (start === null) start = now
        const t = Math.min(1, Math.max(0, (now - start) / REVEAL_MS))
        // easeInOutCubic: leaves the drawing gently, arrives gently, and is
        // quick through the middle where there is nothing to look at.
        const eased = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
        this.position = from * (1 - eased)
        if (t < 1) {
          this.revealFrame = requestAnimationFrame(step)
        } else {
          this.finishReveal()
        }
      }
      this.revealFrame = requestAnimationFrame(step)
    },
    finishReveal () {
      if (this.revealFallback) {
        clearTimeout(this.revealFallback)
        this.revealFallback = null
      }
      this.position = this.startPosition
      this.revealing = false
      this.revealed = true
    },
    // Grabbing the slider mid-sweep hands it straight over — the animation is
    // a demonstration, and it should never fight the person it taught.
    onUserInput () {
      this.hasMoved = true
      if (this.revealed) return
      if (this.revealTimer) clearTimeout(this.revealTimer)
      if (this.revealFrame) cancelAnimationFrame(this.revealFrame)
      this.revealTimer = null
      this.revealFrame = null
      this.revealing = false
      this.revealed = true
      if (this.revealFallback) {
        clearTimeout(this.revealFallback)
        this.revealFallback = null
      }
    },
  },
}
</script>

<style scoped>
/* Shrink-wraps the generated image rather than filling the row, so the
   absolutely positioned original lands on exactly the same pixels. */
.image-compare {
  position: relative;
  display: inline-block;
  max-width: 100%;
  line-height: 0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.15);
  background: #fff;
  user-select: none;
  -webkit-user-select: none;
}

.compare-after {
  display: block;
  max-width: 100%;
  max-height: 75vh;
}

.compare-before {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  /* Contain rather than cover: a drawing cropped from a worksheet is rarely
     the same shape as what the model made from it, and cropping the child's
     own work to force a match would hide part of what they drew. */
  object-fit: contain;
  background: #fff;
  will-change: clip-path;
}

.compare-range {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  opacity: 0;
  cursor: ew-resize;
  background: transparent;
  z-index: 3;
  touch-action: pan-y;
  -webkit-appearance: none;
  appearance: none;
}

/* A hairline thumb keeps the value the browser derives from a drag aligned
   with the pointer: a wide thumb is inset half its width at each end. */
.compare-range::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 2px;
  height: 100%;
  background: transparent;
}

.compare-range::-moz-range-thumb {
  width: 2px;
  height: 100%;
  border: none;
  border-radius: 0;
  background: transparent;
}

.compare-divider {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  margin-left: -1px;
  background: #fff;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.35);
  pointer-events: none;
  z-index: 2;
}

.compare-handle {
  position: absolute;
  top: 50%;
  transform: translate(-50%, -50%);
  pointer-events: none;
  z-index: 2;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: #fff;
  color: #333;
  border: 1px solid rgba(0, 0, 0, 0.2);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
  font-size: 1.6rem;
  line-height: 32px;
  text-align: center;
}

.compare-range:focus-visible ~ .compare-handle {
  border-color: #4a9cff;
  box-shadow: 0 0 0 3px rgba(74, 156, 255, 0.6);
}

/* During the sweep the divider stops being a thin control edge and becomes the
   thing doing the revealing: a bright line with a glow ahead of it. */
.image-compare.revealing .compare-divider {
  width: 3px;
  margin-left: -1.5px;
  background: #fff;
  box-shadow:
    0 0 10px 3px rgba(255, 255, 255, 0.9),
    0 0 26px 10px rgba(120, 200, 255, 0.55);
}

.image-compare.revealing .compare-handle {
  transform: translate(-50%, -50%) scale(1.1);
  border-color: rgba(255, 255, 255, 0.9);
  box-shadow:
    0 0 0 4px rgba(255, 255, 255, 0.35),
    0 0 18px 6px rgba(120, 200, 255, 0.5);
}

.compare-tag,
.compare-hint {
  position: absolute;
  bottom: 10px;
  padding: 3px 9px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.55);
  color: #fff;
  font-size: 1.1rem;
  line-height: 1.6;
  letter-spacing: 0.03em;
  pointer-events: none;
  z-index: 2;
}

.compare-tag-before {
  left: 10px;
}

.compare-tag-after {
  right: 10px;
}

.compare-hint {
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.65);
}

.compare-fullsize {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.45);
  color: #fff;
  font-size: 1.4rem;
  line-height: 28px;
  text-align: center;
  text-decoration: none;
  opacity: 0;
  transition: opacity 0.15s ease;
  z-index: 4;
}

.image-compare:hover .compare-fullsize,
.compare-fullsize:focus {
  opacity: 1;
}

/* Touch devices get no hover, so never reveal it there. */
@media (hover: none) {
  .compare-fullsize {
    display: none;
  }
}

/* On paper there is nothing to drag, so print just the picture. */
@media print {
  .compare-divider,
  .compare-handle,
  .compare-hint,
  .compare-tag,
  .compare-fullsize {
    display: none;
  }
}
</style>
