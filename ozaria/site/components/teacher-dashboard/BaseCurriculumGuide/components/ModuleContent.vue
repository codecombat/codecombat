<script>
  import ModuleHeader from './ModuleHeader'
  import ModuleRow from './ModuleRow'
  import IntroModuleRow from './IntroModuleRow'
  import { mapGetters } from 'vuex'
  import CodeDiff from '../../../../../../app/components/common/CodeDiff'
  import { getProgressStatusHelper, getStudentAndSolutionCode } from '../../../../../../app/views/parents/helpers/levelCompletionHelper'
  import { getCurriculumGuideContentList } from '../curriculum-guide-helper'

  export default {
    data () {
      return {
        showCodeLevelSlug: null,
        solutionCode: null,
        studentCode: null
      }
    },
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
      showProgressDot: {
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

    computed: {
      ...mapGetters({
        getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
        getModuleIntroLevels: 'baseCurriculumGuide/getModuleIntroLevels',
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getContentDescription: 'baseCurriculumGuide/getContentDescription',
        getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign',
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      }),

      courseName () {
        return this.getCurrentCourse?.name || ''
      },

      getContentTypes () {
        return getCurriculumGuideContentList({
          introLevels: this.getModuleIntroLevels,
          moduleInfo: this.getModuleInfo,
          moduleNum: this.moduleNum,
          currentCourseId: this.getCurrentCourse._id,
          codeLanguage: this.getSelectedLanguage
        })
      }
    },

    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
        }
      },
      getProgressStatus ({ slug, fromIntroLevelOriginal }) {
        if (!this.showProgressDot) return
        return getProgressStatusHelper(this.levelSessions, { slug, fromIntroLevelOriginal })
      },
      onShowCodeClicked ({ identifier, hideCode = false }) {
        const level = this.getModuleInfo?.[this.moduleNum].find(l => l.slug === identifier)
        if (hideCode) {
          this.showCodeLevelSlug = null
          return
        }
        this.showCodeLevelSlug = identifier
        const { solutionCode, studentCode } = getStudentAndSolutionCode(level, this.levelSessions)
        this.studentCode = studentCode
        this.solutionCode = solutionCode
        console.log('l', level, this.levelSessions, identifier, this.getModuleInfo?.[this.moduleNum])
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

    <div v-if="!isOnLockedCampaign && !showProgressDot" class="content-rows">
      <a
        v-for="{ icon, name, _id, url, description, isPartOfIntro, isIntroHeadingRow, slug, fromIntroLevelOriginal } in getContentTypes"
        :key="_id"
        :href="url"
        target="_blank"
        rel="noreferrer"
      >
        <intro-module-row
          v-if="isIntroHeadingRow"
          :icon-type="icon"
          :display-name="name"
        />
        <module-row
          v-else
          :icon-type="icon"
          :display-name="name"
          :description="description"
          :is-part-of-intro="isPartOfIntro"
          @click.native="trackEvent('Curriculum Guide: Individual content row clicked')"
        />
      </a>
    </div>
    <!-- If curriculum guide is locked -->
    <div
      v-else
      class="content-rows"
    >
      <template
        v-for="{ icon, name, _id, description, isPartOfIntro, isIntroHeadingRow, slug, fromIntroLevelOriginal } in getContentTypes"
      >
        <intro-module-row
          v-if="isIntroHeadingRow"
          :key="_id"
          :icon-type="icon"
          :display-name="name"
        />
        <module-row
          v-else
          :key="_id"
          :icon-type="icon"
          :display-name="name"
          :description="description"
          :is-part-of-intro="isPartOfIntro"
          :show-progress-dot="showProgressDot"
          :show-code-btn="getProgressStatus({ slug, fromIntroLevelOriginal }) !== 'not-started' && icon !== 'cutscene'"
          :progress-status="getProgressStatus({ slug, fromIntroLevelOriginal })"
          :identifier="slug"
          @showCodeClicked="onShowCodeClicked"
        />
        <code-diff
          v-if="showCodeLevelSlug === slug"
          :language="language"
          :code-right="solutionCode"
          :code-left="studentCode"
          :key="slug"
        />
      </template>
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
