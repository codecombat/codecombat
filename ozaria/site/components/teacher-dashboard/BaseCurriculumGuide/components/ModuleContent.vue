<script>
import Classroom from 'models/Classroom'

import ModuleHeader from './ModuleHeader'
import ModuleRow from './ModuleRow'
import IntroModuleRow from './IntroModuleRow'
import { mapGetters, mapActions } from 'vuex'
import CodeDiff from '../../../../../../app/components/common/CodeDiff'
import { getSolutionCode, getSampleCode } from '../../../../../../app/views/parents/helpers/levelCompletionHelper'
import { getCurriculumGuideContentList, isOzariaNoCodeLevelHelper } from '../curriculum-guide-helper'

export default {
  components: {
    ModuleHeader,
    ModuleRow,
    IntroModuleRow,
    CodeDiff,
  },

  props: {
    moduleNum: {
      required: true,
      type: String,
    },
    isCapstone: {
      type: Boolean,
      default: false,
    },
    levelSessions: {
      type: Array,
      default () {
        return []
      },
      required: false,
    },
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
      classroomId: 'teacherDashboard/classroomId',
      getLevelNumber: 'gameContent/getLevelNumber',
      levelNumberMap: 'gameContent/levelNumberMap',
      getCurrentModuleHeadingInfo: 'baseCurriculumGuide/getCurrentModuleHeadingInfo',
      isContentAccessible: 'me/isContentAccessible',
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

    isHackstack () {
      return this.courseName === 'AI HackStack'
    },

    getContentTypes () {
      return getCurriculumGuideContentList({
        introLevels: this.getModuleIntroLevels,
        moduleInfo: this.getModuleInfo,
        moduleNum: this.moduleNum,
        currentCourseId: this.getCurrentCourse._id,
        codeLanguage: this.getSelectedLanguage,
      })
    },

    courseRegex () {
      return new RegExp(`^${this.getCurrentCourse?._id}:`)
    },
  },
  watch: {
    getSelectedLanguage () {
      for (const slug in this.solutionCodeByLevel) {
        this.solutionCodeByLevel[slug] = getSolutionCode(this.findLevelBySlug(slug), { lang: this.getSelectedLanguage }) || ''
        this.sampleCodeByLevel[slug] = getSampleCode(this.findLevelBySlug(slug), { lang: this.getSelectedLanguage }) || ''
      }
    },
  },

  async created () {
    await this.generateLevelNumberMap({
      campaignId: this.getCurrentCourse.campaignID,
      language: this.getSelectedLanguage,
    })
  },

  methods: {
    ...mapActions({
      generateLevelNumberMap: 'gameContent/generateLevelNumberMap',
    }),
    findLevelBySlug (slug) {
      return this.getModuleInfo[this.moduleNum].find(l => l.slug === slug)
    },
    findRelatedOriginalsByLevelNumber (levelNumber, levelNumberMap) {
      const regex = new RegExp(`^${levelNumber}[a-z]?$`)
      if (!levelNumberMap) {
        return []
      }
      const levelEntries = Object.entries(levelNumberMap)
      const levelOriginals = levelEntries.filter(([key, value]) => regex.test(value.toString()))
      return levelOriginals.map(([key, _v]) => key)
    },
    relatedLevels (levelNumber, slug) {
      if (!/^[0-9]/.test(levelNumber) || !this.isJunior) {
        return [this.findLevelBySlug(slug)]
      }
      const levelNumberMap = this.levelNumberMap
      const levelOriginals = this.findRelatedOriginalsByLevelNumber(levelNumber, levelNumberMap)
      return levelOriginals.map((key) => {
        const levelKey = key.split(':')?.[1] || key
        return this.getModuleInfo[this.moduleNum].find(l => l.original === levelKey)
      })
    },
    trackEvent (eventName) {
      if (eventName) {
        window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
      }
    },
    onShowCodeClicked ({ identifier, levelNumber, hideCode = false }) {
      event.stopPropagation()
      event.preventDefault()
      const relatedLevels = this.relatedLevels(levelNumber, identifier)
      for (const relatedLevel of relatedLevels) {
        const slug = relatedLevel.slug
        if (hideCode) {
          this.showCodeLevelSlugs = _.without(this.showCodeLevelSlugs, slug)
          continue
        }
        this.showCodeLevelSlugs = this.showCodeLevelSlugs.concat([slug])
        this.solutionCodeByLevel[slug] = getSolutionCode(relatedLevel, { lang: this.getSelectedLanguage }) || ''
        this.sampleCodeByLevel[slug] = getSampleCode(relatedLevel, { lang: this.getSelectedLanguage }) || ''
      }
    },
    onClickedCodeDiff (event) {
      // Stop it from triggering its parent <a> to start the level
      event.stopPropagation()
      event.preventDefault()
    },
    calculateLevelDescription (description, slug, levelNumber) {
      const relatedLevels = this.relatedLevels(levelNumber, slug)
      const practiceNumber = relatedLevels.length - 1
      if (!this.isJunior || practiceNumber <= 0) {
        return description
      }
      return `${description}. ${$.i18n.t('teacher_dashboard.practice_levels')}: ${practiceNumber}`
    },
    isOzariaNoCodeLevel (icon) {
      return isOzariaNoCodeLevelHelper(icon)
    },
    isAccessible (moduleNum) {
      if (this.isOnLockedCampaign) {
        return false
      }
      const moduleInfo = this.getCurrentModuleHeadingInfo(moduleNum)
      return this.isContentAccessible(moduleInfo.access)
    },
    getCurrentLevelNumber (original, icon, _id) {
      if (this.isHackstack) {
        return ''
      }
      if (this.isOzariaNoCodeLevel(icon)) {
        return this.getLevelNumber(_id)
      }
      return this.getLevelNumber(original)
    },
  },
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
      <component
        :is="isAccessible(moduleNum)? 'a' : 'span'"
        v-for="{ icon, name, _id, url, description, isPartOfIntro, isIntroHeadingRow, original, assessment, slug, fromIntroLevelOriginal, tool }, key in getContentTypes"
        :key="`${_id}-${isIntroHeadingRow}`"
        :href="isAccessible(moduleNum) ? url : null"
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
            :set="levelNumber = getCurrentLevelNumber(original, icon, _id)"
            :icon-type="icon"
            :name-type="assessment ? null : icon"
            :level-number="levelNumber"
            :display-name="name"
            :description="calculateLevelDescription(description, slug, levelNumber)"
            :is-part-of-intro="isPartOfIntro"
            :show-code-btn="!isOzariaNoCodeLevel(icon) && !(isJunior && icon === 'practicelvl') && !isHackstack"
            :identifier="slug"
            :locked="!isAccessible(moduleNum)"
            :tool="tool"
            @click.native="trackEvent('Curriculum Guide: Individual content row clicked')"
            @showCodeClicked="onShowCodeClicked"
          />
        </template>
        <code-diff
          v-if="showCodeLevelSlugs.includes(slug)"
          :key="slug"
          :language="getSelectedLanguage"
          :code-right="solutionCodeByLevel[slug]"
          :code-left="sampleCodeByLevel[slug]"
          @click.native="onClickedCodeDiff"
        />
      </component>
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
