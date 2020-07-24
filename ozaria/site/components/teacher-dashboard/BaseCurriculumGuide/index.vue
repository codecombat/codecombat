<script>
  import { mapState, mapActions, mapGetters, mapMutations } from 'vuex'

  import ChapterNav from './components/ChapterNav'
  import ChapterInfo from './components/ChapterInfo'
  import ConceptsCovered from './components/ConceptsCovered'
  import CstaStandards from './components/CstaStandards'
  import ModuleContent from './components/ModuleContent'

  export default {
    components: {
      ChapterNav,
      ChapterInfo,
      ConceptsCovered,
      CstaStandards,
      ModuleContent
    },

    computed: {
      ...mapState({
        isVisible: state => state.baseCurriculumGuide.visible
      }),

      ...mapGetters({
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
        getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage'
      }),

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

    methods: {
      ...mapActions({
        toggleCurriculumGuide: 'baseCurriculumGuide/toggleCurriculumGuide'
      }),
      ...mapMutations({
        setSelectedLanguage: 'baseCurriculumGuide/setSelectedLanguage',
        closeCurriculumGuide: 'baseCurriculumGuide/closeCurriculumGuide'
      }),
      changeLanguage(e) {
        this.setSelectedLanguage(e.target.value)
      }
    }
  }
</script>

<template>
  <div>
    <transition name="slide">
      <div
        v-if="isVisible"
        id="curriculum-guide"
      >
        <div class="header">
          <div class="header-icon">
            <img src="/images/ozaria/teachers/dashboard/svg_icons/IconCurriculumGuide.svg">
            <h2>Curriculum Guide</h2>
          </div>
          <div
            class="header-right"
          >
            <div class="code-language-dropdown">
              <span class="select-language"> Select Language </span>
              <select @change="changeLanguage">
                <option value="python" :selected="getSelectedLanguage === 'python'"> Python </option>
                <option value="javascript" :selected="getSelectedLanguage === 'javascript'"> Javascript </option>
              </select>
            </div>
            <img
              class="close-btn"
              @click="toggleCurriculumGuide"
              src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Exit.svg"
            >
          </div>
        </div>

        <chapter-nav />
        <chapter-info />

        <div class="fluid-container">
          <div class="row">
            <div class="col-md-9">
              <module-content :module-num="num" v-for="num in moduleNumbers" :key="num"/>
            </div>
            <div class="col-md-3">
              <concepts-covered :concept-list="conceptsCovered" />
              <csta-standards :csta-list="cstaStandards" />
            </div>
          </div>
        </div>
      </div>
    </transition>
    <div
      v-if="isVisible"
      class="clickable-hide-area"

      @click="closeCurriculumGuide"
    >
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #curriculum-guide {
    position: fixed;
    right: 0;
    bottom: 0;

    max-width: 1116px;
    width: 90vw;
    width: 1116px;
    z-index: 1200;

    max-height: 100vh;
    overflow-y: scroll;

    background-color: white;
    box-shadow: -8px 4px 20px rgba(0, 0, 0, 0.25);

     /* For animating the panel sliding in and out. */
    &.slide-enter-active, &.slide-leave-active {
      -webkit-transition: right 0.7s ease;
      -moz-transition: right 0.7s ease;
      -o-transition: right 0.7s ease;
      -ms-transition: right 0.7s ease;
      transition: right 0.7s ease;
    }

    &.slide-enter, &.slide-leave-to {
      right: -1116px;
    }

    &.slide-enter-to, &.slide-leave {
      right: 0;
    }
  }

  .fluid-container {
    padding: 30px 25px;
  }

  .header {
    height: 60px;
    border: 1px solid rgba(0, 0, 0, 0.13);
    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

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
</style>
