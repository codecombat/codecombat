<script>
  import { mapState, mapActions, mapGetters } from 'vuex'

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
        getModuleInfo: 'baseCurriculumGuide/getModuleInfo'
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
      })
    }
  }
</script>

<template>
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
        class="close-btn"
        @click="toggleCurriculumGuide"
      >
        <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Exit.svg">
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

    .close-btn {
      cursor: pointer;

      width: 58px;
      display: flex;
      justify-content: center;
      align-items: center;
    }
  }
</style>
