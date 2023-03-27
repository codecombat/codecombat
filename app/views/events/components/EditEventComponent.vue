<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import { HTML5_FMT_DATE_LOCAL, HTML5_FMT_TIME_LOCAL } from '../../../core/constants'
import { RRuleGenerator, rruleGeneratorModule } from 'vue2-rrule-generator'
import VueTimepicker from 'vue2-timepicker'
import MembersComponent from './MembersComponent'
import UserSearchComponent from './UserSearchComponent'

export default {
  name: 'EditEventComponent',
  props: {
    editType: {
      type: String,
      default: 'new'
    }
  },
  components: {
    'rrule-generator': RRuleGenerator,
    'user-search': UserSearchComponent,
    'time-picker': VueTimepicker
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
    ...mapActions('events', [
      'saveEvent'
    ]),
    selectOwner (u) {
      Vue.set(this.event, 'owner', u._id)
      Vue.set(this.event, 'ownerName', u.name)
    },
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
      this.event.members.add(m)
    },
    onFormSubmit () {
      this.event.type = 'online-classes'
      this.event.rrule = this.rrule.toString()
      this.saveEvent(this.event).then(res => {
        this.$emit('save')
      })
    }
  },
  computed: {
    ...mapGetters({
      propsEvent: 'events/eventPanelEvent',
      rrule: 'rruleGenerator/rule'
    }),
    _startDate: {
      get () {
        return moment(this.event.startDate).format(HTML5_FMT_DATE_LOCAL)
      },
      set (val) {
        // update startDate and endDate at the same time
        this.$set(this.event, 'startDate', moment(`${val} ${this._startTime}`).toDate())
        this.$set(this.event, 'endDate', moment(`${val} ${this._endTime}`).toDate())
      }
    },
    _startTime: {
      get () {
        return moment(this.event.startDate).format(HTML5_FMT_TIME_LOCAL)
      },
      set (val) {
        this.$set(this.event, 'startDate', moment(`${this._startDate} ${val}`).toDate())
      }
    },
    _endTime: {
      get () {
        return moment(this.event.endDate).format(HTML5_FMT_TIME_LOCAL)
      },
      set (val) {
        // use _startDate here since startDate and endDate share the date
        this.$set(this.event, 'endDate', moment(`${this._startDate} ${val}`).toDate())
      }
    },
    rruleStart () {
      return moment(this.event.startDate).toDate()
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
    const sDate = moment().set('minutes', 0).set('seconds', 0)
    this.event = _.clone(this.propsEvent) || {
      members: new Set(),
      startDate: sDate.toDate(),
      endDate: sDate.clone().add(1, 'hours').toDate(),
      instances: []
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
        <user-search
          :role="'teacher'"
          :value="event.ownerName"
          @select="selectOwner"
        />
      </div>
      <div class="from-group">
        <label for="startDate"> {{ $t('events.start_date') }}</label>
        <input
          v-model="_startDate"
          type="date"
          class="form-control"
          name="startDate"
        >
      </div>
      <div class="from-group">
        <label for="timeRange"> {{ $t('events.time_range') }}</label>
        <div>
          <time-picker format="HH:mm" :minute-interval="10" v-model="_startTime" />
          <span>-</span>
          <time-picker format="HH:mm" :minute-interval="10" v-model="_endTime" />
        </div>
      </div>
      <rrule-generator
        v-if="editType === 'new' || event.rrule"
        :start="rruleStart"
        :option="{showStart: false}"
        :rrule="event.rrule"
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
@import '~vue2-timepicker/dist/VueTimepicker.css';
</style>
