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
      members: {},
      membersToAdd: new Set(),
      membersToRemove: new Set(),
      membersToEdit: new Set(),
      classCode: ''
    }
  },
  methods: {
    ...mapMutations('events', [
      'setEvent'
    ]),
    ...mapActions('events', [
      'addEventMember',
      'editEventMember',
      'delEventMember',
      'importMembersFromClass'
    ]),
    addMember (m) {
      this.membersToAdd.add(m._id)
      this.membersToRemove.delete(m._id)
      this.$set(this.members, m._id, {
        userId: m._id,
        name: m.name,
        count: this.propsEvent.instances.length - this.propsInstance.index,
        startIndex: this.propsInstance.index,
        startDate: this.propsInstance.startDate
      })
    },
    removeMember (id) {
      this.membersToRemove.add(id)
      this.membersToAdd.delete(id)
      this.$delete(this.members, id)
    },
    updateMember ({ id, key, value }) {
      this.$set(this.members[id], key, value)
      if (!this.membersToAdd.has(id)) {
        this.membersToEdit.add(id)
      }
    },
    importClassroom () {
      this.importMembersFromClass({
        classCode: this.classCode
      }).then((members) => {
        members.forEach(m => {
          this.addMember(m)
        })
      }).catch(err => {
        this.errorMessage = err.message
      })
    },
    onFormSubmit () {
      this.inProgress = true
      const promises = []
      Array.from(this.membersToRemove).forEach(m => {
        promises.push(this.delEventMember({
          eventId: this.propsEvent._id,
          member: { userId: m }
        }))
      })
      Array.from(this.membersToAdd).forEach(m => {
        promises.push(this.addEventMember({
          eventId: this.propsEvent._id,
          member: this.members[m]
        }))
      })
      Array.from(this.membersToEdit).forEach(m => {
        promises.push(this.editEventMember({
          eventId: this.propsEvent._id,
          member: { userId: m, count: this.members[m].count }
        }))
      })
      Promise.all(promises).then(() => {
        this.$emit('save', this.propsEvent._id)
        this.inprogress = false
      }).catch(err => {
        this.errorMessage = err.message
      })
    }
  },
  computed: {
    ...mapGetters({
      propsInstance: 'events/eventPanelInstance',
      propsEvent: 'events/eventPanelEvent'
    })
  },
  mounted () {
    this.members = _.indexBy(_.cloneDeep(this.propsEvent.members), 'userId')
  },
  watch: {
    propsEvent: {
      handler (val) {
        this.members = _.indexBy(_.cloneDeep(val.members), 'userId')
      },
      deep: true
    }
  }
}
</script>

<template>
  <div>
    <form
      class="edit-event-form"
    >
      <div class="from-group">
        <label for="members"> {{ $t('events.members') }}</label>
        <members-component
          :members="members"
          @new-member="addMember"
          @remove-member="removeMember"
          @update-member="updateMember"
        />
      </div>

      <div class="form-group import-from-class">
        <label for="import"> {{ $t('events.import_from_class') }}</label>
        <div class="my-input-group">
        <input
          type="text"
          class="form-control"
          id="import"
          placeholder="Class Code"
          v-model="classCode"
          />
        <input
          type="button"
          class="btn btn-primary"
          value="Import"
          @click="importClassroom"
          />
        </div>
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
          @click="onFormSubmit"
        >
          {{ $t('common.submit') }}
        </button>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
.import-from-class {
  .my-input-group{
    display: flex;
  }
}
</style>
