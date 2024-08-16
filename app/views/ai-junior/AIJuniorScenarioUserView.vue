<template>
  <div class="ai-junior-scenario-user">
    <h2>User Projects for Scenario: {{ scenarioId }}</h2>
    <div v-if="loading">
      Loading projects...
    </div>
    <div v-else-if="error">
      {{ error }}
    </div>
    <div v-else>
      <div v-if="projects.length === 0">
        No projects found for this scenario and user.
      </div>
      <div
        v-else
        class="projects-list"
      >
        <div
          v-for="project in projects"
          :key="project._id"
          class="project-item"
        >
          <h3>Project: {{ project.name || 'Unnamed Project' }}</h3>
          <p>Created: {{ new Date(project.created).toLocaleString() }}</p>
          <AIJuniorWorksheet
            :scenario="scenario"
            :scenario-id="scenarioId"
            :user-id="userId"
            :project-id="project._id"
            :read-only="true"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import AIJuniorWorksheet from 'components/common/elements/AIJuniorWorksheet.vue'
import { getAIJuniorScenario } from 'app/core/api/ai-junior-scenarios'
import { getAIJuniorProjectsForScenarioAndUser } from 'app/core/api/ai-junior-projects'

export default {
  name: 'AIJuniorScenarioUserView',
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
    }
  },
  data () {
    return {
      scenario: null,
      projects: [],
      loading: true,
      error: null
    }
  },
  async created () {
    try {
      const [scenarioResponse, projectsResponse] = await Promise.all([
        getAIJuniorScenario({ scenarioHandle: this.scenarioId }),
        getAIJuniorProjectsForScenarioAndUser({ scenarioHandle: this.scenarioId, userId: this.userId })
      ])

      this.scenario = scenarioResponse
      this.projects = projectsResponse
      this.loading = false
    } catch (error) {
      console.error('Error fetching data:', error)
      this.error = 'An error occurred while fetching the projects. Please try again later.'
      this.loading = false
    }
  }
}
</script>

<style scoped>
.ai-junior-scenario-user {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.projects-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.project-item {
  border: 1px solid #ccc;
  padding: 20px;
  border-radius: 5px;
}
</style>
