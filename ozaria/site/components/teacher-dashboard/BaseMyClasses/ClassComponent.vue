<script>
import ClassSummaryRow from './components/ClassSummaryRow'
import ClassChapterSummaries from './components/ClassChapterSummaries'
import ClassLinksComponent from './components/ClassLinksComponent.vue'
import utils from 'core/utils'

export default {
  components: {
    ClassSummaryRow,
    ClassChapterSummaries,
    ClassLinksComponent
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
  },

  computed: {
    showEsportsCampInfoCoco () {
      return utils.isCodeCombat && me.isCodeNinja() && !this.chapterStats.length
    },

    showEsportsCampInfoOz () {
      return utils.isOzaria && me.isCodeNinja() && this.chapterStats.length === 2
    },

    showJuniorCampInfo () {
      return utils.isCodeCombat && me.isCodeNinja() && this.chapterStats.length === 1
    },

    limitedChapterStats () {
      switch (this.classroomStats.type) {
      case 'club-esports':
      case 'club-roblox':
        return []
      case 'club-junior':
        return this.chapterStats.filter(chapter => chapter.name === 'Junior')
      case 'club-hackstack':
        return this.chapterStats.filter(chapter => chapter.name === 'HackStack')
      default:
        return this.chapterStats
      }
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
      :date-start="classroomStats.classDateStart"
      :date-end="classroomStats.classDateEnd"
      :code-camel="classroomStats.codeCamel"
      :archived="classroomStats.archived"
      :display-only="displayOnly"
      :share-permission="classroomStats.sharePermission"
      :class-type="classroomStats.type"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
      @clickAddStudentsModalButton="$emit('clickAddStudentsModalButton')"
      @clickShareClassWithTeacherModalButton="$emit('clickShareClassWithTeacherModalButton')"
    />
    <!--
      can be enabled for shared once in addition to fetchCourseInstancesForTeacher, we do it for all shared class whose owner is not this logged in teacher
    -->
    <class-chapter-summaries
      v-if="!classroomStats.sharePermission"
      :chapter-progress="limitedChapterStats"
    />
    <class-links-component
      :show-esports-camp-info-coco="showEsportsCampInfoCoco"
      :show-esports-camp-info-oz="showEsportsCampInfoOz"
      :show-junior-camp-info="showJuniorCampInfo"
      :club-type="classroomStats.type"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/components/teacher-dashboard/common/_dusk-button";

</style>
