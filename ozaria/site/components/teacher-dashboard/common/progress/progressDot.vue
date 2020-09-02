<script>
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
      }
    },

    computed: {
      isClicked () {
        return this.clickState || false
      },

      dotClass () {
        return {
          dot: true,
          'green-dot': this.status === 'complete',
          'teal-dot': this.status === 'progress',
          'assigned-dot': this.status === 'assigned'
        }
      },

      dotBorder () {
        return {
          'dot-border': true,
          'border-red': this.border === 'red',
          'border-gray': this.border === 'gray'
        }
      },

      isClickedClasses () {
        return { 'clicked': this.isClicked, 'progress-dot': true, 'clickable': typeof this.clickProgressHandler === 'function' }
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
          window.tracker?.trackEvent('Track Progress: Progress Dot Clicked', { category: 'Teachers', label: eventLabel })
        }
      }
    }
  }
</script>

<template>
  <div
    :class="isClickedClasses"
    @click="clickHandler"
    >
    <div :class="dotBorder">
      <img 
        v-if="isLocked"
        class="dot"
        src="/images/ozaria/teachers/dashboard/svg_icons/IconLockedProgress.svg"
      >
      <div v-else :class="dotClass"></div>
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
