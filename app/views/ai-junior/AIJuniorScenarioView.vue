<template>
  <div class="ai-junior-scenario">
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

.curriculum-info {
  margin-top: 20px;
  width: 100%;
  max-width: 800px; /* Adjust as needed */
  text-align: left;
}
</style>
