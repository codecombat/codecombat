<script>
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
      }
    },

    computed: {
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

      isClicked () {
        return { 'clicked': this.clickState, 'progress-dot': true }
      }
    }
  }
</script>

<template>
  <div :class="isClicked">
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
  width: 16px;
  height: 16px;
  border-radius: 8px;
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
