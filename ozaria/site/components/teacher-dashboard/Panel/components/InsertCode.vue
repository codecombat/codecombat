<script>
import CodeArea from '../../common/CodeArea'
import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'

export default {
  components: {
    CodeArea
  },

  props: {
    panelSessionContent: {
      type: Object,
      required: true
    }
  },

  computed: {
    ozariaAssetUrl () {
      return `url("${getOzariaAssetUrl(this.panelSessionContent.interactiveArt)}")`
    }
  }
}
</script>

<template>
  <div>
    <div class="prompt">
      <h4>Prompt: {{ ` ${panelSessionContent.prompt}` }}</h4>
    </div>
    <div class="insert-code">
      <div class="flex-row">
        <div
          :style="{ backgroundImage: ozariaAssetUrl }"
          class="img"
        />
        <div class="flex-col">
          <code-area
            :code="panelSessionContent.code"
            language="javascript"
          />
          <h4>Options</h4>
          <ul>
            <li
              v-for="{ text } in panelSessionContent.options"
              :key="text"
            >
              <p>{{ text }}</p>
            </li>
          </ul>
        </div>
      </div>

      <div class="flex-row">
        <div class="flex-col">
          <h4>Student's 1st Submission</h4>
          <div :class="{'code-box': true, 'is-error': !panelSessionContent.studentSubmission.correct}">
            <p>{{ panelSessionContent.studentSubmission.text }}</p>
          </div>
        </div>
        <div class="flex-col">
          <h4>Solution</h4>
          <div class="code-box">
            <p>{{ panelSessionContent.solution.text }}</p>
          </div>
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

  .insert-code {
    padding: 23px 14px;
  }

  p {
    @include font-p-5-fine-print;
    margin: 0;
    text-align: center;
    padding: 5px;
    font-family: 'Roboto Mono';
  }

  h4 {
    @include font-p-4-paragraph-smallest-gray;
    color: black;
    font-weight: 600;
    line-height: 18px;
    font-size: 14px;

    margin-bottom: 10px;
    margin-top: 21px;
  }

  .flex-row {
    display: flex;
    flex-direction: row;
    justify-content: space-between;

    & > div {
      flex: 2 2 0px;
    }

    .img {
      flex: 1 1 0px;
      background-size: contain;
      background-position: center;
      background-repeat: no-repeat;
      margin-right: 14px;
    }
  }

  .flex-col {
    display: flex;
    flex-direction: column;
  }

  ul {
    padding: 0;
    margin: 0;
    list-style: none;

    li {
      width: 100%;
      padding: 5px;
      margin-bottom: 10px;

      background-color: #e6e6e6;
      border: 1px solid #d8d8d8;
      box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);

      color: black;

      p {
        @include font-p-5-fine-print;
        margin: 0;
        text-align: center;
        padding: 5px;
        font-family: 'Roboto Mono';
      }
    }
  }

  .code-box {
    padding: 5px;

    border: 1px solid #d8d8d8;
    margin: 0 10px;

    &.is-error {
      border: 1px solid #eb003b;
    }

    box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);
  }

</style>
