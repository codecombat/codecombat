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
      },
      displayOnly: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <div class="class-component">
    <class-summary-row
      :class-id="classroomStats.id"
      :classroom-name="classroomStats.name"
      :language="classroomStats.language"
      :num-students="classroomStats.numberOfStudents"
      :date-created="classroomStats.classroomCreated"
      :code-camel="classroomStats.codeCamel"
      :archived="classroomStats.archived"
      :display-only="displayOnly"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
      @clickAddStudentsModalButton="$emit('clickAddStudentsModalButton')"
    />
    <class-chapter-summaries :chapter-progress="chapterStats" />
  </div>
</template>

<style lang="scss" scoped>

</style>
