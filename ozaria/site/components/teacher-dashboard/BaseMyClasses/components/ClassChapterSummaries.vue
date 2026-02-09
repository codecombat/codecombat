<script>
import UnitProgress from './UnitProgress'
import { isCodeCombat } from 'core/utils'

export default {
  components: {
    UnitProgress
  },

  props: {
    chapterProgress: {
      type: Array,
      required: true
    }
  },

  computed: {
    codeCombatCourses () {
      return this.chapterProgress.filter(chapter => !chapter.isOzCourse && !chapter.isHackstackCourse)
    },

    ozariaCourses () {
      return this.chapterProgress.filter(chapter => chapter.isOzCourse)
    },

    hackstackCourses () {
      return this.chapterProgress.filter(chapter => chapter.isHackstackCourse)
    },

    showCodeCombatRow () {
      return isCodeCombat && this.codeCombatCourses.length > 0
    },

    showOzariaRow () {
      return me.showOzCourses() && this.ozariaCourses.length > 0
    },
    showHackstackRow () {
      return isCodeCombat && this.hackstackCourses.length > 0
    },
  },
}
</script>

<template>
  <div>
    <div
      v-if="showCodeCombatRow"
      class="class-chapter-summary flex-row"
    >
      <img
        class="logo"
        alt="CodeCombat logo"
        src="/images/pages/base/logo_square_250.png"
      >
      <div
        class="classes flex-row"
      >
        <unit-progress
          v-for="chapter in codeCombatCourses"
          :key="chapter.name"
          :name="chapter.name"
          :is-assigned="chapter.assigned"
          :completion-percentage="chapter.progress"
        />
      </div>
    </div>

    <div
      v-if="showOzariaRow"
      class="class-chapter-summary flex-row"
    >
      <img
        class="logo"
        alt="Ozaria logo"
        src="/images/ozaria/home/ozaria-logo.png"
      >
      <div
        class="classes flex-row"
      >
        <unit-progress
          v-for="chapter in ozariaCourses"
          :key="chapter.name"
          :name="chapter.name"
          :is-assigned="chapter.assigned"
          :completion-percentage="chapter.progress"
        />
      </div>
    </div>

    <div
      v-if="showHackstackRow"
      class="class-chapter-summary flex-row"
    >
      <img
        class="logo"
        alt="Hackstack logo"
        src="/images/pages/hackstack/hackstack-logo-square-transparent-256.png"
      >
      <div
        class="classes flex-row"
      >
        <unit-progress
          v-for="chapter in hackstackCourses"
          :key="chapter.name"
          :name="chapter.name"
          :is-assigned="chapter.assigned"
          :completion-percentage="chapter.progress"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .logo {
    height: 50px;
    margin-left: 15px;
  }

  .classes {
    flex-wrap: wrap;
    height: 100%;
    padding: 10px;
  }

  .class-chapter-summary {
    background-color: #f2f2f2;
    border: 1px solid #d8d8d8;
    justify-content: start;

    &:last-child {
      margin-bottom: 0;
    }
  }
</style>
