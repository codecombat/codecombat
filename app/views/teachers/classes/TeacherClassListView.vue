<style scoped>
    ul.teacher-list {
        margin: 0;
        padding: 0;
    }
</style>

<template>
    <ul class="teacher-list">
        <classroom-list-row
                v-for="classroom in activeClassrooms"
                :key="classroom._id"
                :classroom="classroom">
        </classroom-list-row>
    </ul>
</template>

<script>
  import ClassroomListRow from './ClassroomListRow'

  export default {
    components: {
      'classroom-list-row': ClassroomListRow
    },

    props: {
      activeClassrooms: Array
    }
  }
</script>

