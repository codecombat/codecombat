<script>
  import CapstoneCodeComponent from '../../common/CapstoneCodeComponent'

  export default {
    components: {
      CapstoneCodeComponent
    },

    props: {
      panelSessionContent: {
        type: Object,
        required: true
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
    <a>View more details on the Student Projects page.</a>
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
