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
      instance: {}
    }
  },
  methods: {
    ...mapMutations('events', [
      'setEvent'
    ]),
    ...mapActions('events', [
      'saveEvent'
    ]),
    selectOwner (id) {
      Vue.set(this.event, 'owner', id)
    },
    previewOnCalendar () {
      const tempEvent = _.cloneDeep(this.event)
      tempEvent._id = 'temp-event'
      this.makeInstances(tempEvent)
      this.setEvent(tempEvent)
    },
    addMember (m) {
      console.log(this.event, m)
      this.event.members.add(m)
    },
    onFormSubmit () {
      this.event.type = 'online-classes'
      this.saveEvent(this.event).then(res => {
        console.log('post done')
        this.$emit('save')
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
  created () {
  },
  mounted () {
    this.instance = _.clone(this.propsInstance)
    if (new Date() > new Date(this.instance.endDate)) {
      this.$set(this.instance, 'done', true)
    }
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
          :instance="instance"
          :members="propsEvent.members"
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
