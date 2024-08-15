<template>
  <div class="ai-scenario">
    <h3>{{ aiScenario.tool }}</h3>
    <ai-project
      v-for="aiProject in aiProjects"
      :key="aiProject._id"
      :ai-project="aiProject"
      :ai-scenario="aiScenario"
      :initial-action-count="aiScenario.initialActionQueue.length"
    />
  </div>
</template>

<script>
import AiProject from './AiProject.vue'

export default {
  name: 'AiScenario',
  components: {
    AiProject,
  },
  props: {
    aiScenario: {
      type: Object,
      required: true,
    },
    aiProjects: {
      type: Array,
      required: true,
    },
  },
}
</script>

<style scoped lang="scss">
.ai-scenario {
    margin: 20px;
}
</style>