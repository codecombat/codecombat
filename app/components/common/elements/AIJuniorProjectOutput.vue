<template>
  <div class="ai-junior-project-output">
    <h3>Project Output</h3>
    <div
      v-if="project.processingStatus === 'processing' || project.processingStatus === 'pending' || !project.processingStatus"
      class="processing"
    >
      <div class="spinner" />
      <p>Processing your project...</p>
    </div>
    <div
      v-else-if="project.processingStatus === 'failed'"
      class="failed"
    >
      <p>Processing failed. Please try again.</p>
      <button @click="$emit('reprocess-project')">
        Reprocess
      </button>
    </div>
    <div
      v-else-if="project.processingStatus === 'completed'"
      class="completed"
    >
      <div
        v-if="scenario.output.html"
        class="project-preview"
      >
        <h4>Project Preview</h4>
        <iframe
          :srcdoc="compiledOutput"
          class="preview-frame"
        />
      </div>
      <div
        v-for="response in project.promptResponses"
        :key="response.promptId"
        class="prompt-response"
      >
        <h4>{{ response.promptId }}</h4>
        <p v-if="response.text">
          {{ response.text }}
        </p>
        <img
          v-if="response.image"
          :src="response.image"
          alt="Generated image"
        >
      </div>
      <button @click="$emit('reprocess-project')">
        Reprocess
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AIJuniorProjectOutput',
  props: {
    project: {
      type: Object,
      required: true
    },
    scenario: {
      type: Object,
      required: true
    }
  },
  computed: {
    compiledOutput () {
      let { html, css, js } = this.scenario.output
      const context = { ...this.project.inputValues }
      for (const promptResponse of this.project.promptResponses || []) {
        context[promptResponse.promptId] = promptResponse.image || promptResponse.text
      }
      try {
        html = _.template(html, context)
        css = _.template(css, context)
        js = _.template(js, context)
      } catch (err) {
        console.log('Template context error:', err, html, css, js, context)
      }
      // eslint-disable-next-line no-useless-escape
      return `<html>\n  <head>\n    <style>${css}</style>\n  </head>\n  <body>\n    ${html}\n    <script>${js}<\/script>\n  </body>\n</html>`
    }
  }
}
</script>

<style scoped>
.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.preview-frame {
  width: 100%;
  height: 500px;
  border: 1px solid #ccc;
}
</style>
