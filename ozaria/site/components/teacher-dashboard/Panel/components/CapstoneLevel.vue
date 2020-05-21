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
  <div class="capstone-level">
    <div class="flex-row">
      <div>
        <h4>Game Goals</h4>
        <ul>
          <li
            v-for="{ description, completed } in panelSessionContent.gameGoals"
            :key="description"
            class="flex-row pushed-left"
          >
            <img v-if="completed" src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Checkbox_Checked.svg">
            <div
              v-else
              class="unchecked"
            >
              <div />
            </div>
            <p>{{ description }}</p>
          </li>
        </ul>
      </div>
      <div>
        <h4>Student Code</h4>
        <code-area
          :code="panelSessionContent.studentCode"
          :language="panelSessionContent.language"
        />
      </div>
    </div>
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
    align-items: flex-start;

    & > div:not(.unchecked) {
      flex: 1 1 0px;
      margin: 6px;
    }

    & > img {
      margin-top: 1px;
      margin-right: 2px;
    }

    .unchecked {
      margin: 2px 6px 0 0;

      & > div {
        height: 16px;
        width: 16px;
        border: 0.5px solid #d8d8d8;
        box-shadow: inset 0px 0px 2px rgba(0, 0, 0, 0.25);
      }
    }
  }

  ul {
    padding: 0;
    margin: 0;
  }

  p {
    @include font-p-4-paragraph-smallest-gray;
    line-height: 18px;
    color: #656565;

    margin-bottom: 9px;
  }

  .pushed-left {
    justify-content: flex-start;
  }

  a {
    @include font-p-3-paragraph-small-blue-link;
    text-decoration: underline;
  }

</style>
