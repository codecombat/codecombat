<script>
  import ContentIcon from '../../common/icons/ContentIcon'

  export default {
    components: {
      ContentIcon
    },

    props: {
      iconType: {
        type: String,
        required: true,
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro'].indexOf(value) !== -1
      },

      displayName: {
        type: String,
        required: true
      }
    }
  }
</script>
<template>
  <div
    class="module-row"
  >
    <div
      v-tooltip.top="{
        content: $t('teacher_dashboard.intro_explain_tooltip'),
        classes: 'teacher-dashboard-tooltip lighter-p'
      }"
    >
      <content-icon
        class="content-icon"
        :icon="iconType"
      />
      <p class="content-heading">
        <b>Intro: {{ displayName }}</b>
      </p>
      <div />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .module-row {
    min-width: 30px;
    width: 100%;
    height: 100%;

    box-sizing: border-box;
    position: relative;

    & > div {
      display: flex;
      flex-direction: row;
      align-items: center;

      padding-top: 5px;
      padding-bottom: 5px;

      width:100%;
      height: 100%;
    }

    cursor: default;
  }

  .module-row::before {
    position: absolute;
    width: 8px;
    height: 100%;
    content: "";
    background-color: #9991B9;

  }

  .content-heading {
    /* Prevents wrapping of the title leading to strange spacing. */
    flex-shrink: 0;
  }

  .content-icon {
    margin: 0 15px;
  }

  p {
    @include font-p-3-paragraph-small-white;
    color: $pitch;
    font-size: 12px;
    line-height: 13px;
    text-align: left;

    margin-bottom: -3px;
    margin-right: 15px;
  }

  .content-icon {
    width: 18px;
    height: 18px;
  }
</style>
