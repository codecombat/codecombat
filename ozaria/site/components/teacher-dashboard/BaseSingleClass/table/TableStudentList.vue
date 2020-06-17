<script>
  import { mapGetters, mapActions } from 'vuex'

  import CellStudent from './CellStudent'
  export default {
    components: {
      CellStudent
    },

    props: {
      students: {
        type: Array,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        isStudentSelected: 'baseSingleClass/isStudentSelected'
      })
    },

    methods: {
      ...mapActions({
        toggleStudentSelectedId: 'baseSingleClass/toggleStudentSelectedId'
      }),

      changeCheckbox (id) {
        this.toggleStudentSelectedId({ studentId: id })
      }
    }
  }
</script>
<template>
  <div id="studentList">
    <CellStudent
      v-for="{ displayName, _id, isEnrolled } of students"
      :key="_id"

      :student-id="_id"
      :student-name="displayName"
      :is-enrolled="isEnrolled"

      :checked="isStudentSelected(_id)"

      @change="changeCheckbox(_id)"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";

#studentList {
  position: sticky;
  position: -webkit-sticky; /* Safari */

  left: 0;
  max-width: $studentNameWidth;
  width: $studentNameWidth;

  text-align: right;
}
</style>
