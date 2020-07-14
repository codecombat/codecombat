<script>
  import { mapGetters } from 'vuex'

  export default {
    props: {
      status: {
        type: String,
        default: 'assigned'
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

      selectedKey: {
        type: String,
        required: false,
        default: undefined
      }
    },

    computed: {
      ...mapGetters({
        selectedProgressKey: 'teacherDashboardPanel/selectedProgressKey'
      }),

      isClicked () {
        return (this.selectedProgressKey && this.selectedProgressKey === this.selectedKey) || this.clickState
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
          this.clickProgressHandler()
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
      <div :class="dotClass"></div>
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
