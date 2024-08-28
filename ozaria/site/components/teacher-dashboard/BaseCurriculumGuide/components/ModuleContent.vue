<script>
import Classroom from 'models/Classroom'
import utils from 'core/utils'

import ModuleHeader from './ModuleHeader'
import ModuleRow from './ModuleRow'
import IntroModuleRow from './IntroModuleRow'
import { mapGetters } from 'vuex'
import CodeDiff from '../../../../../../app/components/common/CodeDiff'
import { getSolutionCode, getSampleCode } from '../../../../../../app/views/parents/helpers/levelCompletionHelper'
import { getCurriculumGuideContentList } from '../curriculum-guide-helper'

export default {
  components: {
    ModuleHeader,
    ModuleRow,
    IntroModuleRow,
    CodeDiff
  },

  props: {
    moduleNum: {
      required: true,
      type: String
    },
    isCapstone: {
      type: Boolean,
      default: false
    },
    levelSessions: {
      type: Array,
      default () {
        return []
      },
      required: false
    },
    language: {
      type: String,
      default: 'javascript'
    }
  },
  data () {
    return {
      showCodeLevelSlugs: [],
      solutionCodeByLevel: {},
      sampleCodeByLevel: {},
    }
  },

  computed: {
    ...mapGetters({
      getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
      getModuleIntroLevels: 'baseCurriculumGuide/getModuleIntroLevels',
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
      getContentDescription: 'baseCurriculumGuide/getContentDescription',
      getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
      isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign',
      getTrackCategory: 'teacherDashboard/getTrackCategory',
      classroom: 'teacherDashboard/classroom',
      classroomId: 'teacherDashboard/classroomId'
    }),

    classroomInstance () {
      const classroom = new Classroom(this.classroom)
      return classroom
    },

    courseName () {
      return this.getCurrentCourse?.name || ''
    },

    isJunior () {
      return this.courseName === 'Junior'
    },

    getContentTypes () {
      return getCurriculumGuideContentList({
        introLevels: this.getModuleIntroLevels,
        moduleInfo: this.getModuleInfo,
        moduleNum: this.moduleNum,
        currentCourseId: this.getCurrentCourse._id,
        codeLanguage: this.getSelectedLanguage
      })
    },

    levelNumberMap () {
      const levels = this.getContentTypes
        .map(({ original, assessment, icon, fromIntroLevelOriginal }) => ({ original, key: (original || fromIntroLevelOriginal), assessment, practice: icon === 'practicelvl' }))
      return utils.createLevelNumberMap(levels)
    },
  },

  methods: {
    relatedLevels (level) {
      const levelNumber = this.getLevelNumber(level.original)
      const regex = new RegExp(`^${levelNumber}[a-z]?$`)
      const levelOriginals = Object.entries(this.levelNumberMap).filter(([_k, value]) => regex.test(value.toString()))
      return levelOriginals.map(([key, _v]) => this.getModuleInfo[this.moduleNum].find(l => l.original === key))
    },
    getLevelNumber (original, index) {
      if (utils.isCodeCombat && this.classroomId) {
        const levelNumber = this.classroomInstance.getLevelNumber(original, index, this.getCurrentCourse?._id)
        return levelNumber
      } else {
        const map = this.levelNumberMap
        return map[original] || index
      }
    },
    trackEvent (eventName) {
      if (eventName) {
        window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
      }
    },
    onShowCodeClicked ({ identifier, hideCode = false }) {
      event.stopPropagation()
      event.preventDefault()
      const level = this.getModuleInfo?.[this.moduleNum].find(l => l.slug === identifier)
      const relatedLevels = this.relatedLevels(level)
      for (const relatedLevel of relatedLevels) {
        const identifier = relatedLevel.slug
        if (hideCode) {
          this.showCodeLevelSlugs = _.without(this.showCodeLevelSlugs, identifier)
          continue
        }
        this.showCodeLevelSlugs = this.showCodeLevelSlugs.concat([identifier])
        this.solutionCodeByLevel[identifier] = getSolutionCode(level, { lang: this.getSelectedLanguage }) || ''
        this.sampleCodeByLevel[identifier] = getSampleCode(level, { lang: this.getSelectedLanguage }) || ''
      }
    },
    onClickedCodeDiff (event) {
      // Stop it from triggering its parent <a> to start the level
      event.stopPropagation()
      event.preventDefault()
    },
    calculateLevelDescription (description, slug) {
      const level = this.getModuleInfo?.[this.moduleNum].find(l => l.slug === slug)
      const relatedLevels = this.relatedLevels(level)
      const practiceNumber = relatedLevels.length - 1
      if (!this.isJunior || practiceNumber === 0) {
        return description
      }
      return `${description}. ${$.i18n.t('teacher_dashboard.practice_levels')}: ${practiceNumber}`
    }
  }
}
</script>
<template>
  <div>
    <module-header
      :module-num="moduleNum"
      :course-name="courseName"
      :is-capstone="isCapstone"
    />

    <div class="content-rows">
      <a
        v-for="{ icon, name, _id, url, description, isPartOfIntro, isIntroHeadingRow, original, assessment, slug, fromIntroLevelOriginal }, key in getContentTypes"
        :key="_id"
        :href="isOnLockedCampaign ? '#' : url"
        target="_blank"
        rel="noreferrer"
      >
        <intro-module-row
          v-if="isIntroHeadingRow"
          :icon-type="icon"
          :display-name="name"
        />
        <template v-else>
          <module-row
            v-if="!isJunior || icon !== 'practicelvl' || showCodeLevelSlugs.includes(slug)"
            :icon-type="icon"
            :name-type="assessment ? null : icon"
            :level-number="getLevelNumber(original, key + 1 )"
            :display-name="name"
            :description="calculateLevelDescription(description, slug)"
            :is-part-of-intro="isPartOfIntro"
            :show-code-btn="icon !== 'cutscene' && !(isJunior && icon === 'practicelvl')"
            :identifier="slug"
            @click.native="trackEvent('Curriculum Guide: Individual content row clicked')"
            @showCodeClicked="onShowCodeClicked"
          />
        </template>
        <code-diff
          v-if="showCodeLevelSlugs.includes(slug)"
          :key="slug"
          :language="language"
          :code-right="solutionCodeByLevel[slug]"
          :code-left="sampleCodeByLevel[slug]"
          @click.native="onClickedCodeDiff"
        />
      </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.content-rows {
  background-color: white;
  box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.12);

  margin-bottom: 29px;

  // Supports both locked and unlocked views.
  & a:nth-child(odd), & > div:nth-child(odd) {
    background-color: #f2f2f2;
  }

  a {
    display: block;
    text-decoration: none;
  }
}
</style>
