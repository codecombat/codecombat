<script>
  import ModuleHeader from './ModuleHeader'
  import ModuleRow from './ModuleRow'
  import IntroModuleRow from './IntroModuleRow'
  import { mapGetters } from 'vuex'
  import utils from 'core/utils'

  export default {
    components: {
      ModuleHeader,
      ModuleRow,
      IntroModuleRow
    },

    props: {
      moduleNum: {
        required: true,
        type: String
      },
      isCapstone: {
        type: Boolean,
        default: false
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
        const introLevels = this.getModuleIntroLevels
        const curriculumGuideContentList = []
        let lastIntroLevelSlug = null
        for (const content of this.getModuleInfo?.[this.moduleNum] || []) {
          const {
            type,
            ozariaType,
            introLevelSlug,
            fromIntroLevelOriginal,
            slug,
            introContent,
            _id
          } = content

          // Potentially this intro doesn't have a header in the curriculum guide yet
          if (introLevelSlug &&
            type !== 'cutscene' &&
            lastIntroLevelSlug !== introLevelSlug
          ) {
            curriculumGuideContentList.push({
              isIntroHeadingRow: true,
              name: utils.i18n(introLevels[fromIntroLevelOriginal], 'displayName'),
              icon: 'intro'
            })
            lastIntroLevelSlug = introLevelSlug
          }

          let icon, url

          // TODO: Where is the language chosen in the curriculum guide?
          if (!ozariaType) {
            icon = type
            url = `/play/intro/${introLevelSlug}?course=${this.getCurrentCourse._id}&codeLanguage=${this.getSelectedLanguage}&intro-content=${introContent || 0}`
          } else if (ozariaType) {
            if (ozariaType === 'practice') {
              icon = 'practicelvl'
            } else if (ozariaType === 'capstone') {
              icon = 'capstone'
            } else if (ozariaType === 'challenge') {
              icon = 'challengelvl'
            }
            url = `/play/level/${slug}?course=${this.getCurrentCourse._id}&codeLanguage=${this.getSelectedLanguage}`
          }

          if (!url || !icon) {
            console.error('missing url or icon in curriculum guide')
          }
          curriculumGuideContentList.push({
            icon,
            name: utils.i18n(content, 'displayName') || utils.i18n(content, 'name'),
            _id,
            description: this.getContentDescription(content),
            url,
            // Handle edge case that cutscenes are always in their own one to one intro
            isPartOfIntro: !!introLevelSlug && icon !== 'cutscene',
            isIntroHeadingRow: false
          })
        }

        return curriculumGuideContentList
      }
    },

    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
        }
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

    <div v-if="!isOnLockedCampaign" class="content-rows">
      <a
        v-for="{ icon, name, _id, url, description, isPartOfIntro, isIntroHeadingRow } in getContentTypes"
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
        v-for="{ icon, name, _id, description, isPartOfIntro, isIntroHeadingRow } in getContentTypes"
      >
        <intro-module-row
          v-if="isIntroHeadingRow"
          :key="_id"
          :icon-type="icon"
          :display-name="name"
        />
        <module-row

          :key="_id"
          :icon-type="icon"
          :display-name="name"
          :description="description"
          :is-part-of-intro="isPartOfIntro"
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
