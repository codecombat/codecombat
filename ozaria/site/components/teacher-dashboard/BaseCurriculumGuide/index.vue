<script>
import { mapState, mapActions, mapGetters, mapMutations } from 'vuex'

import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
import utils from 'core/utils'

import ChapterNav from './components/ChapterNav'
import ChapterInfo from './components/ChapterInfo'
import ConceptsCovered from './components/ConceptsCovered'
import CstaStandards from './components/CstaStandards'
import ModuleContent from './components/ModuleContent'
import LoadingSpinner from 'app/components/common/elements/LoadingSpinner'

export default {
  name: COMPONENT_NAMES.CURRICULUM_GUIDE,
  components: {
    ChapterNav,
    ChapterInfo,
    ConceptsCovered,
    CstaStandards,
    ModuleContent,
    LoadingSpinner
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
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
      getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
      getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
      getTrackCategory: 'teacherDashboard/getTrackCategory'
    }),

    courseName () {
      return this.getCurrentCourse?.name || ''
    },

    conceptsCovered () {
      return this.getCurrentCourse?.concepts || []
    },

    cstaStandards () {
      return this.getCurrentCourse?.cstaStandards || []
    },

    moduleNumbers () {
      return Object.keys(this.getModuleInfo || {})
    }
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
    changeLanguage (e) {
      window.tracker?.trackEvent('Curriculum Guide: Language Changed from dropdown', { category: this.getTrackCategory, label: this.courseName })
      this.setSelectedLanguage(e.target.value)
    },
    isCapstoneModule (moduleNum) {
      if (utils.isCodeCombat) {
        return false
      }
      // Assuming that last module is the capstone module, TODO store `isCapstoneModule` with module details in the course schema.
      return moduleNum === this.moduleNumbers[this.moduleNumbers.length - 1]
    }
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
      <div class="header">
        <div class="header-icon">
          <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCurriculumGuide.svg">
          <h2>{{ $t('teacher_dashboard.curriculum_guide') }}</h2>
        </div>
        <div
          class="header-right"
        >
          <div class="code-language-dropdown">
            <span class="select-language">{{ $t('courses.select_language') }}</span>
            <select @change="changeLanguage">
              <option
                value="python"
                :selected="getSelectedLanguage === 'python'"
              >
                Python
              </option>
              <option
                value="javascript"
                :selected="getSelectedLanguage === 'javascript'"
              >
                JavaScript
              </option>
            </select>
          </div>
        </div>
      </div>

      <chapter-nav />
      <chapter-info />

      <div class="fluid-container">
        <div class="row">
          <div class="col-md-9">
            <module-content
              v-for="num in moduleNumbers"
              :key="num"
              :module-num="num"
              :is-capstone="isCapstoneModule(num)"
            />
            <div
              v-if="moduleNumbers.length==0"
              class="spinner-container"
            >
              <LoadingSpinner />
            </div>
          </div>
          <div class="col-md-3">
            <concepts-covered :concept-list="conceptsCovered" />
            <csta-standards :csta-list="cstaStandards" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

/* TODO: use app/styles/common/transition? */
  #curriculum-guide {
    background-color: white;
  }

  .fluid-container {
    padding: 30px 25px;
  }

  .header {
    height: 60px;

    background-color: #f2f2f2;
    border: 1px solid #d8d8d8;
    /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
    -webkit-box-shadow: 0 8px 6px -6px #D2D2D2;
      -moz-box-shadow: 0 8px 6px -6px #D2D2D2;
          box-shadow: 0 8px 6px -6px #D2D2D2;

    display: flex;
    flex-direction: row;
    justify-content: space-between;

    .header-icon {
      display: flex;
      flex-direction: row;
      align-items: center;

      img {
        margin-left: 25px;
        margin-right: 10px;
      }
    }

    h2 {
      @include font-h-2-subtitle-white-24;
      color: black;
      line-height: 28px;
      letter-spacing: 0.56px;
    }

    .header-right {
      display: flex;
      justify-content: center;
      align-items: center;
      margin-right: 12px;
    }

    .code-language-dropdown {
      select {
        background: $twilight;
        border: 1.5px solid #355EA0;
        border-radius: 4px;
        color: $moon;
        width: 150px;
        padding: 8px 5px;
        font-family: Work Sans;
        font-style: normal;
        font-weight: 600;
        font-size: 14px;
        line-height: 20px;
      }
    }

    .select-language {
      font-family: Work Sans;
      font-weight: 600;
      font-size: 12px;
      line-height: 16px;
      color: #545B64;
      padding: 8px;
    }

    .close-btn {
      cursor: pointer;
      margin-left: 30px;
      padding: 10px;
    }
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
