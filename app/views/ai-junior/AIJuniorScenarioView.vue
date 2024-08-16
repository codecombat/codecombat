<template>
  <div class="ai-junior-scenario">
    <h2>AI Junior Scenario: {{ scenarioId }}</h2>
    <div class="main-column">
      <AIJuniorWorksheet
        v-if="scenario"
        :scenario="scenario"
        :scenario-id="scenarioId"
      />
      <div v-else>
        Loading scenario...
      </div>
    </div>
    <div class="curriculum-info">
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
    AIJuniorWorksheet
  },
  props: {
    scenarioId: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      scenario: null,
      curriculumInfo: ''
    }
  },
  async created () {
    try {
      const response = await getAIJuniorScenario({ scenarioHandle: this.scenarioId })
      this.scenario = response
      this.curriculumInfo = this.scenario.curriculumInfo || 'Curriculum information not available.'
    } catch (error) {
      console.error('Error fetching scenario:', error)
      // Handle error (e.g., show error message to user)
    }
  }
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
  max-width: 800px; /* Adjust as needed */
  margin: 0 auto;
}

.curriculum-info {
  margin-top: 20px;
  width: 100%;
  max-width: 800px; /* Adjust as needed */
  text-align: left;
}
</style>
