<script>
// import { getAIJuniorScenario } from 'core/api/ai-junior-scenarios'
import QRCode from 'qrcode'

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
      },
      deep: true
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
      } catch (err) {
        console.error('Error fetching scenario:', err)
        this.error = 'An error occurred while fetching the scenario.'
      }
    }
  },

  methods: {
    marked,
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
            <span class="field-placeholder">&nbsp;</span>
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
        :key="input.id"
        :class="`scenario-input scenario-input-${input.type}`"
        :style="`left: ${input.left}%; top: ${input.top}%; width: ${input.width}%; height: ${input.height}%;`"
      >
        <!-- eslint-disable vue/no-v-html -->
        <h3
          v-if="input.label"
          class="input-label"
          v-html="input.label"
        />
        <p
          v-if="input.text"
          class="input-text"
          v-html="marked(input.text)"
        />
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
$paper-width: 11;
$paper-height: 8.5;
$top-margin: 0.5 / $paper-height * 100%;
$bottom-margin: 0.5 / $paper-height * 100%;
$left-margin: 0.5 / $paper-width * 100%;
$right-margin: 0.5 / $paper-width * 100%;
$header-height: 0.85 / $paper-height * 100%;

.worksheet-outer-container {
  width: 100%;
  height: 0;
  padding-top: calc(100% * $paper-height / $paper-width); /* Maintain paper aspect ratio */
  position: relative;
  background-color: white;
  border: 4px solid black;
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
  top: $top-margin + $header-height;
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
}

.student-name-label {
  display: flex;
  flex-grow: 0
}

.field-placeholder {
  border-bottom: 2px solid black;
  display: flex;
  flex-grow: 1;
  margin-bottom: 3%;
  margin-left: 1%;
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
  border: 1px dotted #ccc;
}

.scenario-input.scenario-input-image-field {
  border: 4px solid black;

  .input-label {
    text-align: center;
    color: #888;
  }
}

.scenario-input.scenario-input-radio {

}

</style>
