<template>
  <div class="lprogress__module">
    <div class="lprogress__info">
      <div
        v-for="level in levels"
        class="lprogress__level"
        :key="level.original"
      >
        <module-row
          :display-name="level.name"
          :icon-type="getIconType(level)"
          :description="formatDescription(level.description)"
          :show-code-btn="getProgressStatus(level) !== 'not-started'"
          :show-progress-dot="true"
          :progress-status="getProgressStatus(level)"
          :identifier="level.slug"
          @showCodeClicked="onShowCodeClicked"
        />
        <code-diff
          v-if="showCodeModal.includes(level.slug)"
          :language="codeLanguage"
          :code-right="solution[level.slug]"
          :code-left="code[level.slug]"
        />
      </div>
    </div>
    <div class="lprogress__resources">
      <module-resources
        :lesson-slides-url="lessonSlidesUrl"
      />
    </div>
  </div>
</template>

<script>
import LevelProgressInfoComponent from './LevelProgressInfoComponent'
import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
import ModuleResources from './ModuleResources'
import CodeDiff from '../../../components/common/CodeDiff'
import moduleProgressMixin from '../mixins/moduleProgressMixin'
import { getStudentAndSolutionCode } from '../helpers/levelCompletionHelper'
export default {
  name: 'CocoModuleProgressComponent',
  props: {
    levels: {
      type: Array,
      default () {
        return []
      }
    },
    codeLanguage: {
      type: String
    },
    lessonSlidesUrl: {
      type: String
    },
    levelSessions: {
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
    LevelProgressInfoComponent,
    ModuleRow,
    ModuleResources,
    CodeDiff
  },
  mixins: [
    moduleProgressMixin
  ],
  methods: {
    getIconType (level) {
      if (level.kind === 'practice' || level.practice) return 'practicelvl'
      return (['hero', 'hero-ladder', 'game-dev'].includes(level.type) ? 'challengelvl' : (level.type || 'challengelvl'))
    },
    formatDescription (desc) {
      if (!desc) return ''
      const d = desc.replace(/!\[.*?\]\(.*?\)\n*/g, '')
      if (d.length > 60) {
        return this.truncate(d, 60, '...')
      }
      return d
    },
    truncate (str, max, suffix) {
      return str.length < max ? str : `${str.substr(0, str.substr(0, max - suffix.length).lastIndexOf(' '))}${suffix}`
    },
    onShowCodeClicked ({ identifier, hideCode = false }) {
      const levelSlug = identifier
      if (hideCode) {
        this.showCodeModal = this.showCodeModal.filter(s => s !== levelSlug)
        return
      }
      const level = this.levels.find(l => l.slug === levelSlug)
      const { studentCode, solutionCode } = getStudentAndSolutionCode(level, this.levelSessions)
      this.code[levelSlug] = studentCode
      this.solution[levelSlug] = solutionCode
      this.showCodeModal.push(level.slug)
    }
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
