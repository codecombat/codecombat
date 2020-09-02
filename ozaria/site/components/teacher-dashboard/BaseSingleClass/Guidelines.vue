<script>
  import ProgressLabels from '../common/progress/progressLabels'
  import ContentIcon from '../common/icons/ContentIcon'
  export default {
    components: {
      'progress-labels': ProgressLabels,
      ContentIcon
    },
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
      <progress-labels :show-review-labels="true" />
      <div class="title-card">
        <span style="width: 59px">Content Guide</span>
      </div>
      <div class="spacer">
        <div class="grid-container">
          <div class="story-title"><h3>Story</h3></div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Cutscene</h3><p>Short videos that explain parts of the epic Ozaria narrative.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext cutscene-icon vertical-grid-divider"
          >
            <content-icon icon="cutscene" />
            <span>Cutscenes</span>
          </div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Cinematic</h3><p>Expositional dialogue that introduces concepts in an engaging back-and-forth between characters.</p><p class='small'>Part of an <b>intro</b>, which introduce new concepts in a scaffolded way.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext cinematic-icon"
          >
            <content-icon
              icon="cinematic"
              style="width: 28px;"
            />
            <span>Cinematics</span>
          </div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Concept Check</h3><p>Formative checks for student understanding presented in varied formats, including drag-and-drop and code ordering questions.</p><p class='small'>Part of an <b>intro</b>, which introduce new concepts in a scaffolded way.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext concept-icon vertical-grid-divider"
          >
            <content-icon
              icon="interactive"
              style="width: 28px;"
            />
            <span>Concept Checks</span>
          </div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Practice Level</h3><p>Game-play in which students are practicing concepts while solving puzzles to complete their hero's quest.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext practice-icon"
          >
            <content-icon icon="practicelvl" />
            <span>Practice Levels</span>
          </div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Challenge Level</h3><p>Game-play that combines key concepts students have practiced previously.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext challenge-icon vertical-grid-divider"
          >
            <content-icon
              icon="challengelvl"
              style="width: 22px;"
            />
            <span>Challenge Levels</span>
          </div>
          <div
            v-tooltip.bottom="{
              content: `<h3>Capstone Level</h3><p>Students create games and stories using key concepts they learned from the chapter.</p>`,
              classes: 'teacher-dashboard-tooltip lighter-p'
            }"
            class="img-subtext capstone-icon"
          >
            <content-icon
              icon="capstone"
              style="width: 22px;"
            />
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
  min-width: 1260px;

  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;

  border-bottom: 0.5px solid #d8d8d8;

  position: relative;
  z-index: 11;
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
  max-width: 700px;

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

  cursor: pointer;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);

  &:hover {
    background: #eeeced;
    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 0px 4px 4px rgba(0, 0, 0, 0.25), inset 0px 5px 10px rgba(0, 0, 0, 0.15);
  }
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
