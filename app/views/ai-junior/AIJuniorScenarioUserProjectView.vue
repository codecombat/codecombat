<template>
  <div class="ai-junior-scenario-user-project">
    <h2>User Project for Scenario: {{ scenarioId }}</h2>
    <AIJuniorWorksheet
      v-if="!project || project.processingStatus === 'pending'"
      :scenario="scenario"
      :project="project"
      @process-project="processProject"
    />
    <AIJuniorProjectOutput
      v-else
      :project="project"
      :scenario="scenario"
      @reprocess-project="processProject"
    />
  </div>
</template>

<script>
import AIJuniorWorksheet from 'components/common/elements/AIJuniorWorksheet.vue'
import AIJuniorProjectOutput from 'components/common/elements/AIJuniorProjectOutput.vue'
import { getAIJuniorProject, processAIJuniorProject } from 'core/api/ai-junior-projects'
import { getAIJuniorScenario } from 'core/api/ai-junior-scenarios'

export default {
  name: 'AIJuniorScenarioUserProjectView',
  components: {
    AIJuniorWorksheet,
    AIJuniorProjectOutput
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
  },
  data () {
    return {
      project: null,
      scenario: null,
      pollingInterval: null
    }
  },
  mounted () {
    this.fetchData()
  },
  beforeDestroy () {
    this.stopPolling()
  },
  methods: {
    async fetchData () {
      try {
        [this.project, this.scenario] = await Promise.all([
          getAIJuniorProject({ projectHandle: this.projectId }),
          getAIJuniorScenario({ scenarioHandle: this.scenarioId })
        ])

        if (!this.project.processingStatus || this.project.processingStatus === 'pending') {
          await this.processProject()
        } else if (this.project.processingStatus === 'processing') {
          this.startPolling()
        }
      } catch (error) {
        console.error('Error fetching data:', error)
      }
    },
    async processProject () {
      try {
        this.project = await processAIJuniorProject({ projectHandle: this.projectId, force: true })
        this.startPolling()
      } catch (error) {
        console.error('Error processing project:', error)
      }
    },
    startPolling () {
      this.stopPolling() // Clear any existing interval
      this.pollingInterval = setInterval(this.checkProjectStatus, 5000) // Poll every 5 seconds
    },
    stopPolling () {
      if (this.pollingInterval) {
        clearInterval(this.pollingInterval)
        this.pollingInterval = null
      }
    },
    async checkProjectStatus () {
      try {
        const updatedProject = await getAIJuniorProject({ projectHandle: this.projectId })
        if (updatedProject.processingStatus !== 'processing') {
          this.project = updatedProject
          this.stopPolling()
        }
      } catch (error) {
        console.error('Error checking project status:', error)
      }
    }
  }
}
</script>
