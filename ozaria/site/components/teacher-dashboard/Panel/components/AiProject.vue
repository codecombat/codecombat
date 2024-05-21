<template>
  <div class="ai-project">
    <h4>{{ aiProject.name }}</h4>
    <p>Progress: {{ progress }}%</p>
    <p v-if="failedAttempts">
      Failed attempts: {{ failedAttempts }}
    </p>
    <a
      :href="`/ai/project/${aiProject._id}`"
      target="_blank"
    >Open Project</a>
  </div>
</template>

<script>
export default {
  name: 'AiProject',
  props: {
    aiProject: {
      type: Object,
      required: true,
    },
    initialActionCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    progress () {
      const remainingActions = this.aiProject.actionQueue.length
      const completedActions = this.initialActionCount - remainingActions
      return Math.round((completedActions / this.initialActionCount) * 100)
    },
    failedAttempts () {
      return (this.aiProject.wrongChoices || []).length
    }
  },
}
</script>

<style scoped lang="scss">
.ai-project {
    width: 300px;
    padding: 20px;
    border-radius: 5px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.15);
    background-color: #ffffff;
    margin-bottom: 20px;

    h4 {
        color: #333333;
        margin-bottom: 10px;
    }

    p {
        color: #666666;
        margin-bottom: 5px;

        &:last-child {
            margin-bottom: 0;
        }
    }
}
</style>