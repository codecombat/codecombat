<script>
  import ButtonSlides from './ButtonSlides'
  import ButtonProjectReq from './ButtonProjectReq'
  import ButtonExemplar from './ButtonExemplar'

  import IconHelp from '../../common/icons/IconHelp'

  export default {
    components: {
      ButtonSlides,
      ButtonProjectReq,
      ButtonExemplar,
      IconHelp
    }
  }
</script>
<template>
  <div class="header">
    <div class="module-header">
      <h3>Module 1: Algorithms and Syntax</h3>
      <div class="time-row"><p>Class Time: 1 hour</p><icon-help /></div>
    </div>
    <div class="buttons">
      <button-slides />
      <button-project-req />
      <button-exemplar />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .header {
    height: 60px;

    display: flex;
    flex-direction: row;
    align-items: center;

    border: 0.5px solid #d8d8d8;
    box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);

    padding: 0 15px;

    .module-header {
      flex: 1 1 auto;
    }
    .buttons {
      flex: 2 2 auto;
    }
  }

  .time-row {
    display: flex;
    flex-direction: row;

    & > img {
      margin-left: 9px;
    }
  }

  h3 {
    @include font-p-3-small-button-text-black;
    text-align: left;
    color: #333333;
    margin-bottom: 3px;
  }
  p {
    @include font-p-4-paragraph-smallest-gray;
    color: #131b25;
    margin-bottom: 0;
  }
</style>
