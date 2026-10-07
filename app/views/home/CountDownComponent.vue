<template>
  <div class="count-down">
    <div class="time-block">
      <span class="number">{{ days }}</span>
      <span class="unit-label">{{ $t('units.days') }}</span>
    </div>
    <div class="time-block">
      <span class="number">{{ hours | pad }}</span>
      <span class="unit-label">{{ $t('units.hours') }}</span>
    </div>
    <div class="time-block">
      <span class="number">{{ minutes | pad }}</span>
      <span class="unit-label">{{ $t('units.minutes') }}</span>
    </div>
  </div>
</template>
<script>
const dayjs = window.dayjs
export default {
  name: 'CountDown',
  filters: {
    pad (value) {
      return String(value).padStart(2, '0')
    },
  },
  props: {
    ddl: {
      type: [String, Date],
      required: true,
    },
  },
  data () {
    return {
      now: dayjs(),
      timer: null,
    }
  },
  computed: {
    diff () {
      const target = dayjs(this.ddl)
      const diffMs = target.diff(this.now)
      return diffMs > 0 ? diffMs : 0
    },
    duration () {
      return dayjs.duration(this.diff)
    },
    days () {
      return Math.floor(this.duration.asDays())
    },
    hours () {
      return this.duration.hours()
    },
    minutes () {
      return this.duration.minutes()
    },
  },
  mounted () {
    this.startTimer()
  },
  beforeDestroy () {
    this.stopTimer()
  },
  methods: {
    startTimer () {
      this.timer = setInterval(() => {
        this.now = dayjs()
        if (this.diff <= 0) {
          this.stopTimer()
        }
      }, 3000)
    },
    stopTimer () {
      if (this.timer) {
        clearInterval(this.timer)
        this.timer = null
      }
    },
  },
}
</script>
<style scoped lang="scss">
.count-down {
  display: flex;
  align-items: center;
  justify-content: space-around;
.time-block {
  color: black;
  border-radius: 30px;
  border: 1px solid black;
  width: 150px;
  height: 150px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-weight: 700;

  .number {
    font-size: 2.5em;
    line-height: 1;
  }
  .unit-label {
    line-height: 1;
    margin-top: 5px;
    font-size: 16px;
    text-transform: uppercase;
  }
}
}
</style>