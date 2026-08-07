<template>
  <div class="ai-junior-shared">
    <div
      v-if="loadError"
      class="shared-missing"
    >
      <h1>🔍 Creation not found</h1>
      <p>This link may have expired, or the creation was made private again.</p>
      <a
        class="btn btn-lg btn-primary"
        href="/ai-junior"
      >Make your own</a>
    </div>

    <template v-else-if="project && scenario">
      <header class="shared-header">
        <h1 class="creation-name">
          {{ project.name || 'A creation' }}
        </h1>
        <p class="creation-sub">
          made with <strong>{{ scenario.name }}</strong> · CodeCombat AI Junior
        </p>
      </header>

      <AIJuniorProjectOutput
        :project="project"
        :scenario="scenario"
        :hide-reprocess-button="true"
        :read-only="true"
      />

      <section class="make-your-own">
        <h2>Want to make one?</h2>
        <p>
          Print a worksheet, draw on it with a pencil, and watch it come to life.
        </p>
        <a
          class="btn btn-lg btn-primary"
          :href="scenario.slug ? `/ai-junior/project/${scenario.slug}` : '/ai-junior'"
        >Make your own</a>
        <p class="make-your-own-alt">
          <a href="/ai-junior">See all the activities</a>
        </p>
      </section>
    </template>

    <div
      v-else
      class="shared-loading"
    >
      Loading…
    </div>
  </div>
</template>

<script>
import AIJuniorProjectOutput from 'components/common/elements/AIJuniorProjectOutput.vue'
import { getSharedAIJuniorProject } from 'core/api/ai-junior-projects'

// A share link is meant to be handed to a grandparent, so the page strips the
// site's nav and footer down to just the creation and one call to action. The
// chrome is owned by the surrounding Backbone RootView rather than this
// component, so hiding it means injecting a stylesheet and taking it away again
// on the way out — the same approach the worksheet uses for printing.
const CHROME_CSS = `
  nav#main-nav, footer#site-footer { display: none !important; }
  #site-content-area { padding-top: 0 !important; }
`

export default {
  name: 'AIJuniorSharedView',
  components: {
    AIJuniorProjectOutput,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      project: null,
      scenario: null,
      loadError: null,
      styleElement: null,
    }
  },
  async created () {
    try {
      const { project, scenario } = await getSharedAIJuniorProject({ projectHandle: this.projectId })
      this.project = project
      this.scenario = scenario
      if (project.name) document.title = `${project.name} — CodeCombat AI Junior`
    } catch (error) {
      console.error('Error fetching shared creation:', error)
      this.loadError = 'not-found'
    }
  },
  mounted () {
    this.styleElement = document.createElement('style')
    this.styleElement.setAttribute('data-ai-junior-shared', '')
    this.styleElement.textContent = CHROME_CSS
    document.head.appendChild(this.styleElement)
  },
  beforeDestroy () {
    if (this.styleElement) this.styleElement.remove()
  },
}
</script>

<style scoped>
.ai-junior-shared {
  max-width: 960px;
  margin: 0 auto;
  padding: 2rem 1.5rem 4rem;
}

.shared-header {
  text-align: center;
  margin-bottom: 1.5rem;
}

.creation-name {
  font-size: 3.2rem;
  margin: 0 0 0.3rem;
}

.creation-sub {
  color: #888;
  font-size: 1.5rem;
  margin: 0;
}

.shared-loading,
.shared-missing {
  text-align: center;
  padding: 5rem 1rem;
  font-size: 1.8rem;
}

.make-your-own {
  margin-top: 3.5rem;
  padding: 2.2rem 1.5rem;
  text-align: center;
  background: #f5f9ff;
  border-radius: 16px;
}

.make-your-own h2 {
  margin: 0 0 0.5rem;
  font-size: 2.4rem;
}

.make-your-own p {
  color: #666;
  font-size: 1.6rem;
  margin-bottom: 1.4rem;
}

.make-your-own-alt {
  margin: 1.2rem 0 0;
  font-size: 1.4rem;
}
</style>
