<style scoped>
    .progress-dot {
        display: flex;
        align-items: center;
        justify-content: center;

        margin: 10px;

        width: 62px;
        height: 62px;

        border-radius: 50%;

        color: #FFF;
        font-size: 18px;

        background-color: rgb(153, 153, 153);
    }
</style>

<template>
    <li class="progress-dot">
        {{ courseAcronym }}
    </li>
</template>

<script>
  import { mapState } from 'vuex'

  export default {
    props: {
      course: Object
    },

    computed: Object.assign({},
      // TODO this could be loading (top level component prevents this now but may not in future).  Handle loading state here
      mapState('courses', { 'courses': 'byId' }),

      {
        // TODO course acronym could be controlled and sent from the backend
        courseAcronym: function() {
          const course = this.courses[this.$props.course._id]

          let prefix = 'CS';
          if (/game-dev/.test(course.slug)) {
            prefix = 'GD'
          } else if (/web-dev/.test(course.slug)) {
            prefix = 'WD'
          }

          let number = '1';
          const numberMatch = (course.slug || '').match(/(\d+)$/)
          if (numberMatch && numberMatch[1]) {
            number = numberMatch[1]
          }

          return `${prefix}${number}`
        }
      })
  }
</script>
