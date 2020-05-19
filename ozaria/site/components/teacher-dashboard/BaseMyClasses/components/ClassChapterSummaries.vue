<script>
  import UnitProgress from './UnitProgress'

  export default {
    components: {
      UnitProgress
    },

    props: {
      chapterProgress: {
        type: Array,
        required: true
      }
    }
  }
</script>

<template>
  <div
    id="class-chapter-summary"
    class="flex-row"
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

  #classes {
    flex-wrap: wrap;
    height: 100%;
    padding: 10px;
  }

  #class-chapter-summary {
    background-color: #f2f2f2;
    border: 1px solid #d8d8d8;

    justify-content: space-between;
  }
</style>
