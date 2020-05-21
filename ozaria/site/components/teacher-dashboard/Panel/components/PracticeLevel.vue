<script>
  import CodeArea from '../../common/CodeArea'

  export default {
    components: {
      CodeArea
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
  <div class="practice-level">
    <div class="flex-row">
      <div>
        <h4>Starter Code</h4>
        <code-area
          :code="panelSessionContent.starterCode"
          :language="panelSessionContent.language"
        />
      </div>
      <div />
    </div>
    <div class="flex-row">
      <div>
        <h4>Student Code</h4>
        <code-area
          :code="panelSessionContent.studentCode"
          :language="panelSessionContent.language"
        />
      </div>
      <div>
        <h4>Solution</h4>
        <code-area
          :code="panelSessionContent.solutionCode"
          :language="panelSessionContent.language"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  .practice-level {
    padding: 23px 14px;
  }

  h4 {
    @include font-p-4-paragraph-smallest-gray;
    color: black;
    font-weight: 600;
    line-height: 18px;

    margin-bottom: 10px;
  }

  .flex-row {
    display: flex;
    flex-direction: row;
    justify-content: space-between;

    & > div {
      flex: 1 1 0px;
      margin: 6px;
    }
  }

</style>
