<template>
  <div class="lprogress">
    <div class="lprogress__intro">
      <div class="lprogress__intro__title">
        Levels progress
      </div>
      <div class="lprogress__intro__options">
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot not-started-dot"></div>
          <div class="lprogress__intro__text">Not Started</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot in-progress-dot"></div>
          <div class="lprogress__intro__text">In progress</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot complete-dot"></div>
          <div class="lprogress__intro__text">Complete</div>
        </div>
      </div>
    </div>
    <div class="lprogress__content">
      <div
        v-for="(level, index) in levels"
        class="lprogress__level"
        :key="level.original"
      >
        <module-row
          :display-name="level.name"
          :icon-type="getIconType(level)"
          :description="level.description"
          :show-code-btn="getProgressStatus(level) !== 'not-started'"
          :show-progress-dot="true"
          :progress-status="getProgressStatus(level)"
          :identifier="level.slug"
          @showCodeClicked="onShowCodeClicked"
        />
        <code-diff
          v-if="showCodeModal === level.slug"
          :language="language"
          :code-right="solution"
          :code-left="code"
        />
      </div>
    </div>
  </div>
</template>

<script>
import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
import CodeDiff from '../../../../ozaria/site/components/teacher-dashboard/common/CodeDiff'
const Level = require('../../../models/Level')
export default {
  name: 'ModuleProgressDataComponent',
  props: {
    levels: {
      type: Array,
      required: true
    },
    levelSessions: {
      type: Array
    },
    language: {
      type: String,
      default: 'javascript'
    }
  },
  data () {
    return {
      showCodeModal: false,
      code: null,
      solution: null
    }
  },
  components: {
    ModuleRow,
    CodeDiff
  },
  methods: {
    getIconType (level) {
      if (level.kind === 'practice') return 'practicelvl'
      return (['hero', 'hero-ladder', 'game-dev'].includes(level.type) ? 'challengelvl' : (level.type || 'challengelvl'))
    },
    getProgressStatus (level) {
      let status = 'not-started'
      if (!this.levelSessions) return status
      const ls = this.levelSessions.filter(ls => ls.levelID === level.slug)
      if (ls.length) status = 'in-progress'
      ls.forEach(session => {
        if (session.state.complete) status = 'complete'
      })
      return status
    },
    getSolutions (level) {
      const levelModel = new Level(level)
      return levelModel.getSolutions()
    },
    onShowCodeClicked ({ identifier, hideCode = false }) {
      const levelSlug = identifier
      if (hideCode) {
        this.code = null
        this.solution = null
        this.showCodeModal = null
        return
      }
      const level = this.levels.find(l => l.slug === levelSlug)
      const ls = this.levelSessions.find(ls => ls.levelID === levelSlug)
      const studentCode = this.getStudentCode(ls)
      const solutionCode = this.getSolutionCode(level, { lang: studentCode?.codeLanguage })
      this.code = studentCode?.code
      this.solution = solutionCode
      this.showCodeModal = level.slug
    },
    // do we need language filter?
    getStudentCode (levelSession) {
      if (levelSession?.code?.['hero-placeholder']?.plan) {
        return { codeLanguage: levelSession.codeLanguage, code: levelSession?.code?.['hero-placeholder']?.plan }
      } else if (levelSession?.code?.['hero-placeholder-1']?.plan) {
        return { codeLanguage: levelSession.codeLanguage, code: levelSession?.code?.['hero-placeholder-1']?.plan }
      }
      return null
    },
    getSolutionCode (level, { lang = null }) {
      const solutions = this.getSolutions(level)
      if (lang) {
        const sol = solutions.find(s => s.language === lang)
        if (sol) return sol.source
      }
      return solutions.length ? solutions[0].source : null
    }
  },
  computed: {

  },
  updated () {
    console.log('modProg', this.levels)
  }
}
</script>

<style scoped lang="scss">
.lprogress {
  padding: 2rem;
  &__intro {
    display: flex;
    align-items: center;

    &__title {
      font-weight: 500;
      font-size: 1.6rem;
      line-height: 2rem;
      text-transform: uppercase;

      margin-right: auto;
    }

    &__text {
      font-weight: 400;
      font-size: 1rem;
      line-height: 1.1rem;
    }

    &__options {
      display: flex;
    }

    &__option {
      display: flex;
      flex-direction: column;
      align-items: center;

      padding: 1rem;
    }

    &__dot {
      width: 1rem;
      height: 1rem;
      background: #FFFFFF;
      border-radius: 1rem;
      margin-bottom: .5rem;
    }
  }

  &__diff {
    padding: 1rem;
  }

  &__level {
    &:nth-child(odd) {
      background-color: #f2f2f2;
    }
  }
}

.not-started-dot {
  border: 1.5px solid #C8CDCC;
}

.in-progress-dot {
  background-color: #1ad0ff;
}

.complete-dot {
  background-color: #2dcd38;
}
</style>
