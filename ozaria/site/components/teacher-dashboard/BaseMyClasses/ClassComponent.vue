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
      :share-permission="classroomStats.sharePermission"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
      @clickAddStudentsModalButton="$emit('clickAddStudentsModalButton')"
      @clickShareClassWithTeacherModalButton="$emit('clickShareClassWithTeacherModalButton')"
    />
    <!--
      can be enabled for shared once in addition to fetchCourseInstancesForTeacher, we do it for all shared class whose owner is not this logged in teacher
    -->
    <class-chapter-summaries
      v-if="!classroomStats.sharePermission"
      :chapter-progress="chapterStats"
    />
  </div>
</template>

<style lang="scss" scoped>

</style>
