<script>
  import Dropdown from '../common/Dropdown'
  import ProgressLabels from '../common/progress/progressLabels'
  export default {
    components: {
      'dropdown': Dropdown,
      'progress-labels': ProgressLabels
    },
    props: {
      capstoneLevel: {
        type: Object,
        default: () => {}
      },
      levelSessions: {
        type: Object,
        default: () => {}
      },
      members: {
        type: Array,
        default: () => []
      }
    },
    data () {
      return {
        sortOptions: ['First Name']
      }
    }
  }
</script>

<template>
  <div>
    <div class="header">
      <dropdown
        label-text="Sort By"
        class="dropdown"
        :options="sortOptions"
      />
      <progress-labels />
      <!-- TODO: Students row, pass in student name, session status, student code, level goals -->
    </div>
  </div>
</template>

<style lang="scss" scoped>
.header {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
  margin: 15px;
}

.dropdown {
  width: 170px;
}
</style>
