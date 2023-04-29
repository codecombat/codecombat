<script>
import moment from 'moment'

export default {
    props: {
      status: {
        type: String,
        default: 'assigned',
        validator: value => {
          const index = ['assigned', 'progress', 'complete', 'unassigned'].indexOf(value)
          if (index === -1) {
            console.error(`Got progressDot status value of '${value}'`)
          }
          return index !== -1
        }
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
        default: null
      },

      lastLockDate: {
        type: Date,
        default: null
      },

      border: {
        type: String,
        default: ''
      },

      clickState: {
        type: Boolean,
        default: false
      },

      clickProgressHandler: {
        type: Function,
        required: false,
        default: undefined
      },

      contentType: {
        type: String,
        default: null
      },

      trackCategory: {
        type: String,
        default: ''
      },

      selected: {
        type: Boolean,
        default: false
      },

      hovered: {
        type: Boolean,
        default: false
      },

      isPlayable: {
        type: Boolean,
        default: true
      },
      isOptional: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      isClicked () {
        return this.clickState || false
      },

      dotClass () {
        return {
          'green-dot': this.status === 'complete',
          'teal-dot': this.status === 'progress',
          'assigned-dot': this.levelAccessStatus === 'assigned',
          [this.levelAccessStatus]: true
        }
      },

      dotBorder () {
        return {
          'dot-border': true,
          'border-red': this.border === 'red',
          'border-gray': this.border === 'gray',
          'selected': this.selected,
          'hovered': this.hovered,
        }
      },

      isClickedClasses () {
        return {
          'clicked': this.isClicked,
          'progress-dot': true,
          'clickable': typeof this.clickProgressHandler === 'function'
        }
      },

      tooltipContent () {
        const date = (this.isLocked && this.lockDate > new Date() && this.lockDate) || (!this.isLocked && this.lastLockDate)
        const dateString = moment(date).utc().format('ll')

        const label = {
          'locked-by-previous': 'locked_by_previous',
          'locked-with-timeframe': 'locked_with_timeframe'
        }[this.levelAccessStatus] || this.levelAccessStatus

        return $.i18n.t(`teacher_dashboard.${label}`) + (!this.isSkipped && date ? ' ' + $.i18n.t('teacher_dashboard.until_date', { date: dateString }) : '')
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
        return 'assigned'
      },

      hasClockIcon () {
        if (this.levelAccessStatus === 'locked-with-timeframe') {
          return true
        }
        if (this.levelAccessStatus === 'locked-by-previous' && this.lastLockDate > new Date()) {
          return true
        }
        return false
      }
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
            label: eventLabel
          })
        }
      }
    }
  }
</script>

<template>
  <div
      :class="isClickedClasses"
      @click="clickHandler"
      v-tooltip="tooltipContent && {
           content: tooltipContent,
           placement: 'right',
           classes: 'layoutChromeTooltip',
         }"
  >
    <div :class="dotBorder" data="">
      <div class="dot" :class="dotClass">
      </div>
      <span v-if="hasClockIcon" class="timed-lock">
        <i class="glyphicon glyphicon-time"></i>
      </span>
    </div>
  </div>
</template>

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

.clicked {
  background-color: rgba(93, 185, 172, 0.5);
}
</style>
