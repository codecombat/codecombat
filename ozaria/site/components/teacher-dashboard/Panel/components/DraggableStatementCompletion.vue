<script>
export default {
  props: {
    panelSessionContent: {
      type: Object,
      required: true
    }
  }
}
</script>

<template>
  <div>
    <div class="prompt">
      <h4>Prompt: {{ ` ${panelSessionContent.prompt}` }}</h4>
    </div>
    <div class="draggable-statement-completion">
      <div class="flex-row">
        <h4>Student's 1st Submission</h4>
      </div>
      <div class="flex-row">
        <div
          v-for="{ text, correct } in panelSessionContent.submissionText"
          :key="`${text}-student-${correct}`"
          :class="{ 'is-wrong': !correct }"
        >
          <p>{{ text }}</p>
        </div>
      </div>
      <div class="flex-row">
        <div
          v-for="{ text } in panelSessionContent.labels"
          :key="text"
          class="code-label"
        >
          <p>{{ text }}</p>
        </div>
      </div>
      <div class="flex-row">
        <h4 class="solution">
          Solution
        </h4>
      </div>
      <div class="flex-row">
        <div
          v-for="{ text } in panelSessionContent.solutionText"
          :key="`${text}-sol`"
        >
          <p>{{ text }}</p>
        </div>
      </div>
      <div class="flex-row">
        <div
          v-for="{ text } in panelSessionContent.labels"
          :key="text"
          class="code-label"
        >
          <p>{{ text }}</p>
        </div>
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

  .draggable-statement-completion {
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

    & > div:not(.code-label) {
      flex: 1 1 0px;
      margin: 6px;

      border: 1px solid #d8d8d8;
      box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);

      display: flex;
      justify-content: center;
      align-items: center;

      &.is-wrong {
        border: 1px solid #eb003b;
      }
    }

    .code-label {
      flex: 1 1 0px;
      margin: -6px 6px 40px;

      p {
        text-align: start;
        font-size: 12px;
      }
    }

    p {
      @include font-p-5-fine-print;
      margin: 0;
      text-align: center;
      padding: 5px;
      font-family: 'Roboto Mono';
    }
  }

</style>
