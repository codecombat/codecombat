<template>
  <div class="ai-junior-scenario-user-project">
    <h2>User Project for Scenario: {{ scenarioId }}</h2>
    <AIJuniorWorksheet
      :scenario-id="scenarioId"
      :user-id="userId"
      :project-id="projectId"
    />
  </div>
</template>

<script>
import AIJuniorWorksheet from 'components/common/elements/AIJuniorWorksheet.vue'

export default {
  name: 'AIJuniorScenarioUserProjectView',
  components: {
    AIJuniorWorksheet
  },
  props: {
    scenarioId: {
      type: String,
      required: true
    },
    userId: {
      type: String,
      required: true
    },
    projectId: {
      type: String,
      required: true
    }
  }
}
</script>
