<script>
import moment from 'moment'
const fetchJson = require('../../../core/api/fetch-json')
export default Vue.extend({
  props: {
    hide: {
      type: Function,
      required: true
    }
  },
  data () {
    return {
      newStopStart: null,
      newStopEnd: null,
      newStopReason: '',
      stopTimes: []
    }
  },
  computed: {
    moment: () => moment
  },
  async mounted () {
    await this.fetch()
  },
  methods: {
    fetch: async function () {
      const res = await fetchJson('/db/trial-classes/stop', { method: 'GET' })
      this.stopTimes = res
    },
    submit: async function () {
      const json = {
        start: this.newStopStart,
        end: this.newStopEnd,
        reason: this.newStopReason
      }
      await fetchJson('/db/trial-classes/stop', { json, method: 'POST' })
      await this.fetch()
      this.newStopStart = null
      this.newStopEnd = null
      this.newStopReason = ''
    },
    del: async function (index) {
      const line = this.stopTimes[index]
      await fetchJson('/db/trial-classes/stop', { json: line, method: 'DELETE' })
      this.stopTimes.splice(index, 1)
    }
  }
})
</script>
<template>
  <div id="modal-base-flat">
    <div class="body">
      <h3>Notes:</h3>
      <p>A stop means no one can book trial-classes in that period, so be careful to set them.</p>
      <p>The timezone is base on the PDT.</p>
      <p>The past stops will be auto removed.</p>
      <p>The stop can be lost. so don't set the stop for too long, better to only set within a month.</p>
      <h2>Existed Stops</h2>
      <div class="exists">
        <div
          v-for="(line, index) in stopTimes"
          :key="`${line.reason}-${index}`"
          class="stop-line"
        >
          <div class="start">
            {{ moment(line.start).format('lll') }}
          </div>
          <div class="split">
            --
          </div>
          <div class="end">
            {{ moment(line.end).format('lll') }}
          </div>
          <div class="reason">
            {{ line.reason }}
          </div>
          <div
            class="delete btn btn-danger"
            @click="del(index)"
          >
            Delete
          </div>
        </div>
      </div>
      <h2>New Stop</h2>
      <div class="input">
        <label for="newStopStart">Start</label>
        <input
          v-model="newStopStart"
          type="datetime-local"
        >
        <label for="newStopEnd">End</label>
        <input
          v-model="newStopEnd"
          type="datetime-local"
        >
        <br>
        <label for="newStopReason">Reason</label>
        <input
          v-model="newStopReason"
          type="text"
          placeholder="Holiday?"
        >
      </div>
      <br>
      <div class="buttons">
        <a
          class="btn btn-primary btn-lg"
          @click="submit"
        >
          Add
        </a>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.body {
  width: 800px;
  margin-left: -100px;
  background: #F4FAFF;
  box-shadow: 2px 2px 2px 2px #777;
  padding: 5px;
  font-size: 18px;
}
.stop-line {
  display: flex;

  .start, .end, .reason {
    width: 200px;
  }
  .split {
    width: 40px;
  }
  .delete {
    width: 100px;
  }
}
.input {
  display: flex;
  align-items: center;
}
.buttons {
  width: 600px;
  display: flex;
  justify-content: space-between;
}
</style>
