<template>
  <div class="lprogress">
    <div
      v-if="product !== 'Ozaria'"
      class="lprogress__content"
    >
      <div class="lprogress__header">
        <div class="lprogress__intro">
          <div class="lprogress__intro__title">
            Levels progress
          </div>
          <div class="lprogress__intro__options">
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot not-started-dot"></div>
              <div class="lprogress__intro__text">Not Started</div>
            </div>
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot in-progress-dot"></div>
              <div class="lprogress__intro__text">In progress</div>
            </div>
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot complete-dot"></div>
              <div class="lprogress__intro__text">Complete</div>
            </div>
          </div>
        </div>
      </div>
      <div class="lprogress__module">
        <div class="lprogress__info">
          <div
            v-for="level in levels"
            class="lprogress__level"
            :key="level.original"
          >
            <module-row
              :display-name="level.name"
              :icon-type="getIconType(level)"
              :description="formatDescription(level.description)"
              :show-code-btn="getProgressStatus(level) !== 'not-started'"
              :show-progress-dot="true"
              :progress-status="getProgressStatus(level)"
              :identifier="level.slug"
              @showCodeClicked="onShowCodeClicked"
            />
            <code-diff
              v-if="showCodeModal.includes(level.slug)"
              :language="language"
              :code-right="solution[level.slug]"
              :code-left="code[level.slug]"
            />
          </div>
        </div>
        <div class="lprogress__resources">
          <module-resources
            :campaign="campaign"
          />
        </div>
      </div>
    </div>
    <div
      v-else
      class="lprogress__content"
    >
      <div class="lprogress__header">
        <div class="lprogress__intro">
          <div class="lprogress__intro__title">
            Levels progress
          </div>
          <div class="lprogress__intro__options">
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot not-started-dot"></div>
              <div class="lprogress__intro__text">Not Started</div>
            </div>
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot in-progress-dot"></div>
              <div class="lprogress__intro__text">In progress</div>
            </div>
            <div class="lprogress__intro__option">
              <div class="lprogress__intro__dot complete-dot"></div>
              <div class="lprogress__intro__text">Complete</div>
            </div>
          </div>
        </div>
      </div>
      <div
        v-for="num in moduleNumbers"
        class="lprogress__module"
        :key="num"
      >
        <div class="lprogress__info">
          <module-header
            :module-num="num"
            :module-name="getModuleName(num)"
            :is-capstone="false"
          />
          <template
            v-for="{ icon, name, _id, description, isPartOfIntro, isIntroHeadingRow, slug, fromIntroLevelOriginal } in getContentTypes(num)"
          >
            <intro-module-row
              v-if="isIntroHeadingRow"
              :key="_id"
              :icon-type="icon"
              :display-name="name"
              class="lprogress__level"
            />
            <module-row
              v-else
              :key="_id"
              :icon-type="icon"
              :display-name="name"
              :description="description"
              :is-part-of-intro="isPartOfIntro"
              :show-progress-dot="true"
              :show-code-btn="getProgressStatus({ slug, fromIntroLevelOriginal }) !== 'not-started' && !['cutscene', 'cinematic', 'interactive'].includes(icon)"
              :progress-status="getProgressStatus({ slug, fromIntroLevelOriginal })"
              :identifier="slug"
              @showCodeClicked="onShowCodeClicked"
              class="lprogress__level"
            />
            <code-diff
              v-if="showCodeModal.includes(slug)"
              :language="language"
              :code-right="solution[slug]"
              :code-left="code[slug]"
              :key="slug"
            />
          </template>
        </div>
        <div class="lprogress__resources">
          <module-resources
            :campaign="campaign"
            :lesson-slides-url="getLessonSlidesUrl(num)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
import ModuleHeader
  from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleHeader'
import IntroModuleRow
  from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/IntroModuleRow'
import CodeDiff from '../../../components/common/CodeDiff'
import { getProgressStatusHelper, getStudentAndSolutionCode } from '../helpers/levelCompletionHelper'
import { getCurriculumGuideContentList } from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper'
import ModuleResources from './ModuleResources'
const Level = require('../../../models/Level')
const ozariaCourseUtils = require('../../../core/ozaria-course-utils')
export default {
  name: 'ModuleProgressDataComponent',
  props: {
    levels: {
      type: Array,
      required: true
    },
    levelSessions: {
      type: Array
    },
    language: {
      type: String,
      default: 'javascript'
    },
    product: {
      type: String,
      default: 'CodeCombat'
    },
    ozCourseContent: {
      type: Object,
      default () {
        return {}
      }
    },
    campaign: {
      type: Object
    }
  },
  data () {
    return {
      showCodeModal: [],
      code: {},
      solution: {}
    }
  },
  components: {
    ModuleRow,
    CodeDiff,
    ModuleHeader,
    IntroModuleRow,
    ModuleResources
  },
  methods: {
    getIconType (level) {
      if (level.kind === 'practice' || level.practice) return 'practicelvl'
      return (['hero', 'hero-ladder', 'game-dev'].includes(level.type) ? 'challengelvl' : (level.type || 'challengelvl'))
    },
    getProgressStatus (level) {
      return getProgressStatusHelper(this.levelSessions, level)
    },
    onShowCodeClicked ({ identifier, hideCode = false }) {
      const levelSlug = identifier
      if (hideCode) {
        // this.showCodeModal.splice(this.showCodeModal.findIndex(slug => slug === levelSlug), 1)
        this.showCodeModal = this.showCodeModal.filter(s => s !== levelSlug)
        return
      }
      let level = this.levels.find(l => l.slug === levelSlug)
      if (this.product === 'Ozaria' && !level) {
        for (const num of this.moduleNumbers) {
          const module = this.ozCourseContent.modules[num]
          level = module.find(l => l.slug === levelSlug)
          if (level) break
        }
      }
      const { studentCode, solutionCode } = getStudentAndSolutionCode(level, this.levelSessions)
      this.code[levelSlug] = studentCode
      this.solution[levelSlug] = solutionCode
      this.showCodeModal.push(level.slug)
    },
    formatDescription (desc) {
      if (!desc) return ''
      const d = desc.replace(/!\[.*?\]\(.*?\)\n*/g, '')
      if (d.length > 60) {
        return this.truncate(d, 60, '...')
      }
      return d
    },
    truncate (str, max, suffix) {
      return str.length < max ? str : `${str.substr(0, str.substr(0, max - suffix.length).lastIndexOf(' '))}${suffix}`
    },
    isCapstoneModule (moduleNum) {
      return moduleNum === this.moduleNumbers[this.moduleNumbers.length - 1]
    },
    getModuleName (moduleNum) {
      return ozariaCourseUtils.courseModules[this.campaign._id][moduleNum]
    },
    getContentTypes (moduleNum) {
      return getCurriculumGuideContentList({
        introLevels: this.ozCourseContent.introLevels,
        moduleInfo: this.ozCourseContent.modules,
        moduleNum,
        currentCourseId: this.campaign._id,
        codeLanguage: this.language
      })
    },
    getLessonSlidesUrl (moduleNum) {
      return this.campaign.modules[moduleNum]?.lessonSlidesUrl
    }
  },
  computed: {
    moduleNumbers () {
      return Object.keys(this.ozCourseContent?.modules || {})
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.lprogress {
  padding: 2rem;
  &__intro {
    display: flex;
    align-items: center;

    &__title {
      font-weight: 500;
      font-size: 1.6rem;
      line-height: 2rem;
      text-transform: uppercase;

      margin-right: auto;
    }

    &__text {
      font-weight: 400;
      font-size: 1rem;
      line-height: 1.1rem;
    }

    &__options {
      display: flex;
    }

    &__option {
      display: flex;
      flex-direction: column;
      align-items: center;

      padding: 1rem;
    }

    &__dot {
      width: 1rem;
      height: 1rem;
      background: #FFFFFF;
      border-radius: 1rem;
      margin-bottom: .5rem;
    }
  }

  &__diff {
    padding: 1rem;
  }

  &__level {
    &:nth-child(odd) {
      background-color: $color-grey-2;
    }
    height: unset;
  }

  &__module {
    display: grid;
    grid-template-columns: 2.5fr 1fr;

    &:not(:last-child) {
      padding-bottom: 5rem;
    }
  }

  &__header {
    display: grid;
    grid-template-columns: 2.5fr 1fr;
  }
}

.not-started-dot {
  border: 1.5px solid $color-grey-3;
}

.in-progress-dot {
  background-color: #1ad0ff;
}

.complete-dot {
  background-color: #2dcd38;
}
</style>
