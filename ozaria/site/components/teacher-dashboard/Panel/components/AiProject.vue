<template>
  <div class="ai-project">
    <h4>{{ aiProject.name }}</h4>
    <p>Progress: {{ progress }}%</p>
    <p v-if="failedAttempts">
      {{ $t('teacher_dashboard.failed_attempts') }}: {{ failedAttempts }}
      <br><span class="subtext">Number of times incorrect option was selected'</span>
    </p>
    <p v-else>
      {{ $t('teacher_dashboard.no_failed_attempts') }}
    </p>
    <a
      :href="`/ai/project/${aiProject._id}`"
      target="_blank"
    >{{ $t('teacher_dashboard.open_project') }}</a>
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
    margin-bottom: 15px;
    line-height: 1.2em;

    &:last-child {
      margin-bottom: 0;
    }

    .subtext {
      font-size: 0.8em;
      color: #999999;
    }
  }
}
</style>