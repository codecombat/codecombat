<script>
  import ContentIcon from '../../common/icons/ContentIcon'
  export default {
    components: {
      ContentIcon
    }
  }
</script>
<template>
  <div class="module-row">
    <content-icon class="content-icon" :icon="['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl'][Math.floor(Math.random() * 6)]" />
    <p><b>Practice Level: Forest of the Fox</b></p>
    <p>Practice writing a code sequence including a method with arguments</p>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .module-row {
    min-width: 30px;

    display: flex;
    flex-direction: row;
    align-items: center;
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
</style>
