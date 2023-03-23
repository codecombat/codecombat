<template>
  <div class="flex">
    <div
      v-for="m in members"
      :key="m.userId"
      class="attendance"
    >
      <input
        v-model="memberAttendencee[m]"
        type="checkbox"
      >
      <div class="name">
        {{ m.name }}
      </div>
      <input
        :value="memberAttendencee[m.userId.toString()]?.description"
        name="m"
        type="text"
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
    instance: {
      type: Object,
      default () { return {} }
    },
    members: {
      type: Array,
      default () { return [] }
    }
  },
  data () {
    return {
      memberNameMap: {},
      memberAttendencee: {}
    }
  },
  mounted () {
    Array.from(this.members).forEach(m => {
      if (m.startIndex + m.count > this.instance.index) {
        this.memberAttendencee[m.userId.toString()] = {
          attendance: false,
          description: ''
        }
      }
    })
  },
  methods: {
  }
}
</script>

<style>
</style>
