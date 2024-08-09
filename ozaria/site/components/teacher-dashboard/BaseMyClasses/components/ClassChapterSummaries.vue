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
    getLogoSrc () {
      if (isCodeCombat) {
        return '/images/pages/base/logo_square_250.png'
      }
      return '/images/ozaria/home/ozaria-logo.png'
    }
  },
}
</script>

<template>
  <div
    id="class-chapter-summary"
    class="flex-row"
  >
    <img
      class="logo"
      alt="logo"
      :src="getLogoSrc"
    >
    <div
      id="classes"
      class="flex-row"
    >
      <unit-progress
        v-for="chapter in chapterProgress"
        :key="chapter.name"

        :name="chapter.name"
        :is-assigned="chapter.assigned"
        :completion-percentage="chapter.progress"
      />
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

  #classes {
    flex-wrap: wrap;
    height: 100%;
    padding: 10px;
  }

  #class-chapter-summary {
    background-color: #f2f2f2;
    border: 1px solid #d8d8d8;

    justify-content: start;
  }
</style>
