<script>
// import { getAIJuniorScenario } from 'core/api/ai-junior-scenarios'
import { createNewAIJuniorProject, processAIJuniorProject } from 'core/api/ai-junior-projects'
import QRCode from 'qrcode'
import { markedInline } from 'core/utils'

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
  },

  data: () => ({
    error: null,
    qrCodeUrl: '',
    styleElement: null,
    isDrawing: false,
    currentColor: '#33CC33',
    lineWidth: 8,
    canvasRefs: {},
    scale: 1,
    lastX: 0,
    lastY: 0,
    canvasContents: {}, // Store canvas content for each input
  }),

  computed: {
    me () {
      return me
    },
  },

  watch: {
    scenario: {
      handler (newScenario) {
        console.log('Scenario updated:', newScenario)
        this.generateQRCode()
        this.updateDynamicCss()
        this.scaleWorksheet()
      },
      deep: true
    },
    'scenario.inputCss': {
      handler (newCss) {
        this.updateDynamicCss(newCss)
      },
      immediate: true
    },
    scale () {
      this.$nextTick(() => {
        Object.keys(this.canvasRefs).forEach(inputId => {
          this.initializeCanvas(inputId)
        })
      })
    },
  },

  async mounted () {
    if (!this.scenario) {
      console.log('mounted', this.slug, { scenarioHandle: this.slug || '' })
      try {
        // this.scenario = await getAIJuniorScenario({ scenarioHandle: this.slug || '' })
        // TODO: data vs. prop, passing in slug vs. passing in scenario?
        console.log(this.scenario)
        this.generateQRCode()
        this.updateDynamicCss()
      } catch (err) {
        console.error('Error fetching scenario:', err)
        this.error = 'An error occurred while fetching the scenario.'
      }
    }

    this.initializeCanvases()
    window.addEventListener('resize', this.onResize)
  },

  updated () {
    this.$nextTick(() => {
      this.initializeCanvases()
    })
  },

  beforeDestroy () {
    if (this.styleElement) {
      this.styleElement.remove()
    }
    window.removeEventListener('resize', this.onResize)
  },

  methods: {
    markedInline,

    async generateQRCode () {
      if (this.scenario && this.scenario.slug) {
        const url = `https://codecombat.com/ai-junior/project/${this.slug}/${this.me.id}`
        try {
          this.qrCodeUrl = await QRCode.toDataURL(url)
        } catch (err) {
          console.error('Error generating QR code:', err)
        }
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

    scaleWorksheet () {
      const worksheet = this.$el
      const container = $(worksheet).parent()
      const scaleX = container.width() / (11 * 96) // 11 inches * 96 pixels per inch
      const scaleY = container.height() / (8.5 * 96) // 8.5 inches * 96 pixels per inch
      this.scale = Math.min(scaleX, scaleY)
      if (this.scale > 0) {
        worksheet.style.transform = `scale(${this.scale})`
        worksheet.style.transformOrigin = 'top left'
      }
    },

    initializeCanvases () {
      this.$nextTick(() => {
        this.scenario?.inputs.forEach(input => {
          if (input.type === 'image-field') {
            this.initializeCanvas(input.id)
          }
        })
      })
    },

    initializeCanvas (inputId) {
      const canvasRef = this.$refs[`canvas-${inputId}`]
      if (canvasRef && canvasRef[0]) {
        const canvas = canvasRef[0]
        const ctx = canvas.getContext('2d')

        // Set canvas size to match its display size
        const rect = canvas.getBoundingClientRect()
        canvas.width = rect.width
        canvas.height = rect.height

        ctx.lineJoin = 'round'
        ctx.lineCap = 'round'
        this.canvasRefs[inputId] = canvas

        // Restore previous content if available
        if (this.canvasContents[inputId]) {
          ctx.putImageData(this.canvasContents[inputId], 0, 0)
        }
      }
    },

    startDrawing (event) {
      this.isDrawing = true
      const { x, y } = this.getCoordinates(event)
      this.lastX = x
      this.lastY = y
    },

    draw (event) {
      if (!this.isDrawing) return
      const canvas = event.target
      const ctx = canvas.getContext('2d')
      const { x, y } = this.getCoordinates(event)

      ctx.beginPath()
      ctx.moveTo(this.lastX, this.lastY)
      ctx.lineTo(x, y)
      ctx.strokeStyle = this.currentColor
      ctx.lineWidth = this.lineWidth
      ctx.stroke()

      this.lastX = x
      this.lastY = y

      // Store the updated canvas content
      this.canvasContents[canvas.id] = ctx.getImageData(0, 0, canvas.width, canvas.height)
    },

    stopDrawing () {
      this.isDrawing = false
    },

    getCoordinates (event) {
      const canvas = event.target
      const rect = canvas.getBoundingClientRect()
      const scaleX = canvas.width / rect.width
      const scaleY = canvas.height / rect.height
      const x = (event.clientX - rect.left) * scaleX
      const y = (event.clientY - rect.top) * scaleY
      return { x, y }
    },

    clearCanvas (inputId) {
      const canvas = this.canvasRefs[inputId]
      if (canvas) {
        const ctx = canvas.getContext('2d')
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        // Clear stored content
        this.canvasContents[inputId] = null
      }
    },

    onResize () {
      this.scaleWorksheet()
      this.$nextTick(() => {
        Object.keys(this.canvasRefs).forEach(inputId => {
          this.resizeCanvas(inputId)
        })
      })
    },

    resizeCanvas (inputId) {
      const canvas = this.canvasRefs[inputId]
      if (canvas) {
        const ctx = canvas.getContext('2d')
        const oldWidth = canvas.width
        const oldHeight = canvas.height

        // Store the current drawing
        const imageData = ctx.getImageData(0, 0, oldWidth, oldHeight)

        // Resize canvas
        const rect = canvas.getBoundingClientRect()
        canvas.width = rect.width
        canvas.height = rect.height

        // Scale and restore the drawing
        ctx.save()
        ctx.scale(canvas.width / oldWidth, canvas.height / oldHeight)
        ctx.putImageData(imageData, 0, 0)
        ctx.restore()

        // Update stored content
        this.canvasContents[inputId] = ctx.getImageData(0, 0, canvas.width, canvas.height)

        ctx.lineJoin = 'round'
        ctx.lineCap = 'round'
      }
    },

    async submitWorksheet () {
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
          const canvas = this.canvasRefs[input.id]
          if (canvas) {
            try {
              const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'))
              // Convert blob to base64
              const base64 = await new Promise((resolve) => {
                const reader = new FileReader()
                reader.onloadend = () => resolve(reader.result)
                reader.readAsDataURL(blob)
              })
              inputValues[input.id] = base64
              console.log('got base64 for', input.id)
            } catch (error) {
              console.error('Error getting base64 for', input.id, error)
            }
          } else {
            console.log('no canvas for', input.id, this.canvasRefs)
          }
        } else {
          const inputElement = document.getElementById(input.id)
          if (inputElement) {
            inputValues[input.id] = inputElement.value
          }
        }
      }

      const studentName = document.querySelector('input.student-name-input')?.value

      const projectData = {
        scenarioId: this.scenario._id,
        userId: this.me.id,
        inputValues,
        studentName
      }

      try {
        const project = await createNewAIJuniorProject(projectData)
        processAIJuniorProject({ projectHandle: project._id, force: true })
        // TODO: I had the new page start processing, but it wasn't set up right, so starting processing here, waiting a bit, and then opening it.
        _.delay(() => window.open(`/ai-junior/project/${this.slug || this.scenario?._id}/${this.me.id}/${project._id}`, '_blank'), 500)
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
            v-if="false && (me.get('name') || me.get('firstName') || me.get('lastName'))"
            class="student-name"
          >{{ me.broadName() }}</span>
          <span
            v-else
            class="student-name-field"
          >
            <span class="student-name-label">Name: </span>
            <input
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
      <button
        class="submit-button no-print"
        @click="submitWorksheet"
      >
        Submit
      </button>
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
            >
            <label :for="`${input.id}-free-choice`">Other:</label>
            <input
              :id="`${input.id}-free-choice-text`"
              type="text"
              :name="`${input.id}-free-choice-text`"
            >
          </div>
        </div>
        <!-- eslint-enable vue/no-v-html -->
        <div
          v-if="input.type === 'image-field'"
          class="drawing-container"
        >
          <canvas
            :ref="`canvas-${input.id}`"
            class="drawing-canvas"
            @mousedown="startDrawing"
            @mousemove="draw"
            @mouseup="stopDrawing"
            @mouseleave="stopDrawing"
          />
          <div
            class="drawing-controls no-print"
            :style="{ transform: `scale(${1/scale})`, transformOrigin: 'bottom left' }"
          >
            <button @click="clearCanvas(input.id)">
              Clear
            </button>
            <input
              v-model="currentColor"
              type="color"
            >
            <input
              v-model.number="lineWidth"
              type="range"
              min="1"
              max="20"
            >
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

.qr-code {
  position: absolute;
  top: -0.875%;
  right: -0.75%;
  height: 100%;
  width: auto;
}

.scenario-input {
  position: absolute;
  /* border: 1px dotted #ccc; */

  &.scenario-input-image-field {
    border: 4px solid black;

    .input-label {
      text-align: center;
      color: #888;
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
        flex-grow: 1;
        border: none;
        border-bottom: 2px solid black;
        padding: 5px 5px 0 5px;
        margin-left: 8px;
        font-size: $input-text-font-size;
        line-height: 1.5em; /* Height of the underline */
        width: auto; /* Adjust width to take remaining space */
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
}

.drawing-controls {
  position: absolute;
  bottom: 10px;
  left: 10px;
  display: flex;
  gap: 10px;

  button, input {
    font-size: 14px;
    padding: 0px;
    border: 0;
    background-color: transparent;
  }

  input {
    height: 30px;
  }

  /* Styles for the range input */
  input[type="range"] {
    -webkit-appearance: none;
    width: 100%;
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

.submit-button {
  position: absolute;
  top: -40px;
  right: 0px; // Positioned above the QR code
  padding: 5px 8px;
  background-color: #007bff;
  color: white;
  border: none;
  cursor: pointer;
  font-size: 16px;
  z-index: 10;

  &:hover {
    background-color: #0056b3;
  }
}

@media print {
  .no-print {
    display: none !important;
  }
}
</style>
