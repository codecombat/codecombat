<script>
export default {
  props: {
    panelSessionContent: {
      type: Object,
      required: true
    }
  },

  computed: {
    cssVariables () {
      return {
        '--cols': `${this.panelSessionContent.solutionText?.length || 0}`
      }
    }
  }
}
</script>

<template>
  <div
    class="draggable-ordering"
    :style="cssVariables"
  >
    <div class="prompt">
      <h4>Prompt: {{ ` ${panelSessionContent.prompt}` }}</h4>
    </div>
    <div class="grid-wrapper">
      <h4>Student's 1st Submission</h4>
      <div
        v-for="{ text, correct } in panelSessionContent.submissionText"
        :key="`${text}-student-${correct}`"
        :class="{ 'is-wrong': !correct }"
      >
        <p>{{ text }}</p>
      </div>
      <h4 class="solution">
        Solution
      </h4>
      <div
        v-for="{ text } in panelSessionContent.solutionText"
        :key="`${text}-sol`"
      >
        <p>{{ text }}</p>
      </div>
      <div class="spacer" />
      <div
        v-for="{ text } in panelSessionContent.lastColText"
        :key="text"
        class="finalCol"
      >
        <p>{{ text }}</p>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .prompt h4 {
    color: white;
    margin: 0;
  }

  .prompt {
    background-color: #545b64;
    padding: 17px 20px;
  }

  h4 {
    @include font-p-4-paragraph-smallest-gray;
    color: black;
    font-weight: 600;
    line-height: 18px;

    margin-bottom: 10px;
  }

  .grid-wrapper {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-template-rows: auto repeat(var(--cols), 1fr);
    grid-auto-flow: column;
    grid-gap: 10px 20px;
    width: 630px;
    padding: 23px 14px;

    & > div:not(.spacer) {
      display: flex;
      justify-content: center;
      align-items: center;

      padding: 12px;
      border: 1px solid #d8d8d8;
      box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);

      &.is-wrong {
        border: 1px solid #eb003b;
      }

      p {
        @include font-p-5-fine-print;
        margin: 0;
        text-align: center;
      }
    }
  }

  .finalCol {
    background-color: #e6e6e6;
  }

</style>
