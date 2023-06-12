<template>
  <div class="classes-stats">
    <ul class="tabs nav nav-tabs">
      <li class="tab" :class="{active: selectedTab === 'students'}" @click="selectedTab = 'students'">
        <a href="#students">Students</a>
      </li>
      <li class="tab" :class="{active: selectedTab === 'teachers'}" @click="selectedTab = 'teachers'">
        <a href="#teachers">Teachers</a>
      </li>
    </ul>
    <students-stats :events="events" v-if="selectedTab === 'students'" />
    <teachers-stats :events="events" v-else />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import moment from 'moment'
import StudentsStats from './StudentsStats'
import TeachersStats from './TeachersStats'
export default {
  name: 'ClassesStats',
  components: {
    StudentsStats,
    TeachersStats
  },
  props: {
    events: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      selectedTab: 'students'
    }
  },
  mounted () {
    this.getMemberNames()
  },
  methods: {
    ...mapActions({
      getMemberNames: 'events/fetchMemberNames'
    }),
    clearSearch () {
      this.selectedStudent = {}
    },
    selectStudent (u) {
      this.selectedStudent = u
    }
  }
}
</script>

<style lang="scss" scoped>
.classes-stats{
}
</style>
