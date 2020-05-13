<script>
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

    methods: {
      changeCheckbox (displayName) {
        // TODO hook this up to Vuex to change checkbox state.
        console.log('Toggled Checkbox for:', displayName)
      }
    }
  }
</script>
<template>
  <div id="studentList">
    <CellStudent
      v-for="{ displayName, checked } of students"
      :key="displayName"

      :student-name="displayName"
      :checked="checked"

      @change="changeCheckbox(displayName)"
    />
  </div>
</template>

<style lang="scss" scoped>

#studentList {
  position: sticky;
  position: -webkit-sticky; /* Safari */

  left: 0;
  max-width: 190px;
  width: 190px;

  text-align: right;
}
</style>
