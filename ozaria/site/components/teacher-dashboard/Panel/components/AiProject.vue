<template>
  <div class="ai-project panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">
        {{ aiProject.name }}
      </h4>
    </div>

    <div class="panel-body">
      <!-- Metadata grouped as a Bootstrap definition list for consistent label/value alignment -->
      <dl class="dl-horizontal">
        <dt>{{ $t('teacher_dashboard.ai_model') }}</dt>
        <dd>{{ aiScenario.tool }}</dd>

        <template v-if="lastPlayed">
          <dt>{{ $t('user.last_played') }}</dt>
          <dd>{{ lastPlayed }}</dd>
        </template>

        <template v-if="mode === 'use'">
          <dt>{{ $t('user.status') }}</dt>
          <dd>
            <span :class="['label', aiProject.isReadyToReview ? 'label-success' : 'label-info']">
              {{ aiProject.isReadyToReview ? $t('teacher_dashboard.ready_to_review') : $t('teacher.in_progress') }}
            </span>
          </dd>
        </template>

        <template v-else>
          <dt>{{ $t('teacher.progress') }}</dt>
          <dd>
            <div class="progress">
              <div
                class="progress-bar"
                role="progressbar"
                :aria-valuenow="progress"
                aria-valuemin="0"
                aria-valuemax="100"
                :style="{ width: `${progress}%` }"
              >
                {{ progress }}%
              </div>
            </div>
          </dd>

          <template v-if="failedAttempts">
            <dt>{{ $t('teacher_dashboard.failed_attempts') }}</dt>
            <dd>
              {{ failedAttempts }}
              <br><span class="subtext text-muted">{{ $t('teacher_dashboard.failed_attempts_subtext') }}</span>
            </dd>
          </template>
          <template v-else-if="mode === 'learn to use'">
            <dt>{{ $t('teacher_dashboard.failed_attempts') }}</dt>
            <dd>{{ $t('teacher_dashboard.no_failed_attempts') }}</dd>
          </template>
        </template>
      </dl>

      <p v-if="aiProject.remixedFrom">
        {{ $t('teacher_dashboard.this_project_is_remixed') }}
        <a
          :href="`/ai/project/${aiProject.remixedFrom}`"
          target="_blank"
        >{{ $t('teacher_dashboard.view_original_project') }}</a>
      </p>

      <div
        v-if="safetyValidations.length > 0"
        class="safety-validations alert alert-warning"
      >
        <strong>{{ $t('teacher_dashboard.safety_violations') }}</strong>
        <ul class="list-unstyled">
          <li
            v-for="safetyValidation in safetyValidations"
            :key="safetyValidation._id"
            class="safety-validations__item"
          >
            <strong>{{ safetyValidation.failureType }}</strong><br>
            {{ safetyValidation.failureDetails }}
            <span class="violation-message-text text-muted">{{ safetyValidation.text }}</span>
          </li>
        </ul>
      </div>

      <div
        v-if="aiEvaluation"
        class="ai-evaluation"
      >
        <strong>{{ $t('teacher_dashboard.ai_evaluation') }}:</strong>
        <IconBeta class="beta-icon" />
        <div class="evaluation well well-sm">
          <!-- v-text avoids a text node so `white-space: pre-wrap` doesn't render the template's own indentation as leading whitespace, eslint + whitespace issues -->
          <p
            class="content"
            v-text="aiEvaluation.content"
          />
          <p class="content evaluate-date text-muted">
            {{ $t('teacher_dashboard.ai_evaluated_on') }}:
            {{ aiEvaluation.evaluateOn }}
          </p>
        </div>
      </div>
    </div>

    <div class="panel-footer">
      <a
        class="purple-btn"
        :href="`/ai/project/${aiProject._id}`"
        target="_blank"
      >{{ $t('teacher_dashboard.open_project') }}</a>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import IconBeta from 'app/core/components/IconBeta'
const moment = window.moment

export default {
  name: 'AiProject',
  components: {
    IconBeta,
  },
  props: {
    aiProject: {
      type: Object,
      required: true,
    },
    aiScenario: {
      type: Object,
      required: true,
    },
  },
  computed: {
    initialActionCount () {
      return this.aiScenario.initialActionQueue.length
    },
    lastPlayed () {
      if (this.aiProject.changed) {
        return moment(this.aiProject.changed).format('lll')
      } else {
        return ''
      }
    },
    mode () {
      return this.aiScenario.mode
    },
    progress () {
      const remainingActions = this.aiProject.actionQueue.length
      const completedActions = this.initialActionCount - remainingActions
      return Math.round((completedActions / this.initialActionCount) * 100)
    },
    failedAttempts () {
      return (this.aiProject.wrongChoices || []).length
    },
    safetyValidations () {
      if (!this.aiProject || !this.aiProject.unsafeChatMessages) return []
      return _.flatten(this.aiProject.unsafeChatMessages.map(i => i.safetyValidation.map(validation => ({
        ...validation,
        text: i.text.length > 100 ? `${i.text.substring(0, 100)}...` : i.text,
      }))))
    },
    aiEvaluation () {
      if (!this.aiProject || !this.aiProject.evaluations) return undefined
      const evs = this.aiProject.evaluations
      if (evs.length === 0) return undefined
      const ev = evs[evs.length - 1] // last one
      ev.evaluateOn = moment(ev.date).format('lll')
      return ev
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/components/teacher-dashboard/common/purple-button";

// Layout/spacing comes from Bootstrap's .panel; only component-specific tweaks live here.
.ai-project {
  // .purple-btn is display:flex; keep the footer link sized to its label instead of full-width.
  .purple-btn {
    display: inline-flex;

    &:hover,
    &:focus {
      text-decoration: none;
    }
  }

  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.15);

  // Bootstrap right-aligns .dl-horizontal labels at wider viewports; keep them left-aligned.
  .dl-horizontal dt {
    text-align: left;
  }

  .subtext {
    font-size: 0.8em;
  }

  .safety-validations__item {
    font-size: 0.8em;
    line-height: 1.2em;
    margin-bottom: 10px;
  }

  .violation-message-text {
    margin-left: 10px;
    border-left: 1px solid #999999;
    padding-left: 10px;
    margin-top: 5px;
    margin-bottom: 5px;
    display: block;
  }

  .ai-evaluation {
    position: relative;

    .beta-icon {
      position: absolute;
      top: -20px;
      cursor: auto;
    }

    .evaluation {
      margin-top: 8px;

      .content {
        max-height: 40vh;
        overflow-y: auto;
        white-space: pre-wrap;
        margin-bottom: 0;
      }

      .evaluate-date {
        font-size: 0.8em;
        white-space: unset;
        margin-top: 8px;
        margin-bottom: 0;
      }
    }
  }
}
</style>