<template>
  <div class="flex">
    <div class="title">
      <div class="name">
        {{ $t('general.name') }}
      </div>
      <div class="startDate">
        {{ $t('outcomes.start_date') }}
      </div>
      <div class="count">
        {{ $t('events.class_count') }}
      </div>
    </div>
    <div
      v-for="(member, id) in members"
      :key="id"
      class="current"
    >
      <input
        calss="name"
        name="m"
        type="text"
        disabled="true"
        :value="member.name"
      >
      <input
        class="startdate"
        type="date"
        :value="formatDate(member.startDate)"
        disabled
      >
      <input
        class="count"
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
        :value="newMember"
        @select="selectNewMember"
      />
      <button
        class="btn btn-primary btn-add-member"
        :class="{disabled: !newMember}"
        @click="addMember"
      >
        {{ $t('events.add_member') }}
      </button>
    </div>
  </div>
</template>

<script>
import UserSearchComponent from './UserSearchComponent'
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
  data () {
    return {
      newMember: '',
    }
  },
  methods: {
    formatDate (date) {
      return date.toString().slice(0, 10)
    },
    selectNewMember (u) {
      this.newMember = u
    },
    addMember () {
      this.$emit('new-member', this.newMember)
      this.newMember = ''
    },
    removeMember (member) {
      this.$emit('remove-member', member)
    },
    updateMember (id, key, value) {
      this.$emit('update-member', {id, key, value})
    }
  }
}
</script>

<style lang="scss">
.title {
  display: flex;
  justify-content: space-between;
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
