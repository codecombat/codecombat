<script>
  import { mapGetters, mapActions } from 'vuex'
  export default {
    computed: {
      ...mapGetters({
        chapterNavBar: 'baseCurriculumGuide/chapterNavBar',
        selectedChapterId: 'baseCurriculumGuide/selectedChapterId',
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      }),

      chapterNav () {
        // This ensures released chapters are correctly placed, with internal chapters added after.
        return (this.chapterNavBar || [])
          .filter(({ releasePhase }) => releasePhase !== 'internalRelease')
          .concat(
            (this.chapterNavBar || [])
              .filter(({ releasePhase }) => releasePhase === 'internalRelease')
          ).map(({ campaignID, free }, idx) => {
            return ({
              campaignID,
              heading: this.$t('teacher_dashboard.chapter_num', { num: idx + 1 })
            })
          })
      },

      courseName () {
        return this.getCurrentCourse?.name || ''
      }
    },

    methods: {
      ...mapActions({
        clickChapterHeading: 'baseCurriculumGuide/setSelectedCampaign'
      }),

      classForButton (campaignID) {
        return {
          selected: this.selectedChapterId === campaignID,
          'chapter-btn': true
        }
      },

      clickChapterNav (campaignID) {
        this.clickChapterHeading(campaignID)
        window.tracker?.trackEvent('Curriculum Guide: Chapter Nav Clicked', { category: this.getTrackCategory, label: this.courseName })
      }
    }
  }
</script>

<template>
  <div id="chapter-nav">
    <div
      v-for="{ campaignID, heading } in chapterNav"
      :key="campaignID"
      :class="classForButton(campaignID)"

      @click="() => clickChapterNav(campaignID)"
    >
      <div class="chapter-pill">
        {{ heading }}
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #chapter-nav {
    display: flex;
    margin: 8px 25px 0;

    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

    h4 {
      @include font-h-4-nav-uppercase-black;
      font-size: 14px;
      line-height: 18px;
      color: #545b64;
    }
  }

  .chapter-pill {
    padding: 9px 20px;
    border-radius: 20px;

    &:hover {
      background-color: #f2f2f2;
    }
  }

  .chapter-btn {
    margin: 0 2.5px;
    padding: 0 5px;

    cursor: pointer;

    transition: border-color 0.2s;
    border-bottom: 4px solid rgba(71,111,177, 0);

    &.selected {
      border-bottom: 4px solid rgba(71,111,177, 1);
    }
  }
</style>
