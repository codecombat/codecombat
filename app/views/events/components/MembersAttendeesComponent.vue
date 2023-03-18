<template>
  <div class="flex">
    <div class="current" v-for="m in members" :key="m">
      <input type="checkbox" name="" v-model="memberAttendencee[m]" />
      <div class="name"></div>
      <input
        name="m"
        type="text"
        v-model="memberAttendencee[m].description"
      >
    </div>
  </div>
</template>

<script>
export default {
  name: 'MembersComponent',
  components: {
  },
  props: {
    members: {
      type: Set,
      default () { return new Set() }
    }
  },
  data () {
    return {
      memberNameMap: {},
      memberAttendencee: {}
    }
  },
  methods: {
  },
  mounted () {
    Array.from(this.members).forEach(m => {
      this.memberAttendencee[m] = {
        attendence: false,
        description: ''
      }
    })
  }
}
</script>

<style>
</style>
