<script>
  import ClassSummaryRow from './components/ClassSummaryRow'
  import ClassChapterSummaries from './components/ClassChapterSummaries'

  export default {
    components: {
      ClassSummaryRow,
      ClassChapterSummaries
    },
    props: {
      classroomStats: {
        type: Object,
        required: true
      },
      chapterStats: {
        type: Array,
        required: true
      }
    }
  }
</script>

<template>
  <div class="class-component">
    <class-summary-row
      :classroom-name="classroomStats.name"
      :language="classroomStats.language"
      :num-students="classroomStats.numberOfStudents"
      :date-created="classroomStats.classroomCreated"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
    />
    <class-chapter-summaries :chapter-progress="chapterStats" />
  </div>
</template>

<style lang="scss" scoped>
  .class-component {
    margin: 28px 32px 0;
  }
</style>
