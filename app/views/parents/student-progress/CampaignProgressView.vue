<template>
  <div
    v-if="campaign"
    class="cprogress"
  >
    <div class="cprogress__header">
      <level-progress-info-component />
    </div>
    <div
      v-if="product === 'codecombat'"
      class="cprogress__coco"
    >
      <coco-module-progress-component
        :levels="sortedLevels"
        :code-language="codeLanguage"
        :lesson-slides-url="''"
        :level-sessions="levelSessions"
      />
    </div>
    <div
      v-else
      class="cprogress__oz"
    >
      <div
        v-for="num in moduleNumbers"
        :key="num"
        class="cprogress__module"
      >
        <oz-module-progress-component
          :module-num="num"
          :lesson-slides-url="lessonSlidesUrl(num)"
          :is-free-campaign="isFreelyAvailable"
          :module-name="moduleName(num)"
          :is-capstone="isCapstone(num)"
          :levels="getContentTypes(num)"
          :code-language="codeLanguage"
          :level-sessions="levelSessions"
          :module-levels="moduleLevels(num)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import CocoModuleProgressComponent from './CocoModuleProgressComponent'
import OzModuleProgressComponent from './OzModuleProgressComponent'
import LevelProgressInfoComponent from './LevelProgressInfoComponent'
import {
  getCurriculumGuideContentList
} from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper'
import { mapGetters } from 'vuex'
import utils from 'app/core/utils'
export default {
  name: 'CampaignProgressView',
  components: {
    CocoModuleProgressComponent,
    OzModuleProgressComponent,
    LevelProgressInfoComponent
  },
  props: {
    campaign: {
      type: Object
    },
    levelSessions: {
      type: Array
    },
    sortedLevels: {
      type: Array,
      default () {
        return []
      }
    },
    product: {
      type: String,
      default: 'codecombat'
    },
    ozCourseContent: {
      type: Object,
      default () {
        return {}
      }
    },
    codeLanguage: {
      type: String
    }
  },
  computed: {
    ...mapGetters({
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
    }),
    moduleNumbers () {
      // Wonder if something like this could also work:
      // return Object.keys(this.getCurrentCourse?.modules || {}).map(n => parseInt(n, 10))
      return Object.keys(this.ozCourseContent?.modules || {}).map(n => parseInt(n, 10))
    },
    isFreelyAvailable () {
      return this.campaign.free
    }
  },
  methods: {
    moduleName (num) {
      let moduleInfo = this.getCurrentCourse?.modules
      moduleInfo = moduleInfo || this.campaign.modules[num] // Fallback method. Do we need it?
      return utils.i18n(moduleInfo?.[num] || {}, 'name')
    },
    lessonSlidesUrl (num) {
      let moduleInfo = this.getCurrentCourse?.modules
      moduleInfo = moduleInfo || this.campaign.modules[num] // Fallback method. Do we need it?
      let lessonSlidesUrl = utils.i18n(moduleInfo?.[num] || {}, 'lessonSlidesUrl')
      if (typeof lessonSlidesUrl === 'object') {
        lessonSlidesUrl = lessonSlidesUrl[this.codeLanguage || 'javascript'] || lessonSlidesUrl.javascript
      }
      return lessonSlidesUrl
    },
    isCapstone (num) {
      return num === this.moduleNumbers[this.moduleNumbers.length - 1]
    },
    getContentTypes (moduleNum) {
      return getCurriculumGuideContentList({
        introLevels: this.ozCourseContent.introLevels,
        moduleInfo: this.ozCourseContent.modules,
        moduleNum,
        currentCourseId: this.campaign._id,
        codeLanguage: this.codeLanguage
      })
    },
    moduleLevels (num) {
      return this.ozCourseContent.modules[num]
    }
  }
}
</script>

<style scoped lang="scss">
.cprogress {
  padding: 1rem;

  &__header {
    display: grid;
    grid-template-columns: 2.5fr 1fr;
  }

  &__module {
    &:not(:last-child) {
      padding-bottom: 2rem;
    }
  }
}
</style>
