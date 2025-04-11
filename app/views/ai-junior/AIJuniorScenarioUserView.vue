<template>
  <div class="ai-junior-scenario-user">
    <div v-if="loading">
      Loading projects...
    </div>
    <div v-else-if="error">
      {{ error }}
    </div>
    <div
      v-else
      class="projects-list"
    >
      <h2>
        User Projects for Scenario: {{ scenario?.name }}
      </h2>
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
          <p v-if="project.created">
            Created On: {{ new Date(project.created).toLocaleString() }}
          </p>
          <!-- <AIJuniorWorksheet
            :scenario="scenario"
            :scenario-id="scenarioId"
            :user-id="userId"
            :project-id="project._id"
            :read-only="true"
          /> -->
          <AIJuniorProjectOutput
            :project="project"
            :scenario="scenario"
            :hide-reprocess-button="true"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getAIJuniorScenario } from 'app/core/api/ai-junior-scenarios'
import { getAIJuniorProjectsForScenarioAndUser } from 'app/core/api/ai-junior-projects'
import AIJuniorProjectOutput from 'components/common/elements/AIJuniorProjectOutput.vue'

export default {
  name: 'AIJuniorScenarioUserView',
  components: {
    AIJuniorProjectOutput,
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
  padding: 20px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center
}

.projects-list {
  display: flex;
  flex-direction: column;
  gap: 20px;

  padding: 10px;
}

.project-item {
  border: 1px solid #ccc;
  padding: 20px;
  border-radius: 5px;
}
</style>
