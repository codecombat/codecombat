<script>
  import IconHelp from '../../common/icons/IconHelp'
  import ButtonPlayChapter from './ButtonPlayChapter'
  import ButtonSolutionGuide from './ButtonSolutionGuide'
  export default {
    components: {
      IconHelp,
      ButtonPlayChapter,
      ButtonSolutionGuide
    }
  }
</script>
<template>
  <div id="chapter-info">
    <div class="img-container">
      <img class="img-responsive" src="/images/ozaria/teachers/dashboard/png_img/TempChapter1PlaceholderArt.png">
    </div>
    <div class="info-container">
      <h3>Chapter 1: Sky Mountain</h3>
      <p class="chapter-summary">
        Students are introduced to the epic world of Ozaria and their mission:
        to defeat the impending darkness through different coding challenges.
        Students sample coding concepts like syntax etc.
      </p>
      <div class="stats-and-btns">
        <div>
          <p><b>Capstone Project</b>: Hungry Hungry Avatars</p>
          <div class="time-row"><p><b>Class Time</b>: 5 hours</p><icon-help /></div>
        </div>
        <div class="btns">
          <button-play-chapter />
          <button-solution-guide />
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #chapter-info {
    display: flex;
    flex-direction: row;

    background-color: #f2f2f2;

    .img-container {
      max-width: 256px;
      width: 100%;

      margin-right: 30px;

      display: flex;
      align-items: center;
    }

      .time-row {
    display: flex;
    flex-direction: row;

    & > img {
      margin-left: 9px;
    }
  }

    h3 {
      @include font-h-4-nav-uppercase-black;
      color: $pitch;
      text-align: left;

      margin: 18px 0 5px;
    }

    p {
      @include font-p-4-paragraph-smallest-gray;
      color: $pitch;
      font-size: 16px;
      line-height: 20px;
      font-style: normal;
      font-weight: normal;
    }

    .chapter-summary {
      margin-right: 60px;
    }
  }

  .info-container {
    display: flex;
    flex-direction: column;
  }

  .stats-and-btns {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;

    margin-bottom: 18px;
    margin-right: 60px;

    & > div {
      /* Ensure containers are evenly distributed */
      flex: 1 1 auto;
    }

    .btns {
      display: flex;
      justify-content: space-around;
    }

    p {
      margin-bottom: 5px;
    }
  }
</style>
