<template>
  <div
    class="lprogress__module"
  >
    <div class="lprogress__info">
      <module-header
        :module-num="`${moduleNum}`"
        :module-name="moduleName"
        :is-capstone="isCapstone"
        :show-lesson-slides="false"
      />
      <div
        v-for="{ icon, name, _id, description, isPartOfIntro, isIntroHeadingRow, slug, fromIntroLevelOriginal } in levels"
        :key="slug"
        class="lprogress__level"
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
          :show-progress-dot="true"
          :show-code-btn="getProgressStatus({ slug, fromIntroLevelOriginal }) !== 'not-started' && !['cutscene', 'cinematic', 'interactive'].includes(icon)"
          :progress-status="getProgressStatus({ slug, fromIntroLevelOriginal })"
          :identifier="slug"
          @showCodeClicked="onShowCodeClicked"
        />
        <code-diff
          v-if="showCodeModal.includes(slug)"
          :language="codeLanguage"
          :code-right="solution[slug]"
          :code-left="code[slug]"
          :key="slug"
        />
      </div>
    </div>
    <div class="lprogress__resources">
      <module-resources
        :lesson-slides-url="lessonSlidesUrl"
        :is-free="isFreeCampaign"
      />
    </div>
  </div>
</template>

<script>
import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
import ModuleResources from './ModuleResources'
import CodeDiff from '../../../components/common/CodeDiff'
import ModuleHeader
  from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleHeader'
import IntroModuleRow
  from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/IntroModuleRow'
import { getStudentAndSolutionCode } from '../helpers/levelCompletionHelper'
import moduleProgressMixin from '../mixins/moduleProgressMixin'

export default {
  name: 'OzModuleProgressComponent',
  props: {
    moduleNum: {
      type: Number
    },
    moduleName: {
      type: String,
    },
    lessonSlidesUrl: {
      type: String
    },
    isFreeCampaign: {
      type: Boolean,
      default: false
    },
    codeLanguage: {
      type: String
    },
    levels: {
      type: Array,
      default () {
        return []
      }
    },
    isCapstone: {
      type: Boolean,
      default: false
    },
    levelSessions: {
      type: Array,
      default () {
        return []
      }
    },
    moduleLevels: {
      type: Array,
      default () {
        return []
      }
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
    ModuleResources,
    CodeDiff,
    ModuleHeader,
    IntroModuleRow
  },
  mixins: [
    moduleProgressMixin
  ],
  methods: {
    onShowCodeClicked ({ identifier, hideCode = false }) {
      const levelSlug = identifier
      if (hideCode) {
        this.showCodeModal = this.showCodeModal.filter(s => s !== levelSlug)
        return
      }
      const level = this.moduleLevels.find(l => l.slug === levelSlug)
      const { studentCode, solutionCode } = getStudentAndSolutionCode(level, this.levelSessions)
      this.code[levelSlug] = studentCode
      this.solution[levelSlug] = solutionCode
      this.showCodeModal.push(level.slug)
    },
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.lprogress {
  &__module {
    display: grid;
    grid-template-columns: 2.5fr 1fr;
  }

  &__level {
    &:nth-child(odd) {
      background-color: $color-grey-2;
    }
    height: unset;
  }
}
</style>
