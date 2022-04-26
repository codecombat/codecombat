<script>
  import CapstoneCodeComponent from '../../common/CapstoneCodeComponent'
  import { mapGetters } from 'vuex'

  export default {
    components: {
      CapstoneCodeComponent
    },

    props: {
      panelSessionContent: {
        type: Object,
        required: true
      }
    },

    computed: {
      ...mapGetters({
        classroomId: 'teacherDashboard/classroomId'
      }),

      projectURL () {
        return `/teachers/projects/${this.classroomId}`
      }
    }
  }
</script>

<template>
  <div class="capstone-level">
    <capstone-code-component
      :game-goals="panelSessionContent.gameGoals"
      :capstone-session-code="panelSessionContent.studentCode"
      :capstone-session-language="panelSessionContent.language"
    />
    <a :href="projectURL">View more details on the Student Projects page.</a>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  .capstone-level {
    padding: 23px 14px;
  }

  a {
    @include font-p-3-paragraph-small-blue-link;
    text-decoration: underline;
  }

</style>
