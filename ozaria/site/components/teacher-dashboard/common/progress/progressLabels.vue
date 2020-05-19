<script>
  export default {
    props: {
      showReviewLabels: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <div class="spacer">
    <div class="img-subtext">
      <div class="dot-border"><div class="dot green-dot"></div></div>
      <span>Complete</span>
    </div>
    <div class="img-subtext">
      <div class="dot-border"><div class="dot teal-dot"></div></div>
      <span>In Progress</span>
    </div>
    <div class="img-subtext">
      <div class="dot-border"><div class="dot assigned-dot"></div></div>
      <span>Assigned</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <div class="dot-border concept-flag-border"><div class="dot green-dot"></div></div>
      <span>Concept Flag</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <div class="dot-border time-flag-border"><div class="dot green-dot"></div></div>
      <span>Time Spent Flag</span>
    </div>
    <div v-if="showReviewLabels">
      <div class="question-mark">
        <span>?</span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.spacer {
  // ensure spacers are equal size
  flex: 1 1 0px;

  display: flex;
  flex-direction: row;
  justify-content: center;

  & > div:not(.grid-container) {
    width: 58px;
    margin: 0 10px;
  }
}

.img-subtext {
  width: 100%;
  height: 100%;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  @include font-p-4-paragraph-smallest-gray;
  font-size: 10px;
  line-height: 11px;
  text-align: center;
}

.dot-border {
  width: 22px;
  height: 22px;

  display: flex;
  justify-content: center;
  align-items: center;

  border-radius: 3px;
}

.dot {
  width: 16px;
  height: 16px;
  border-radius: 8px;
}

.green-dot {
  background-color: #2dcd38;
}

.teal-dot {
  background-color: #1ad0ff;
}

.assigned-dot {
  border: 1.5px solid #c8cdcc;
}

.question-mark {
  width: 18px;
  height: 18px;
  border-radius: 9px;
  background-color: #476fb1;

  display: flex;
  justify-content: center;
  align-items: center;
  text-align: center;

  @include font-p-4-paragraph-smallest-gray;
  font-weight: bold;
  line-height: 14px;
  color: $moon;
}

.concept-flag-border {
  border: 1px solid #eb003b;
}

.time-flag-border {
  border: 1px solid #828282;
}
</style>
