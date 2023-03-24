<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import { HTML5_FMT_DATETIME_LOCAL } from '../../../core/constants'
import UserSearchComponent from './UserSearchComponent'
import MembersAttendeesComponent from './MembersAttendeesComponent'


export default {
  name: 'EditInstanceComponent',
  components: {
    'user-search': UserSearchComponent,
    'members-attendees': MembersAttendeesComponent
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
    selectOwner (id) {
      Vue.set(this.instance, 'owner', id)
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
      this.instance.members = Object.values(this.memberAttendees).map(ma => _.pick(ma, ['userId', 'attendance', 'description']))
      this.saveInstance(this.instance).then(res => {
        // todo
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
        return moment(this.instance.startDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.instance, 'startDate', moment(val).toDate())
      }
    },
    _endDate: {
      get () {
        return moment(this.instance.endDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.instance, 'endDate', moment(val).toDate())
      }
    },
  },
  mounted () {
    this.instance = _.clone(this.propsInstance)
    if (new Date() > new Date(this.instance.endDate)) {
      this.$set(this.instance, 'done', true)
    }
    this.propsEvent.members.forEach(m => {
      if (m.startIndex <= this.instance.index && m.startIndex + m.count > this.instance.index) {
        const existMember = _.find(this.instance.members, { userId: m.userId })
        this.$set(this.memberAttendees, m.userId, _.merge({
          userId: m.userId,
          name: m.name,
          attendance: false,
          description: ''
        }, existMember))
      }
    })
  }
}
</script>

<template>
  <div>
    <form
      class="edit-instance-form"
      @submit.prevent="onFormSubmit"
    >
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
          :value="instance.ownerName"
          @select="selectOwner"
        />
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
</style>
