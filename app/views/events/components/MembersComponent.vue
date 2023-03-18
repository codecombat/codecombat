<template>
  <div class="flex">
    <div class="title">
      <div>name</div>
      <div>startDate</div>
      <div>count</div>
    </div>
    <div class="current" v-for="m in members" :key="m">
      <input
        name="m"
        type="text"
        disabled="true"
        :value="memberNameMap[m]"
      >
      <input name="" type="date" value=""/>
      <input name="" type="number" value=""/>
      <div
        class="remove icon-remove"
        @click="removeMember(m)"
      >
      </div>
    </div>
    <div class="new">
      <user-search
        :role="'student'"
        :value="newMember"
        @select="selectNewMember"
      />
      <div
        class="plus icon-plus"
        :class="{disabled: !newMember}"
        @click="addMember"
      />
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
      type: Set,
      default () { return new Set() }
    }
  },
  data () {
    return {
      newMember: '',
      memberNameMap: {}
    }
  },
  methods: {
    selectNewMember (u) {
      this.memberNameMap[u._id] = u.name
      this.newMember = u._id
    },
    addMember () {
      this.$emit('new-member', this.newMember)
      this.newMember = ''
    },
    removeMember (member) {
      this.$emit('remove-member', member)
    }
  }
}
</script>

<style>
</style>
