<template>
  <div class="flex">
    <div class="title row">
      <div class="name col-sm-4">
        {{ $t('general.name') }}
      </div>
      <div class="startDate col-sm-4">
        {{ $t('outcomes.start_date') }}
      </div>
      <div class="count col-sm-3">
        {{ $t('events.class_count') }}
      </div>
    </div>
    <div
      v-for="(member, id) in members"
      :key="id"
      class="current row"
    >
      <input
        class="name col-sm-4"
        name="m"
        type="text"
        disabled="true"
        :value="member.name"
      >
      <input
        class="startdate col-sm-4"
        type="date"
        :value="formatDate(member)"
        disabled
      >
      <input
        class="count col-sm-3"
        type="number"
        :value="member.count"
        @input="updateMember(id, 'count', $event.target.value)"
      >
      <div
        class="remove icon-remove"
        @click="removeMember(id)"
      />
    </div>
    <div class="split" />
    <div class="new">
      <user-search
        class="user-search"
        :role="'student'"
        :value="newMember.name"
        @select="selectNewMember"
      />
      <button
        class="btn btn-primary btn-add-member"
        :class="{disabled: !newMember._id}"
        @click="addMember"
      >
        {{ $t('events.add_member') }}
      </button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import UserSearchComponent from './UserSearchComponent'
import _ from 'lodash'
export default {
  name: 'MembersComponent',
  components: {
    'user-search': UserSearchComponent
  },
  props: {
    members: {
      type: Object
    }
  },
  computed: {
    ...mapGetters({
      propsEvent: 'events/eventPanelEvent'
    })
  },
  data () {
    return {
      newMember: {}
    }
  },
  methods: {
    formatDate (member) {
      let date
      if (member.startDate) {
        date = member.startDate
      } else {
        date = _.find(this.propsEvent.instances, { index: member.startIndex }).startDate
      }
      return date.toString().slice(0, 10)
    },
    selectNewMember (u) {
      this.newMember = u
    },
    addMember () {
      this.$emit('new-member', this.newMember)
      this.newMember = {}
    },
    removeMember (member) {
      this.$emit('remove-member', member)
    },
    updateMember (id, key, value) {
      if (key === 'count') {
        value = parseInt(value)
      }
      this.$emit('update-member', {id, key, value})
    }
  }
}
</script>

<style lang="scss">
.title {
  font-weight: bold;
  margin-bottom: 10px;
}

.split {
  margin: 20px 0;
  border-bottom: 1px solid #ccc;
  height: 1px;
}

.new {
  display: flex;
  margin-bottom: 15px;

  .user-search {
    flex-grow: 1;
  }
  .plus {
    flex-shrink: 1;
  }
}
</style>
