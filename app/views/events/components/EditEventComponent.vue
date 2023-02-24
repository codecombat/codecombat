<script>
import { mapGetters, mapMutations } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import { HTML5_FMT_DATETIME_LOCAL } from '../../../core/constants'
import { RRuleGenerator, rruleGeneratorModule } from 'vue2-rrule-generator'
import MembersComponent from './MembersComponent'

export default {
  name: 'EditEventComponent',
  components: {
    'rrule-generator': RRuleGenerator,
    members: MembersComponent
  },
  data () {
    return {
      isSuccess: false,
      inProgress: false,
      errorMessage: '',
      event: {}
    }
  },
  methods: {
    ...mapMutations('events', [
      'setEvent'
    ]),
    previewOnCalendar () {
      const tempEvent = _.cloneDeep(this.event)
      tempEvent._id = 'temp-event'
      this.makeInstances(tempEvent)
      this.setEvent(tempEvent)
    },
    makeInstances (event) {
      const instance = {
        _id: 'temp-event-' + Math.random(),
        title: 'temp-' + event.name,
        owner: event.owner,
      }
      event.instances = this.rrule.all().map(d => {
        return Object.assign({}, instance, {
          startDate: d,
          endDate: new Date((+event.endDate) - (+event.startDate) + (+d))
        })
      })
    },
    addMember (m) {
      console.log(this.event, m)
      this.event.members.add(m)
    }
  },
  computed: {
    ...mapGetters({
      propsEvent: 'events/eventPanelEvent',
      rrule: 'rruleGenerator/rule'
    }),
    _startDate: {
      get () {
        return moment(this.event.startDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.event, 'startDate', moment(val).toISOString())
      }
    },
    _endDate: {
      get () {
        return moment(this.event.endDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.event, 'endDate', moment(val).toISOString())
      }
    },
    rulePreviewTop6 () {
      return this.rrule.all((date, i) => i < 6).map(d => moment(d).format('ll'))
    }
  },
  created () {
    if (!this.$store.hasModule('rruleGenerator')) {
      this.$store.registerModule('rruleGenerator', rruleGeneratorModule)
    }
  },
  mounted () {
    const addHours = (date, hours) => {
      date.setHours(date.getHours() + hours)
      return date
    }
    this.event = _.clone(this.propsEvent) || {
      members: new Set(),
      startDate: new Date(),
      endDate: addHours(new Date(), 1)
    }
  }
}
</script>

<template>
  <div>
    <form
      class="edit-event-form"
      @submit.prevent="onFormSubmit"
    >
      <div class="from-group">
        <label for="name"> {{ $t('events.name') }}</label>
        <input
          v-model="event.name"
          name="name"
          class="form-control"
          type="text"
        >
      </div>
      <div class="from-group">
        <label for="description"> {{ $t('events.description') }}</label>
        <input
          v-model="event.description"
          name="description"
          class="form-control"
          type="text"
        >
      </div>
      <div class="from-group">
        <label for="owner"> {{ $t('events.owner') }}</label>
        <input
          v-model="event.owner"
          name="owner"
          class="form-control"
          type="text"
        >
      </div>
      <div class="from-group">
        <label for="startDate"> {{ $t('events.start_date') }}</label>
        <input
          v-model="_startDate"
          type="datetime-local"
          class="form-control"
          name="startDate"
        >
      </div>
      <div class="from-group">
        <label for="endDate"> {{ $t('events.end_date') }}</label>
        <input
          v-model="_endDate"
          type="datetime-local"
          class="form-control"
          name="endDate"
        >
      </div>
      <!-- todo: add member in single panel -->
      <!-- <div class="form-group">
           <label for="members">{{ $t('events.members') }}</label>
           <members
           :members="event.members"
           @new-member="addMember"
           />
           </div> -->

      <rrule-generator
        :start="new Date()"
        :option="{showStart: false}"
      />

      <div class="form-group pull-right">
        <span
          v-if="isSuccess"
          class="success-msg"
        >
          {{ $t('teacher.success') }}
        </span>
        <span
          v-if="errorMessage"
          class="error-msg"
        >
          {{ errorMessage }}
        </span>
        <button
          class="btn btn-success btn-lg"
          type="submit"
          :disabled="inProgress"
        >
          {{ $t('common.submit') }}
        </button>
      </div>
    </form>
    <div class="preview">
      <input
        class="btn btn-success btn-lg"
        type="button"
        value="Preview"
        @click="previewOnCalendar"
      >
      <div
        v-for="date in rulePreviewTop6"
        :key="date"
      >
        {{ date }}
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import '~vue2-rrule-generator/dist/vue2-rrule-generator.css';
</style>
