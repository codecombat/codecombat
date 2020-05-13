<script>
  export default {
    props: {
      visible: {
        type: Boolean,
        default: true
      }
    },
    methods: {
      clickArrow () {
        this.$emit('click-arrow')
      }
    }
  }
</script>

<template>
  <transition name="fade">
    <div class="guidelines-nav" v-show="visible">
      <div class="title-card">
        <span>Color Code</span>
      </div>
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
        <div class="img-subtext">
          <div class="dot-border concept-flag-border"><div class="dot green-dot"></div></div>
          <span>Concept Flag</span>
        </div>
        <div class="img-subtext">
          <div class="dot-border time-flag-border"><div class="dot green-dot"></div></div>
          <span>Time Spent Flag</span>
        </div>
        <div>
          <div class="question-mark">
            <span>?</span>
          </div>
        </div>
      </div>
      <div class="title-card">
        <span style="width: 59px">Content Guide</span>
      </div>
      <div class="spacer">
        <div class="grid-container">
          <div class="story-title"><h3>Story</h3></div>
          <div class="img-subtext cutscene-icon vertical-grid-divider">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCutscene.svg">
            <span>Cutscenes</span>
          </div>
          <div class="img-subtext cinematic-icon">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCinematic.svg">
            <span>Cinematics</span>
          </div>
          <div class="img-subtext concept-icon vertical-grid-divider">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconInteractive.svg">
            <span>Concept Checks</span>
          </div>
          <div class="img-subtext practice-icon">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconPracticeLevel.svg">
            <span>Practice Levels</span>
          </div>
          <div class="img-subtext challenge-icon vertical-grid-divider">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconChallengeLevel.svg">
            <span>Challenge Levels</span>
          </div>
          <div class="img-subtext capstone-icon">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCapstoneLevel.svg">
            <span>Capstone Levels</span>
          </div>
          <div class="intro-title"><h3>Intro</h3></div>
          <div class="practice-title"><h3>Practice</h3></div>
          <div class="assess-title"><h3>Assess</h3></div>
        </div>
      </div>
      <div class="arrow-toggle" @click="clickArrow"><div class="arrow-icon"></div></div>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.guidelines-nav {
  height: 71px;
  max-height: 71px;

  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;

  border-bottom: 0.5px solid #d8d8d8;
}

.story-title {
  grid-area: story-title;
  align-self: end;
}
.intro-title {
  grid-area: intro-title;
  align-self: end;
}
.practice-title {
  grid-area: practice-title;
  align-self: end;
}
.assess-title {
  grid-area: assess-title;
  align-self: end;
}
.cutscene-icon {
  grid-area: cutscene-icon;
}
.cinematic-icon {
  grid-area: cinematic-icon;
}
.concept-icon {
  grid-area: concept-icon;
}
.practice-icon {
  grid-area: practice-icon;
}
.challenge-icon {
  grid-area: challenge-icon;
}
.capstone-icon {
  grid-area: capstone-icon;
}

.vertical-grid-divider {
  position: relative;
}

.vertical-grid-divider:after {
  content: "";
  position: absolute;
  border-left: 0.5px solid #476FB1;
  top: -17%;
  bottom: 28%;
  left: 101%;
}

.grid-container {
  width: 100%;

  display: grid;
  grid-template-rows: 22px 47px;
  grid-template-columns: auto;
  grid-template-areas:
    "story-title intro-title intro-title practice-title practice-title assess-title"
    "cutscene-icon cinematic-icon concept-icon practice-icon challenge-icon capstone-icon";

  h3 {
    @include font-p-1-paragraph-large-twilight;
    font-size: 12px;
    line-height: 16px;
    font-weight: 600;
    text-align: center;
  }
}

.title-card {
  width: 100px;
  height: 100%;

  display: flex;
  flex-direction: column;

  justify-content: center;
  align-items: center;

  @include font-p-4-paragraph-smallest-gray;
  font-weight: 600;
  color: black;

  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
}

.img-subtext {
  width: 100%;
  height: 100%;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  img {
    width: 24px;
    height: 24px;
  }

  @include font-p-4-paragraph-smallest-gray;
  font-size: 10px;
  line-height: 11px;
  text-align: center;
}

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

.arrow-icon {
  border: 3px solid #476FB1;
  box-sizing: border-box;
  border-bottom: unset;
  border-right: unset;
  transform: rotate(45deg);
  width: 9px;
  height: 9px;
}

.arrow-toggle {
  width: 62px;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);

  &:hover {
    background: #eeeced;
    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 0px 4px 4px rgba(0, 0, 0, 0.25), inset 0px 5px 10px rgba(0, 0, 0, 0.15);
  }
}

.dot-border {
  width: 22px;
  height: 22px;

  display: flex;
  justify-content: center;
  align-items: center;

  border-radius: 3px;
}

.concept-flag-border {
  border: 1px solid #eb003b;
}

.time-flag-border {
  border: 1px solid #828282;
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

.fade-leave-active {
  // Staggers opacity with height staggered.
  transition: opacity .4s, max-height .3s 0.1s;
}

.fade-enter-active {
  // feels better to start with height and then do opacity when opening drawer.
  transition: max-height .4s, opacity .3s 0.15s;
}

.fade-leave-to {
  opacity: 0;
  max-height: 0px;
}

.fade-enter {
  opacity: 0;
  max-height: 0px;
}

.fade-enter-to {
  opacity: 1;
  max-height: 71px;
}
</style>
