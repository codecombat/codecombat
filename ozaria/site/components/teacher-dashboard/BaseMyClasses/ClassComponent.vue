<script>
  import ClassSummaryRow from './components/ClassSummaryRow'
  import ClassChapterSummaries from './components/ClassChapterSummaries'

  export default {
    components: {
      ClassSummaryRow,
      ClassChapterSummaries
    },
    props: {
      classroom: {
        type: Object,
        required: true
      }
    }
  }
</script>

<template>
  <div class="class-component">
    <class-summary-row
      :classroom-name="classroom.name"
      :language="classroom.language"
      :num-students="classroom.numberOfStudents"
      :date-created="classroom.classroomCreated"
    />
    <class-chapter-summaries :chapter-progress="classroom.chapters" />
  </div>
</template>

<style lang="scss" scoped>
  .class-component {
    margin: 28px 32px 0;
  }
</style>
