<script>
// import { getAIJuniorScenario } from 'core/api/ai-junior-scenarios'
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
    styleElement: null, // Add this to keep track of the style element
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
    }
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

    this.scaleWorksheet()
    window.addEventListener('resize', this.scaleWorksheet)
  },

  beforeDestroy () {
    if (this.styleElement) {
      this.styleElement.remove()
    }
    window.removeEventListener('resize', this.scaleWorksheet)
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
      const scale = Math.min(scaleX, scaleY)
      if (scale > 0) {
        worksheet.style.transform = `scale(${scale})`
        worksheet.style.transformOrigin = 'top left'
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
            >
            <label for="${input.id}-free-choice">Other:</label>
            <input
              id="free-choice-text"
              type="text"
              :name="`${input.id}-free-choice-text`"
            >
          </div>
        </div>
        <!-- eslint-enable vue/no-v-html -->
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
  border: $input-border-size solid #000; /* Black border */
  margin-right: $input-margin-right;

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
  margin-bottom: -2%;
  margin-top: -3%;
}

.scenario-name-subhead {
  display: inline-block;
  margin-top: -1%;
}

.student-name-container {
  width: 37%;
  top: 27%;
  right: 13%;
  position: absolute;
  display: inline-block;
}

.student-name {
  display: inline;
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
    line-height: 1.5em; /* Height of the underline */
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
      margin-top: 10px;
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
</style>
