<script>
import moment from 'moment'
import { mapGetters } from 'vuex'

export default {
  props: {
    status: {
      type: String,
      default: 'unassigned',
      validator: value => {
        const index = ['assigned', 'progress', 'complete', 'unassigned'].indexOf(value)
        if (index === -1) {
          console.error(`Got progressDot status value of '${value}'`)
        }
        return index !== -1
      },
    },

    isLocked: {
      type: Boolean,
      default: false,
    },

    isSkipped: {
      type: Boolean,
      default: false,
    },

    lockDate: {
      type: Date,
      default: null,
    },

    lastLockDate: {
      type: Date,
      default: null,
    },

    border: {
      type: String,
      default: '',
    },

    clickState: {
      type: Boolean,
      default: false,
    },

    clickProgressHandler: {
      type: Function,
      required: false,
      default: undefined,
    },

    contentType: {
      type: String,
      default: null,
    },

    trackCategory: {
      type: String,
      default: '',
    },

    selected: {
      type: Boolean,
      default: false,
    },

    hovered: {
      type: Boolean,
      default: false,
    },

    isPlayable: {
      type: Boolean,
      default: true,
    },
    isOptional: {
      type: Boolean,
      default: false,
    },
    playTime: {
      type: Number,
      default: 0,
    },
    playedOn: {
      type: String,
      default: '',
    },
    completionDate: {
      type: [Boolean, String],
      default: null,
    },
    tooltipName: {
      type: String,
      default: null,
    },
    moduleNumber: {
      required: false,
      type: [Number, String],
      default: null,
    },
    normalizedOriginal: {
      required: false,
      type: String,
      default: null,
    },
    studentId: {
      type: String,
      default: null,
      required: false,
    },
    classroomGameContent: {
      type: Object,
      default: null,
    },
    levelSessionMap: {
      type: Object,
      default: null,
    },
    extraPracticeLevels: {
      type: Array,
      default: () => [],
    },
  },

  computed: {
    ...mapGetters({
      classroomId: 'teacherDashboard/classroomId',
    }),

    activePracticeLevels () {
      return this.extraPracticeLevels.filter(({ inProgress }) => inProgress)
    },

    allPracticeLevelsCompleted () {
      return this.extraPracticeLevels.length > 0 && this.extraPracticeLevels.every(({ isCompleted }) => isCompleted)
    },

    isClicked () {
      return this.clickState || false
    },

    dotClass () {
      return {
        'green-dot': this.status === 'complete',
        'teal-dot': this.status === 'progress',
        'assigned-dot': this.levelAccessStatus === 'assigned',
        [this.levelAccessStatus]: this.levelAccessStatus !== 'progress',
      }
    },

    dotBorder () {
      return {
        'dot-border': true,
        'border-red': this.border === 'red',
        'border-gray': this.border === 'gray',
        selected: this.selected,
        hovered: this.hovered,
        'has-active-practice-levels': this.activePracticeLevels.length > 0,
        'all-practice-levels-completed': this.allPracticeLevelsCompleted,
      }
    },

    isClickedClasses () {
      return {
        clicked: this.isClicked,
        'progress-dot': true,
        clickable: typeof this.clickProgressHandler === 'function',
      }
    },

    tooltipContent () {
      const date = (this.isLocked && this.lockDate > new Date() && this.lockDate) || (!this.isLocked && this.lastLockDate)
      const dateString = moment(date).utc().format('ll')

      const label = {
        'locked-by-previous': 'locked_by_previous',
        'locked-with-timeframe': 'locked_with_timeframe',
      }[this.levelAccessStatus] || this.levelAccessStatus

      const status = $.i18n.t(`teacher_dashboard.${label}`) + (!this.isSkipped && date ? ' ' + $.i18n.t('teacher_dashboard.until_date', { date: dateString }) : '')

      return `
        ${status}
        ${this.tooltipName ? `<br><strong>${this.tooltipName}</strong>` : ''}
        ${this.playedOn ? `<br>${$.i18n.t('user.last_played')}: ${moment(this.playedOn).format('lll')}` : ''}
        ${this.status === 'complete' && this.completionDate ? `<br>${$.i18n.t('teacher.completed')}: ${moment(this.completionDate).format('lll')}` : ''}
        ${this.playTime ? `<br>${$.i18n.t('teacher.time_played_label')} ${moment.duration({ seconds: this.playTime }).humanize()}` : ''}

        ${this.extraPracticeLevels?.length ? '<br><br>' : ''}

        ${this.filterPracticeLevelsToDisplay(this.extraPracticeLevels).map(({ name, status }) => `${$.i18n.t('teacher_dashboard.practice_level')}: ${name} - ${$.i18n.t(`teacher_dashboard.${status}`)}`).join('<br>')}`
    },

    levelAccessStatus () {
      if (this.isLocked && !this.lockDate && !this.isOptional) {
        return 'locked'
      } else if (!this.isLocked && !this.isPlayable && !this.lockDate) {
        return 'locked-by-previous'
      } else if (this.lockDate && this.lockDate > new Date()) {
        return 'locked-with-timeframe'
      } else if (this.isSkipped) {
        return 'skipped'
      } else if (this.isOptional && this.isPlayable) {
        return 'optional'
      }
      return this.status
    },

    hasClockIcon () {
      if (this.levelAccessStatus === 'locked-with-timeframe') {
        return true
      }
      if (this.levelAccessStatus === 'locked-by-previous' && this.lastLockDate > new Date()) {
        return true
      }
      return false
    },
  },

  methods: {
    clickHandler () {
      if (typeof this.clickProgressHandler === 'function') {
        this.trackEvent()
        this.clickProgressHandler()
      }
    },

    trackEvent () {
      if (this.contentType) {
        let eventLabel = this.contentType
        if (this.border === 'red') {
          eventLabel += ' alert'
        }
        window.tracker?.trackEvent('Track Progress: Progress Dot Clicked', {
          category: this.trackCategory || 'Teachers',
          label: eventLabel,
        })
      }
    },
    filterPracticeLevelsToDisplay (practiceLevels) {
      const levels = practiceLevels.map(level => ({ name: level.name, status: this.getStatus(level) }))

      const inProgressLevelIndex = levels.findIndex(level => level.status === 'progress')

      const firstAssignedLevelIndex = levels.findIndex(level => level.status === 'assigned')

      let mainIndex = levels.length - 2
      if (inProgressLevelIndex !== -1) {
        mainIndex = inProgressLevelIndex
      } else if (firstAssignedLevelIndex !== -1) {
        mainIndex = firstAssignedLevelIndex
      }

      if (mainIndex === 0) {
        return levels.slice(0, 3)
      }

      const selectedLevels = [
        levels[mainIndex - 2],
        levels[mainIndex - 1],
        levels[mainIndex],
        levels[mainIndex + 1],
      ].filter(Boolean)

      if (mainIndex === firstAssignedLevelIndex) {
        return selectedLevels.slice(0, 3)
      }

      return selectedLevels.slice(-3)
    },

    getStatus (level) {
      if (level.isCompleted) {
        return 'complete'
      } else if (level.inProgress) {
        return 'progress'
      } else {
        return 'assigned'
      }
    },
  },
}
</script>

<template>
  <div
    v-tooltip="tooltipContent && {
      content: tooltipContent,
      placement: 'right',
      classes: 'layoutChromeTooltip progress-dot-tooltip',
    }"
    :class="isClickedClasses"
    @click="clickHandler"
  >
    <div
      :class="dotBorder"
      data=""
    >
      <div
        class="dot"
        :class="dotClass"
      />
      <span
        v-if="hasClockIcon"
        class="timed-lock"
      >
        <i class="glyphicon glyphicon-time" />
      </span>
    </div>
  </div>
</template>

<style lang="scss">
.progress-dot-tooltip {
  max-width: max-content;
  .tooltip-inner {
    max-width: max-content;
  }
}
</style>

<style lang="scss" scoped>

.progress-dot {
  border-radius: 4px;
  width: 28px;
  height: 28px;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;

  .skipped {
    background-image: url('/images/ozaria/teachers/dashboard/svg_icons/IconSkippedLevel.svg');
    background-repeat: no-repeat;
    background-position: center center;
  }

  .optional {
    background-image: url('/images/ozaria/teachers/dashboard/svg_icons/IconOptionalLevel.svg');
    background-repeat: no-repeat;
    background-position: center center;
  }

  .timed-lock {
    position: absolute;
    font-size: 8px;
    top: -5px;
    right: 0;
  }
}

.dot {
  width: 14px;
  height: 14px;
  border-radius: 8px;
}

.clickable {
  cursor: pointer;

  &:hover:not(.clicked) {
    background-color: #d8d8d8;
  }
}

.green-dot {
  background-color: #2dcd38;
  &.locked, &.locked-by-previous, &.locked-with-timeframe {
    background-color: rgba(#2dcd38, 0.35);
  }
}

.teal-dot {
  background-color: #1ad0ff;
}

.assigned-dot {
  border: 1.5px solid #c8cdcc;
}

.locked, .locked-by-previous, .locked-with-timeframe {
  background-image: url('/images/ozaria/teachers/dashboard/svg_icons/IconLockedProgress.svg');
  background-repeat: no-repeat;
  background-position: center center;
}

.not-playable .dot {
  background-color: gray;
}

.hovered {
  background: rgba(173, 173, 173, 0.4);
  border-radius: 4px;

  &:not(.locked) .assigned-dot {
    border: 1.5px solid white;
  }
}

.selected {
  background: rgba(93, 185, 172, 0.5);
  border-radius: 4px;

  .assigned-dot {
    border: 1.5px solid white;
  }
}

.dot-border {
  width: 22px;
  height: 22px;

  display: flex;
  justify-content: center;
  align-items: center;

  border-radius: 3px;
}
.border-red {
  border: 1px solid #eb003b;
}

.border-gray {
  border: 1px solid #828282;
}

.has-active-practice-levels {
  border: 1px dotted blue;
  &.all-practice-levels-completed {
    border-style: solid;
  }
}

.clicked {
  background-color: rgba(93, 185, 172, 0.5);
}
</style>
