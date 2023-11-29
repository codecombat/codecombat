<script>
export default {
  props: {
    conceptCheck: {
      type: Object,
      required: true
    }
  }
}
</script>
<template>
  <div id="concept-check-info">
    <div class="row-icon">
      <img src="/images/ozaria/teachers/dashboard/svg_icons/IconLearningGoal.svg">
      <p>
        <b>{{ 'Learning Goal: ' }}</b>
        {{ conceptCheck.learningGoal }}
      </p>
    </div>
    <div
      v-if="conceptCheck.totalSubmissions !== -1"
      class="row-icon"
    >
      <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Submissions.svg">
      <p>
        <b>{{ 'Number of total submissions: ' }}</b>
        {{ conceptCheck.totalSubmissions }}
      </p>
    </div>
    <div
      v-if="conceptCheck.timeSpent !== -1"
      class="row-icon"
    >
      <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_TimeSpent.svg">
      <p>
        <b>{{ 'Time Spent: ' }}</b>
        {{ `${conceptCheck.timeSpent} min` }}
      </p>
    </div>
    <div
      v-if="conceptCheck.classAverage !== -1"
      class="row-icon"
    >
      <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_ClassAvg.svg">
      <p>
        <b>{{ 'Class Average: ' }}</b>
        {{ `${conceptCheck.classAverage} min` }}
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #concept-check-info {
    width: 100%;

    display: flex;
    flex-direction: column;

    justify-content: space-between;
    align-items: center;

    padding: 18px 20px;

    background-color: #f7fbff;

    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  }

  img {
    width: 25px;
    height: 25px;
  }

  .row-icon {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: flex-start;

    margin: 7px 0;

    width: 100%;
  }

  p {
    @include font-p-4-paragraph-smallest-gray;
    color: #545b64;
    margin: 0;
  }
</style>
