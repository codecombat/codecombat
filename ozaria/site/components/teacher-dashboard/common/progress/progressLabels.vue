<script>
import { mapGetters } from 'vuex'
import IconHelp from '../../common/icons/IconHelp'
import ProgressDot from '../../common/progress/progressDot'
import utils from 'core/utils'
const AiProject = require('app/models/AIProject')

const BASE_LABELS = [
  { key: 'complete', dotProps: { status: 'complete' }, label: 'teacher_dashboard.complete' },
  { key: 'progress', dotProps: { status: 'progress' }, label: 'teacher.in_progress' },
  { key: 'assigned', dotProps: { status: 'assigned' }, label: 'teacher.assigned' },
  { key: 'locked', dotProps: { isLocked: true }, label: 'common.locked' },
]

const OZARIA_LABELS = [
  { key: 'concept_flag', dotProps: { status: 'complete', flag: 'concept' }, label: 'teacher_dashboard.concept_flag' },
]

const COCO_LABELS = []

const HACKSTACK_LABELS = [
  { key: 'violation', dotProps: { status: 'complete', flag: AiProject.AI_UNSAFE }, label: 'teacher_dashboard.violation' },
  { key: 'ai-struggling', dotProps: { status: 'complete', flag: AiProject.AI_STRUGGLING }, label: 'teacher_dashboard.ai_struggling' },
  { key: 'ai-eval-yes', dotProps: { status: 'complete', aiEvalFlag: AiProject.AI_EVALUATION_YES }, label: 'teacher_dashboard.ai_eval_yes' },
  { key: 'ai-eval-no', dotProps: { status: 'complete', aiEvalFlag: AiProject.AI_EVALUATION_NO }, label: 'teacher_dashboard.ai_eval_no' },
]

const OZARIA_POPOVER_ITEMS = [
  {
    rowClass: 'top-row',
    subjectKey: 'teacher.all_students',
    dotProps: { status: 'complete', flag: 'concept' },
    descriptionKey: 'teacher_dashboard.concept_flag_desc',
    borderClass: 'golden-olive-border',
  },
  {
    rowClass: 'bottom-row',
    subjectKey: 'courses.student',
    dotProps: { status: 'complete', flag: 'concept' },
    descriptionKey: 'teacher_dashboard.concept_flag_desc2',
    borderClass: 'light-gray-border',
  },
]

const COCO_POPOVER_ITEMS = [
  {
    rowClass: 'top-row',
    subjectKey: 'courses.student',
    dotProps: {
      status: 'complete',
      extraPracticeLevels: [
        { name: 'Practice Level A', inProgress: true, isCompleted: true },
        { name: 'Practice Level B', inProgress: true, isCompleted: true },
        { name: 'Practice Level C', inProgress: true, isCompleted: true },
      ],
    },
    descriptionKey: 'teacher_dashboard.completed_all_practice_levels',
    borderClass: 'light-gray-border',
  },
  {
    rowClass: 'bottom-row',
    subjectKey: 'courses.student',
    dotProps: {
      status: 'complete',
      extraPracticeLevels: [
        { name: 'Practice Level A', inProgress: true, isCompleted: true },
        { name: 'Practice Level B', inProgress: true },
        { name: 'Practice Level C', inProgress: false },
      ],
    },
    descriptionKey: 'teacher_dashboard.played_some_practice_levels',
    borderClass: 'light-gray-border',
  },
]

const HACKSTACK_POPOVER_ITEMS = [
  {
    rowClass: 'top-row',
    subjectKey: 'courses.student',
    dotProps: { status: 'complete', flag: AiProject.AI_STRUGGLING },
    descriptionKey: 'teacher_dashboard.ai_struggling_desc',
    borderClass: 'light-gray-border',
  },
  {
    rowClass: 'bottom-row',
    subjectKey: 'courses.student',
    dotProps: { status: 'complete', flag: AiProject.AI_UNSAFE },
    descriptionKey: 'teacher_dashboard.ai_unsafe_desc',
    borderClass: 'light-gray-border',
  },
  {
    rowClass: 'bottom-row',
    subjectKey: 'teacher_dashboard.ai_eval_unsure',
    dotProps: { status: 'complete', aiEvalFlag: AiProject.AI_EVALUATION_UNSURE },
    descriptionKey: 'teacher_dashboard.ai_eval_unsure_desc',
    borderClass: 'light-gray-border',
  },
]

const REVIEW_POPOVER_ITEMS = [
  {
    rowClass: 'top-row',
    subjectKey: 'teacher_dashboard.skipped',
    dotProps: { isSkipped: true },
    descriptionKey: 'teacher_dashboard.skipped_desc',
    borderClass: 'light-gray-border',
  },
  {
    rowClass: 'bottom-row',
    subjectKey: 'teacher_dashboard.optional',
    dotProps: { isOptional: true, isPlayable: true },
    descriptionKey: 'teacher_dashboard.optional_desc',
    borderClass: 'light-gray-border',
  },
]

export default {
  components: {
    IconHelp,
    ProgressDot,
  },
  computed: {
    ...mapGetters({
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
    }),
    isOzariaCourse () {
      return utils.OZ_COURSE_IDS.includes(this.selectedCourseId)
    },
    isHackstackCourse () {
      return utils.HACKSTACK_COURSE_IDS.includes(this.selectedCourseId)
    },
    popoverItems () {
      if (this.isOzariaCourse) {
        return [...OZARIA_POPOVER_ITEMS, ...REVIEW_POPOVER_ITEMS]
      }
      if (this.isHackstackCourse) {
        return [...HACKSTACK_POPOVER_ITEMS, ...REVIEW_POPOVER_ITEMS]
      }
      return [...COCO_POPOVER_ITEMS, ...REVIEW_POPOVER_ITEMS]
    },
    popoverCells () {
      return this.popoverItems.flatMap((item, i) => [
        { key: `${i}-subject`, classes: [item.rowClass, item.borderClass], isDot: false, labelKey: item.subjectKey },
        { key: `${i}-dot`, classes: [item.rowClass, item.borderClass], isDot: true, dotProps: item.dotProps },
        { key: `${i}-desc`, classes: ['description', item.rowClass, item.borderClass], isDot: false, labelKey: item.descriptionKey },
      ])
    },
    labelItems () {
      if (this.isOzariaCourse) {
        return [...BASE_LABELS, ...OZARIA_LABELS]
      }
      if (this.isHackstackCourse) {
        return [...BASE_LABELS, ...HACKSTACK_LABELS]
      }
      return [...BASE_LABELS, ...COCO_LABELS]
    },
  },
}
</script>

<template>
  <div class="progress-labels">
    <div
      v-for="item in labelItems"
      :key="item.key"
      class="img-subtext"
    >
      <progress-dot v-bind="item.dotProps" />
      <span>{{ $t(item.label) }}</span>
    </div>

    <div class="help-container">
      <v-popover
        popover-class="teacher-dashboard-tooltip lighter-p large-width"
        trigger="hover"
      >
        <!-- Triggers the tooltip -->
        <icon-help />
        <!-- The tooltip -->
        <template slot="popover">
          <div>
            <h3 style="margin-bottom: 15px;">
              {{ $t('teacher_dashboard.support_learning') }}
            </h3>
            <div class="supportGrid">
              <div
                v-for="cell in popoverCells"
                :key="cell.key"
                :class="cell.classes"
              >
                <progress-dot
                  v-if="cell.isDot"
                  v-bind="cell.dotProps"
                />
                <p v-else>
                  {{ $t(cell.labelKey) }}
                </p>
              </div>
            </div>
            <p style="margin-top: 20px; font-family: Monaco, Menlo, Ubuntu Mono, Consolas, source-code-pro, monospace; font-size: 12px;">
              {{ $t('teacher_dashboard.click_progress_dot_tip') }}
            </p>
          </div>
        </template>
      </v-popover>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.progress-labels {
  // ensure spacers are equal size
  flex: 0.5 0.5 0px;

  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: flex-start;

  & > div {
    width: 50px;
    margin: 0 10px;
  }

  & > div.help-container {
    width: 26px;

    ::v-deep .v-popover {
      display: flex;
      .trigger {
        line-height: 19px;
      }
    }
  }
}

.img-subtext {
  width: 100%;
  height: 100%;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  @include font-p-4-paragraph-smallest-gray;
  font-size: 10px;
  line-height: 11px;
  text-align: center;
  white-space: nowrap;
}

.supportGrid {
  display: grid;
  grid-template-columns: 0.4fr 45px 1fr;
  grid-auto-rows: minmax(47px, auto);
  justify-content: center;
  align-items: center;

  .top-row, .bottom-row {
    width: 100%;
    height: 100%;

    display: flex;
    align-items: center;
    justify-content: center;

    padding: 0 10px;
    text-align: left;

    /* Required so that we don't have thick borders between cells. */
    &:not(:nth-child(3n+1)) {
      border-left: unset;
    }

    &:nth-child(3n+1) {
      justify-content: unset;
    }
  }

  .bottom-row {
    border-top: unset;
  }

  .golden-olive-border {
    background: #fff9e3;
    border: 0.5px solid #c2a957;
  }

  .light-gray-border {
    border: 0.5px solid #d8d8d8;
  }

  .description p {
    font-size: 13px;
    color: #545b64;
  }
}
</style>
