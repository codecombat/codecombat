<script>
import ProgressLabels from '../common/progress/progressLabels'
import ContentGuideItem from './ContentGuideItem'
import { mapGetters } from 'vuex'
import utils from 'core/utils'

const ozariaContentGuideItems = [
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.story'),
    classes: 'story-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.cutscenes_tooltip'),
    classes: 'cutscene-icon vertical-grid-divider',
    icon: 'cutscene',
    iconStyle: '',
    text: $.i18n.t('teacher_dashboard.cutscenes'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.cinematics_tooltip'),
    classes: 'cinematic-icon',
    icon: 'cinematic',
    iconStyle: 'width: 28px;',
    text: $.i18n.t('teacher_dashboard.cinematics'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.concepts_tooltip'),
    classes: 'concept-icon vertical-grid-divider',
    icon: 'interactive',
    iconStyle: 'width: 28px;',
    text: $.i18n.t('teacher_dashboard.concept_checks'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.ozaria_practices_tooltip'),
    classes: 'practice-icon',
    icon: 'practicelvl',
    iconStyle: '',
    text: $.i18n.t('teacher_dashboard.practice_levels'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.challenges_tooltip'),
    classes: 'challenge-icon vertical-grid-divider',
    icon: 'challengelvl',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.challenge_levels'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.capstones_tooltip'),
    classes: 'capstone-icon',
    icon: 'capstone',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.capstone_levels'),
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.intro'),
    classes: 'intro-title',
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.practice'),
    classes: 'practice-title',
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.assess'),
    classes: 'assess-title',
  },
]

const cocoContentGuideItems = [
  {
    tooltip: $.i18n.t('teacher_dashboard.coco_practices_tooltip'),
    classes: 'practice-icon vertical-grid-divider',
    icon: 'practicelvl',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.practice_levels'),
  },

  {
    tooltip: $.i18n.t('teacher_dashboard.mains_tooltip'),
    classes: 'challenge-icon vertical-grid-divider',
    icon: 'challengelvl',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.main_levels'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.multiplayers_tooltip'),
    classes: 'intro-icon vertical-grid-divider',
    icon: 'intro',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.multiplayer_levels'),
  },

  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.main'),
    classes: 'main-title',
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.multiplayer'),
    classes: 'multiplayer-title',
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.practice'),
    classes: 'practice-title',
  },
]

const hackstackContentGuideItems = [
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.type'),
    classes: 'type-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.learn_to_use_tooltip'),
    classes: 'learn-icon',
    icon: 'ai-learn',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.learn_levels'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.use_tooltip'),
    classes: 'use-icon',
    icon: 'ai-use',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.use_levels'),
  },
]

const gameDevContentGuideItems = [
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.main'),
    classes: 'main-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.mains_tooltip'),
    classes: 'challenge-icon vertical-grid-divider',
    icon: 'intro',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.main_levels'),
  },

  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.assess'),
    classes: 'assess-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.capstones_tooltip'),
    classes: 'capstone-icon',
    icon: 'capstone',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.capstone_levels'),
  },
]
const webDevContentGuideItems = [
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.main'),
    classes: 'main-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.mains_tooltip'),
    classes: 'intro-icon vertical-grid-divider',
    icon: 'intro',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.main_levels'),
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.mains_tooltip'),
    classes: 'challenge-icon',
    icon: 'challengelvl',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.main_levels'),
  },
  {
    isTitle: true,
    title: $.i18n.t('teacher_dashboard.assess'),
    classes: 'assess-title',
  },
  {
    tooltip: $.i18n.t('teacher_dashboard.capstones_tooltip'),
    classes: 'capstone-icon',
    icon: 'capstone',
    iconStyle: 'width: 22px;',
    text: $.i18n.t('teacher_dashboard.capstone_levels'),
  },
]

export default {
  components: {
    'progress-labels': ProgressLabels,
    ContentGuideItem,
  },
  props: {
    visible: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ...mapGetters({
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
    }),
    showContentGuide () {
      return this.guideContainer?.items?.length
    },
    guideContainer () {
      if (utils.isOzaria) {
        return {
          classes: 'ozaria-container',
          items: ozariaContentGuideItems,
        }
      } else {
        if (!this.selectedCourseId) {
          return {
            items: [],
          }
        }
        if (utils.OZ_COURSE_IDS.includes(this.selectedCourseId)) {
          return {
            classes: 'ozaria-container',
            items: ozariaContentGuideItems,
          }
        } else if (utils.HACKSTACK_COURSE_IDS.includes(this.selectedCourseId)) {
          return {
            classes: 'hackstack-container',
            items: hackstackContentGuideItems,
          }
        } else if (utils.GD_COURSE_IDS.includes(this.selectedCourseId)) {
          return {
            classes: 'game-dev-container',
            items: gameDevContentGuideItems,
          }
        } else if (utils.WD_COURSE_IDS.includes(this.selectedCourseId)) {
          return {
            classes: 'web-dev-container',
            items: webDevContentGuideItems,
          }
        } else {
          return {
            classes: 'coco-container',
            items: cocoContentGuideItems,
          }
        }
      }
    },
  },
  methods: {
    clickArrow () {
      this.$emit('click-arrow')
    },
  },
}
</script>

<template>
  <transition name="fade">
    <div
      v-show="visible"
      class="guidelines-nav"
    >
      <div class="title-card">
        <span>{{ $t('teacher_dashboard.color_code') }}</span>
      </div>
      <progress-labels :show-review-labels="true" />
      <div
        v-if="showContentGuide"
        class="title-card"
      >
        <span style="width: 59px">{{ $t('teacher_dashboard.content_guide') }}</span>
      </div>
      <div class="spacer">
        <div
          v-if="showContentGuide"
          class="grid-container"
          :class="guideContainer.classes"
        >
          <ContentGuideItem
            v-for="(item, index) in guideContainer.items"
            :key="`content-guide-items-${index}`"
            :item="item"
          />
        </div>
      </div>
      <div
        class="arrow-toggle"
        @click="clickArrow"
      >
        <div class="arrow-icon" />
      </div>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.guidelines-nav {
  height: 60px;
  max-height: 60px;
  min-width: 1200px;

  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;

  border-bottom: 0.5px solid #d8d8d8;

  position: relative;
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
  max-height: 60px;
}

.grid-container {
  width: 100%;
  max-width: 700px;

  display: grid;
  grid-template-columns: auto;
  grid-template-rows: 22px 47px;

    &.ozaria-container {
      grid-template-areas:
        "story-title intro-title intro-title practice-title practice-title assess-title"
        "cutscene-icon cinematic-icon concept-icon practice-icon challenge-icon capstone-icon";
    }
    &.coco-container {
      grid-template-areas:
        "main-title practice-title multiplayer-title"
        "challenge-icon practice-icon intro-icon";
    }
    &.game-dev-container {
      grid-template-areas:
        "main-title assess-title"
        "challenge-icon capstone-icon";
    }
    &.web-dev-container {
      grid-template-areas:
        "main-title main-title assess-title"
        "challenge-icon intro-icon capstone-icon";
    }

    &.hackstack-container {
      grid-template-areas:
        "type-title type-title"
        "learn-icon use-icon";
    }

  ::v-deep {
    h3 {
      @include font-p-1-paragraph-large-twilight;
      font-size: 12px;
      line-height: 16px;
      font-weight: 600;
      text-align: center;
    }

    .type-title {
      grid-area: type-title;
      align-self: end;
    }
    .main-title {
      grid-area: main-title;
      align-self: end;
    }

    .multiplayer-title {
      grid-area: multiplayer-title;
      align-self: end;
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
    .learn-icon {
      grid-area: learn-icon;
    }
    .use-icon {
      grid-area: use-icon;
    }
    .intro-icon {
      grid-area: intro-icon;
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
  }
}
</style>
