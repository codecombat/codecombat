<script>
  import CodeArea from './CodeArea'
  import utils from 'core/utils'

  export default {
    components: {
      CodeArea
    },

    props: {
      gameGoals: {
        type: Array,
        required: true
      },
      capstoneSessionCode: {
        type: String,
        required: true
      },
      capstoneSessionLanguage: {
        type: String,
        required: true
      }
    },
    created() {
      this.utils = utils
    }

  }
</script>

<template>
  <div class="flex-row">
    <div>
      <h4>{{ $t('concepts.game_goals') }}</h4>
      <ul>
        <li
          v-for="{ goal, completed } in gameGoals"
          :key="goal.name"
          class="flex-row pushed-left"
        >
          <img v-if="completed" src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Checkbox_Checked.svg">
          <div
            v-else
            class="unchecked"
          >
            <div />
          </div>
          <p>{{ utils.i18n(goal, 'name') }}</p>
        </li>
      </ul>
    </div>
    <div>
      <h4>{{ $t('concepts.student_code') }}</h4>
      <code-area
        :code="capstoneSessionCode"
        :language="capstoneSessionLanguage"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

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
      margin-right: 5px;
    }

    .unchecked {
      margin: 2px 10px 0 0;

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

    margin-bottom: 5px;
  }

  .pushed-left {
    justify-content: flex-start;
  }

</style>
