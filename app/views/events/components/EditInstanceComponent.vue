<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import VueTimepicker from 'vue2-timepicker'
import { HTML5_FMT_DATE_LOCAL, HTML5_FMT_TIME_LOCAL } from '../../../core/constants'
import UserSearchComponent from './UserSearchComponent'
import MembersAttendeesComponent from './MembersAttendeesComponent'


export default {
  name: 'EditInstanceComponent',
  components: {
    'user-search': UserSearchComponent,
    'members-attendees': MembersAttendeesComponent,
    'time-picker': VueTimepicker
  },
  data () {
    return {
      isSuccess: false,
      inProgress: false,
      errorMessage: '',
      instance: {},
      memberAttendees: {}
    }
  },
  methods: {
    ...mapActions('events', [
      'saveInstance'
    ]),
    selectOwner (u) {
      Vue.set(this.instance, 'owner', u._id)
      Vue.set(this.instance.ownerDetails, 'name', u.name)
    },
    toggleMember (m) {
      const bool = this.memberAttendees[m].attendance
      this.$set(this.memberAttendees[m], 'attendance', !bool)
    },
    updateDescription (desc) {
      console.log('update?', desc.id, desc.value)
      this.$set(this.memberAttendees[desc.id], 'description', desc.value)
    },
    onFormSubmit () {
      this.inProgress = true
      this.instance.members = Object.values(this.memberAttendees).map(ma => _.pick(ma, ['userId', 'attendance', 'description']))
      this.saveInstance(this.instance).then(res => {
        this.$emit('save', this.instance.event)
        this.inProgress = false
      }).catch(err => {
        this.errorMessage = err.message
      })
    },

    instanceUpdate () {
      this.instance = _.cloneDeep(this.propsInstance)
      if (new Date() > new Date(this.instance.endDate)) {
        this.$set(this.instance, 'done', true)
      }
      this.memberAttendees = {}
      this.propsEvent.members.forEach(m => {
        if (m.startIndex <= this.instance.index && m.startIndex + m.count > this.instance.index) {
          const existMember = _.find(this.instance.members, { userId: m.userId })
          this.$set(this.memberAttendees, m.userId, _.merge({
            userId: m.userId,
            name: m.name,
            attendance: true,
            description: ''
          }, existMember))
        }
      })
    }
  },
  computed: {
    ...mapGetters({
      propsInstance: 'events/eventPanelInstance',
      propsEvent: 'events/eventPanelEvent'
    }),
    _startDate: {
      get () {
        return moment(this.instance.startDate).format(HTML5_FMT_DATE_LOCAL)
      },
      set (val) {
        this.$set(this.instance, 'startDate', moment(`${val} ${this._startTime}`).toDate())
        this.$set(this.instance, 'endDate', moment(`${val} ${this._endTime}`).toDate())
      }
    },
    _startTime: {
      get () {
        return moment(this.instance.startDate).format(HTML5_FMT_TIME_LOCAL)
      },
      set (val) {
        this.$set(this.instance, 'startDate', moment(`${this._startDate} ${val}`).toDate())
      }
    },
    _endTime: {
      get () {
        return moment(this.instance.endDate).format(HTML5_FMT_TIME_LOCAL)
      },
      set (val) {
        // use _startDate here since startDate and endDate share the date
        this.$set(this.instance, 'endDate', moment(`${this._startDate} ${val}`).toDate())
      }
    },
  },
  watch: {
    propsInstance () {
      this.instanceUpdate()
    }
  },
  mounted () {
    this.instanceUpdate()
  }
}
</script>

<template>
  <div>
    <div class="tab-label">
      {{ $t('events.edit_instance_tab_desc') }}
    </div>
    <form
      class="edit-instance-form"
      @submit.prevent="onFormSubmit"
    >
      <div class="from-group">
        <label for="name"> {{ $t('events.name') }}</label>
        <input
          :value="propsEvent.name"
          name="name"
          class="form-control"
          type="text"
          disabled
        >
      </div>
      <div class="from-group">
        <label for="description"> {{ $t('events.description') }}</label>
        <input
          :value="propsEvent.description"
          name="description"
          class="form-control"
          type="text"
          disabled
        >
      </div>
      <div class="from-group">
        <label for="done"> {{ $t('events.done') }}</label>
        <input
          v-model="instance.done"
          type="checkbox"
          class="form-control"
          name="done"
          :disabled="new Date(instance.endDate) > new Date()"
        >
      </div>
      <div class="from-group">
        <label for="owner"> {{ $t('events.owner') }}</label>
        <user-search
          :role="'teacher'"
          :value="instance.ownerDetails?.name"
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
      <div class="form-group">
        <label for="video"> {{ $t('events.video_recording') }}</label>
        <input
          v-model="instance.video"
          type="text"
          class="form-control"
          name="video"
        >
      </div>
      <div class="form-group">
        <label for="members">{{ $t('events.members') }}</label>
        <!-- TODO: select participants -->
        <members-attendees
          :instance="propsInstance"
          :members="memberAttendees"
          @toggle-select="toggleMember"
          @update-description="updateDescription"
        />
      </div>

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
  </div>
</template>

<style lang="scss" scoped>
@import '~vue2-rrule-generator/dist/vue2-rrule-generator.css';
@import '~vue2-timepicker/dist/VueTimepicker.css';

.tab-label {
  font-size: 15px;
  color: rgba(128, 128, 128, 0.7);
}
</style>
