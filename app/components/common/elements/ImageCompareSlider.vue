<template>
  <div class="image-compare">
    <!-- The generated image sits in normal flow and gives the box its size, so
         the two pictures are compared at the same scale and position however
         differently shaped the source drawing was. -->
    <img
      class="compare-after"
      :src="generated"
      :alt="generatedLabel"
    >

    <img
      class="compare-before"
      :src="original"
      :alt="originalLabel"
      :style="{ clipPath: `inset(0 ${(100 - position).toFixed(2)}% 0 0)` }"
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
      @pointerdown="hasMoved = true"
      @keydown="hasMoved = true"
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
         it does; after that it says which side you are looking at. -->
    <span
      v-if="!hasMoved"
      class="compare-hint"
    >↔ Slide to see {{ originalLabel.toLowerCase() }}</span>
    <template v-else>
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
  },
  data () {
    return {
      position: this.startPosition,
      hasMoved: false,
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
