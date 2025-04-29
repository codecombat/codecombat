<template>
  <div class="chapter-content">
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
</template>

<script>
import ConceptsCovered from './ConceptsCovered'
import CstaStandards from './CstaStandards'
import ModuleContent from './ModuleContent'
import LoadingSpinner from 'app/components/common/elements/LoadingSpinner'
import { mapGetters } from 'vuex'
import utils from 'core/utils'

export default {
  name: 'ChapterContent',
  components: {
    ConceptsCovered,
    CstaStandards,
    ModuleContent,
    LoadingSpinner,
  },
  computed: {
    ...mapGetters({
      getModuleInfo: 'baseCurriculumGuide/getModuleInfo',
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
    }),
    moduleNumbers () {
      return Object.keys(this.getModuleInfo || {})
    },
    conceptsCovered () {
      return this.getCurrentCourse?.concepts || []
    },

    cstaStandards () {
      return this.getCurrentCourse?.cstaStandards || []
    },
  },
  methods: {
    isCapstoneModule (moduleNum) {
      if (utils.isCodeCombat) {
        return false
      }
      // Assuming that last module is the capstone module, TODO store `isCapstoneModule` with module details in the course schema.
      return moduleNum === this.moduleNumbers[this.moduleNumbers.length - 1]
    },
  },
}
</script>

<style lang="scss" scoped>
.fluid-container {
  padding: 30px 25px;
}
</style>