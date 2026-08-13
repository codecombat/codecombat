<template>
  <div class="ai-junior-scenario">
    <div
      v-if="hasAccess() && scenario"
      class="scan-cta no-print"
    >
      <a
        class="btn btn-primary"
        :href="`/ai-junior/scan/${scenarioId}`"
      >📷 Scan a paper worksheet</a>
      <span class="scan-hint">Already filled one in on paper? Photograph it instead of drawing here.</span>
    </div>
    <div
      v-if="hasAccess()"
      class="main-column"
    >
      <AIJuniorWorksheet
        v-if="scenario"
        :scenario="scenario"
        :scenario-id="scenarioId"
      />
      <div v-else>
        Loading scenario...
      </div>
    </div>
    <div
      v-if="curriculumInfo"
      class="curriculum-info"
    >
      <h3>Curriculum Information</h3>
      <p>{{ curriculumInfo }}</p>
    </div>
  </div>
</template>

<script>
import AIJuniorWorksheet from 'components/common/elements/AIJuniorWorksheet.vue'
import { getAIJuniorScenario } from 'app/core/api/ai-junior-scenarios'

export default {
  name: 'AIJuniorScenarioView',
  components: {
    AIJuniorWorksheet,
  },
  props: {
    scenarioId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      scenario: null,
      curriculumInfo: null,
    }
  },
  async created () {
    try {
      const response = await getAIJuniorScenario({ scenarioHandle: this.scenarioId })
      this.scenario = response
      this.curriculumInfo = this.scenario.curriculumInfo
    } catch (error) {
      console.error('Error fetching scenario:', error)
      // Handle error (e.g., show error message to user)
    }
  },
  methods: {
    hasAccess () {
      return me.hasAiJuniorAccess()
    },
  },
}
</script>

<style scoped>
.ai-junior-scenario {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
}

.main-column {
  width: 100%;
  display: flex;
  justify-content: center;
}

.scan-cta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem 1rem;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
}

.scan-hint {
  font-size: 1.4rem;
  color: #666;
}

.curriculum-info {
  margin-top: 20px;
  width: 100%;
  max-width: 800px; /* Adjust as needed */
  text-align: left;
}
</style>
