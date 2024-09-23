<script>
import CodeArea from '../../common/CodeArea'
import CodeDiff from '../../../../../../app/components/common/CodeDiff'
import utils from 'core/utils'

export default {
  components: {
    CodeArea,
    CodeDiff
  },

  props: {
    panelSessionContent: {
      type: Object,
      required: true
    }
  },

  computed: {
    dateFirstCompleted () {
      return this.panelSessionContent.session?.dateFirstCompleted ? moment(this.panelSessionContent.session.dateFirstCompleted).format('lll') : null
    },
    playTime () {
      return utils.secondsToMinutesAndSeconds(Math.ceil(this.panelSessionContent.session.playtime))
    },
    formattedPracticeThreshold () {
      return utils.secondsToMinutesAndSeconds(this.panelSessionContent.practiceThresholdMinutes * 60)
    }
  }
}
</script>

<template>
  <div
    class="practice-level"
    :class="{extra:panelSessionContent.isExtra}"
  >
    <div v-if="panelSessionContent.isExtra">
      <h3
        class="text-h3"
      >
        {{ $t('teacher_dashboard.extra_practice') }} {{ panelSessionContent.levelTitle }}
      </h3>
      <div class="row-icon">
        <div
          v-if="panelSessionContent.session"
          class="left-items"
        >
          <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_TimeSpent.svg">
          <span>
            <b>{{ $t('teacher.time_played_label') }}</b>
            {{ playTime }}
            <span v-if="panelSessionContent.practiceThresholdMinutes">
              <b>{{ $t('teacher.practice_threshold_label') }}</b> {{ formattedPracticeThreshold }}
            </span>
          </span>
        </div>
        <div v-else />
        <div class="right-item">
          <span
            v-if="panelSessionContent.session && dateFirstCompleted"
            class="status completed"
          >
            {{ $t('teacher.completed') }}: {{ dateFirstCompleted }}
          </span>
          <span
            v-else-if="panelSessionContent.session"
            class="status in-progress"
          >
            {{ $t('teacher.in_progress') }}
          </span>
          <span
            v-else
            class="status assigned"
          >
            {{ $t('teacher.assigned') }}
          </span>
        </div>
      </div>
    </div>
    <div class="flex-row">
      <div>
        <h4>Starter Code</h4>
        <code-area
          :code="panelSessionContent.starterCode"
          :language="panelSessionContent.language"
        />
      </div>
      <div />
    </div>
    <div class="flex-row extra-title">
      <h4>Student Code</h4>
      <h4>Solution</h4>
    </div>
    <div class="flex-row">
      <code-diff
        :code-left="panelSessionContent.studentCode"
        :code-right="panelSessionContent.solutionCode"
        :language="panelSessionContent.language"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  .practice-level {
    padding: 23px 14px;

    &.extra {
      background: $mist;
      margin: 15px;
      padding: 10px;
    }
  }

  h4 {
    @include font-p-4-paragraph-smallest-gray;
    color: black;
    font-weight: 600;
    line-height: 18px;

    margin-bottom: 10px;
  }

  .text-h3 {
    @include font-p-4-paragraph-smallest-gray;
    font-weight: 600;
    margin: 5px auto;
  }

  .flex-row {
    display: flex;
    flex-direction: row;
    justify-content: space-between;

    & > div {
      flex: 1 1 0px;
      margin: 6px;
    }
  }

  .extra-title {
    padding-right: 35%;
    margin-top: 50px;
  }

  .row-icon {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin: 7px 0;
    width: 100%;
    font-size: 14px;
  }

  .left-items {
    display: flex;
    align-items: center;
  }

</style>
