<template>
  <div class="flex">
    <input
      v-for="m in members"
      :key="m"
      name="m"
      type="text"
      :value="m"
    >
    <div class="new">
      <input
        v-model="newMember"
        name=""
        type="text"
      >
      <div
        class="plus icon-plus"
        :class="{disabled: !newMember}"
        @click="addMember"
      />
    </div>
  </div>
</template>

<script>
export default {
  name: 'MembersComponent',
  props: {
    members: {
      type: Set,
      default () { return new Set() }
    }
  },
  data () {
    return {
      newMember: ''
    }
  },
  methods: {
    addMember () {
      this.$emit('new-member', this.newMember)
      this.newMember = ''
    }
  }
}
</script>

<style>
</style>
