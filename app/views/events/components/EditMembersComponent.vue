<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
import moment from 'moment'
import { HTML5_FMT_DATETIME_LOCAL } from '../../../core/constants'
import MembersComponent from './MembersComponent'

export default {
  name: 'EditMembersComponent',
  components: {
    MembersComponent
  },
  data () {
    return {
      isSuccess: false,
      inProgress: false,
      errorMessage: '',
      members: new Set(),
      membersToAdd: new Set(),
      membersToRemove: new Set()
    }
  },
  methods: {
    ...mapMutations('events', [
      'setEvent'
    ]),
    ...mapActions('events', [
      'addEventMember',
      'delEventMember'
    ]),
    addMember (m) {
      this.members.add(m)
      this.membersToAdd.add(m)
      this.membersToRemove.delete(m)
      this.members = new Set(this.members.values())
    },
    removeMember (m) {
      this.members.delete(m)
      this.membersToRemove.add(m)
      this.membersToAdd.delete(m)
      this.members = new Set(this.members.values())
    },
    onFormSubmit () {
      const promises = []
      Array.from(this.membersToRemove).forEach(m => {
        promises.push(this.delEventMember({
          eventId: this.propsEvent._id,
          member: m
        }))
      })
      Array.from(this.membersToAdd).forEach(m => {
        promises.push(this.addEventMember({
          eventId: this.propsEvent._id,
          member: m
        }))
      })
      Promise.all(promises).then(() => {
        this.$emit('save')
      }).catch(err => {
        this.errorMessage = err.message
      })
    }
  },
  computed: {
    ...mapGetters({
      propsEvent: 'events/eventPanelEvent'
    })
  },
  created () {
  },
  mounted () {
    this.members = new Set(this.propsEvent.members)
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
        <label for="members"> {{ $t('events.members') }}</label>
        <members-component
          :members="members"
          @new-member="addMember"
          @remove-member="removeMember"
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
</style>
