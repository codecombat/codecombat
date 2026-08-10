<template>
  <div class="ai-junior-scenario-user-project">
    <div class="project-header">
      <h2>{{ project?.name || 'Project' }}</h2>
      <!-- Scanning a stack of worksheets is the common case, so getting back to
           the scanner is a button rather than a trip through the browser's
           history. It goes to the argument-less scanner, which reads the next
           sheet's QR code and works out its scenario and student by itself. -->
      <p
        v-if="scenario"
        class="header-links no-print"
      >
        <a
          class="btn btn-primary scan-again"
          href="/ai-junior/scan"
        >📷 Scan another worksheet</a>
      </p>
      <p
        v-if="scenario"
        class="header-links no-print"
      >
        <a :href="`/ai-junior/project/${scenarioHandle}`">{{ scenario.name }}</a>
        ·
        <a :href="`/ai-junior/project/${scenarioHandle}/${userId}`">All my projects</a>
      </p>
    </div>
    <AIJuniorWorksheet
      v-if="showWorksheet"
      :scenario="scenario"
      :project="project"
      @process-project="processProject"
    />
    <AIJuniorProjectOutput
      v-else-if="project && scenario"
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

// Well past the server's own processing timeout, so a run that is genuinely
// still going is never cut off by the page giving up on it.
const MAX_POLL_MS = 15 * 60 * 1000

export default {
  name: 'AIJuniorScenarioUserProjectView',
  components: {
    AIJuniorWorksheet,
    AIJuniorProjectOutput,
  },
  props: {
    scenarioId: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      project: null,
      scenario: null,
      pollingInterval: null,
    }
  },
  computed: {
    scenarioHandle () {
      return this.scenario?.slug || this.scenarioId
    },
    // Show the filled-in worksheet only for a project that hasn't started
    // processing; once it's running (or done), show the live output view.
    showWorksheet () {
      return this.scenario && this.project && this.project.processingStatus === 'pending'
    },
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
          getAIJuniorScenario({ scenarioHandle: this.scenarioId }),
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
      this.pollingStartedAt = Date.now()
      this.pollingInterval = setInterval(this.checkProjectStatus, 3000)
    },
    stopPolling () {
      if (this.pollingInterval) {
        clearInterval(this.pollingInterval)
        this.pollingInterval = null
      }
    },
    async checkProjectStatus () {
      // A project whose server died mid-run stays "processing" for ever. The
      // page already offers a restart once it looks stalled, so stop asking
      // rather than polling this project until the tab is closed.
      if (this.pollingStartedAt && Date.now() - this.pollingStartedAt > MAX_POLL_MS) {
        this.stopPolling()
        return
      }
      try {
        // Update every poll so partial results (images finishing one by one)
        // appear as soon as the server saves them.
        const updatedProject = await getAIJuniorProject({ projectHandle: this.projectId })
        this.project = updatedProject
        if (updatedProject.processingStatus !== 'processing') {
          this.stopPolling()
        }
      } catch (error) {
        console.error('Error checking project status:', error)
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.project-header {
  text-align: center;
  margin-bottom: 1.5rem;

  h2 {
    margin-bottom: 0.3rem;
  }

  .header-links {
    color: #777;
    margin-bottom: 0.5rem;

    a {
      color: #337ab7;
    }

    .scan-again {
      color: #fff;
      font-size: 1.6rem;
      padding: 0.6rem 1.4rem;
      border-radius: 10px;
    }
  }
}
</style>
