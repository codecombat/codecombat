<script>
import { mapState, mapActions, mapGetters, mapMutations } from 'vuex'

import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
import utils from 'core/utils'

import ChapterNav from './components/ChapterNav'
import ChapterInfo from './components/ChapterInfo'
import ChapterContent from './components/ChapterContent'
import HeaderComponent from './components/HeaderComponent'

export default {
  name: COMPONENT_NAMES.CURRICULUM_GUIDE,
  components: {
    ChapterNav,
    ChapterInfo,
    ChapterContent,
    HeaderComponent,
  },

  props: {
    defaultLanguage: {
      type: String,
      default: 'python'
    },
    campaign: {
      type: String,
      default: '',
      required: false
    }
  },

  computed: {
    ...mapState({
      isVisible: state => state.baseCurriculumGuide.visible
    }),

    ...mapGetters({
      getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
      getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
      chapterNavBar: 'baseCurriculumGuide/chapterNavBar',
    }),

    chapterNav () {
      // This ensures released chapters are correctly placed, with internal chapters added after.
      const chapters = this.chapterNavBar || []
      const internalChapters = chapters.filter(({ releasePhase }) => releasePhase === 'internalRelease')
      const releasedChapters = chapters.filter(({ releasePhase }) => releasePhase !== 'internalRelease')
      return releasedChapters.concat(internalChapters)
        .map(({ campaignID, free, _id }, idx) => {
          return ({
            campaignID,
            heading: utils.isCodeCombat ? utils.courseAcronyms[_id] : this.$t('teacher_dashboard.chapter_num', { num: idx + 1 }),
          })
        })
    },
  },

  mounted () {
    this.setTeacherId(me.get('_id'))
    this.setPageTitle(PAGE_TITLES[this.$options.name])
    this.fetchData({ componentName: this.$options.name, options: { campaignUrl: this.campaign, loadedEventName: 'Curriculum Guide: Loaded' } })
  },

  methods: {
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData'
    }),
    ...mapMutations({
      setSelectedLanguage: 'baseCurriculumGuide/setSelectedLanguage',
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setPageTitle: 'teacherDashboard/setPageTitle'
    }),
  },
  watch: {
    defaultLanguage: {
      handler (language) {
        this.setSelectedLanguage(language)
      }
    }
  }
}
</script>

<template>
  <div>
    <div>
      <header-component />
      <chapter-nav
        :chapters="chapterNav"
      />
      <chapter-info />

      <chapter-content />
    </div>
  </div>
</template>

<style lang="scss" scoped>
/* TODO: use app/styles/common/transition? */
  #curriculum-guide {
    background-color: white;
  }

  .clickable-hide-area {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;

    /* Sets this under the curriculum guide and over everything else */
    z-index: 1100;
  }
  .spinner-container {
    display: flex;
    justify-content: center;
    align-items: center;
  }
</style>
