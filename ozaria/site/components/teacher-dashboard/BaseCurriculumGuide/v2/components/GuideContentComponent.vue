<template>
  <div class="guide-content">
    <chapter-nav :chapters="chaptersNavData" />
    <div class="separator" />
    <chapter-info />
    <chapter-content />
  </div>
</template>

<script>
import ChapterNav from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ChapterNav.vue'
import ChapterInfo from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ChapterInfo.vue'
import ChapterContent from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ChapterContent.vue'
import { mapActions, mapGetters } from 'vuex'
import utils from 'core/utils'
export default {
  name: 'GuideContentComponent',
  components: {
    ChapterNav,
    ChapterInfo,
    ChapterContent,
  },
  props: {
    product: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      chapterNavBar: 'baseCurriculumGuide/chapterNavBar',
    }),
    chaptersNavData () {
      const chapters = (this.chapterNavBar || []).filter(({ releasePhase }) => releasePhase === 'released')
      const hackstackCourseIds = utils.HACKSTACK_COURSE_IDS || []
      const juniorCourseIds = utils.JUNIOR_COURSE_IDS || []
      let result
      if (this.product === 'hackstack') {
        result = chapters.filter(({ _id }) => hackstackCourseIds.includes(_id))
      } else if (this.product === 'junior') {
        result = chapters.filter(({ _id }) => juniorCourseIds.includes(_id))
      } else {
        result = chapters.filter(({ _id }) => !hackstackCourseIds.includes(_id) && !juniorCourseIds.includes(_id))
      }
      return result
        .map(({ campaignID, _id }, idx) => {
          return ({
            campaignID,
            heading: utils.isCodeCombat ? utils.courseAcronyms[_id] : this.$t('teacher_dashboard.chapter_num', { num: idx + 1 }),
          })
        })
    },
  },
  async mounted () {
    await this.fetchData()
  },
  methods: {
    ...mapActions({
      fetchReleasedCourses: 'courses/fetchReleased',
    }),
    async fetchData () {
      try {
        await this.fetchReleasedCourses()
      } catch (err) {
        console.error('Error fetching released courses', err)
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.separator {
  border: 1px solid #E6E6E6;
  box-shadow: inset 0px -2px 10px rgba(0, 0, 0, 0.15);
}
</style>
