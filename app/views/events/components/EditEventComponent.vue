<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import { HTML5_FMT_DATETIME_LOCAL } from '../../../core/constants'
import { RRuleGenerator, rruleGeneratorModule } from 'vue2-rrule-generator'
import MembersComponent from './MembersComponent'
import UserSearchComponent from './UserSearchComponent'

export default {
  name: 'EditEventComponent',
  components: {
    'rrule-generator': RRuleGenerator,
    members: MembersComponent,
    'user-search': UserSearchComponent
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
    selectOwner (id) {
      Vue.set(this.event, 'owner', id)
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
      console.log(this.event, m)
      this.event.members.add(m)
    },
    onFormSubmit () {
      this.event.type = 'online-classes'
      this.event.rrule = this.rrule.toString()
      this.saveEvent(this.event).then(res => {
        console.log('post done')
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
        return moment(this.event.startDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.event, 'startDate', moment(val).toDate())
      }
    },
    _endDate: {
      get () {
        return moment(this.event.endDate).format(HTML5_FMT_DATETIME_LOCAL)
      },
      set (val) {
        this.$set(this.event, 'endDate', moment(val).toDate())
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
    const addHours = (date, hours) => {
      date.setHours(date.getHours() + hours)
      return date
    }
    this.event = _.clone(this.propsEvent) || {
      members: new Set(),
      startDate: new Date(),
      endDate: addHours(new Date(), 1),
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
          :value="event.owner"
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
      <!-- todo: add member in single panel -->
      <!-- <div class="form-group">
           <label for="members">{{ $t('events.members') }}</label>
           <members
           :members="event.members"
           @new-member="addMember"
           />
           </div> -->

      <rrule-generator
        :start="rruleStart"
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
