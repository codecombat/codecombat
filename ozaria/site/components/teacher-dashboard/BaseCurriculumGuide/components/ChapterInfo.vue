<script>
  import IconHelp from '../../common/icons/IconHelp'
  import ButtonPlayChapter from './ButtonPlayChapter'
  import ButtonSolutionGuide from './ButtonSolutionGuide'

  import { mapGetters } from 'vuex'

  export default {
    components: {
      IconHelp,
      ButtonPlayChapter,
      ButtonSolutionGuide
    },

    computed: {
      ...mapGetters({
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getCapstoneInfo: 'baseCurriculumGuide/getCapstoneInfo',
        getCourseUnitMapUrl: 'baseCurriculumGuide/getCourseUnitMapUrl',
        getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign'
      }),

      courseShortName () {
        return this.getCurrentCourse?.shortName || this.getCurrentCourse?.name || ''
      },

      courseDescription () {
        return this.getCurrentCourse?.description || ''
      },

      capstoneName () {
        return this.getCapstoneInfo?.displayName || this.getCapstoneInfo?.name
      },

      totalCourseDuration () {
        return this.getCurrentCourse?.duration?.total || 0
      },

      getCourseThumbnail () {
        // Use backup image if content screenshot missing.
        return this.getCurrentCourse?.screenshot || `/images/ozaria/teachers/dashboard/png_img/TempChapter1PlaceholderArt.png`
      },

      solutionGuideUrl () {
        if (!this.getCurrentCourse || this.isOnLockedCampaign) {
          return ''
        }

        return `/teachers/course-solution/${this.getCurrentCourse._id}/${this.getSelectedLanguage}`
      },

      playChapterUrl () {
        if (this.isOnLockedCampaign) {
          return ''
        }
        return this.getCourseUnitMapUrl || ''
      },

      clickedLink () {
        return !this.isOnLockedCampaign
      }
    },

    methods: {
      tooltipTimeContent () {
        const time = []

        if (this.getCurrentCourse?.duration?.totalTimeRange) {
          time.push(`<p><b>Total Class Time:</b> ${this.getCurrentCourse?.duration?.totalTimeRange}</p>`)
        }

        if (this.getCurrentCourse?.duration?.inGame) {
          time.push(`<p><b>In-Game Play Time:</b> ${this.getCurrentCourse?.duration?.inGame}</p>`)
        }

        return time.join('')
      }
    }
  }
</script>
<template>
  <div id="chapter-info">
    <div class="img-container">
      <img class="img-responsive" :src="getCourseThumbnail">
    </div>
    <div class="info-container">
      <h3>{{ courseShortName }}</h3>
      <p class="chapter-summary">
        {{ courseDescription }}
      </p>
      <div class="stats-and-btns">
        <div>
          <p><b>Capstone Project</b>: {{ capstoneName }}</p>
          <div
            v-if="totalCourseDuration"
            class="time-row"
          >
            <p>
              <b>Class Time</b>: {{ totalCourseDuration }}
            </p>
            <icon-help
              v-if="tooltipTimeContent()"
              v-tooltip.top="{
                content: tooltipTimeContent,
                classes: 'teacher-dashboard-tooltip'
              }"
            />
          </div>
        </div>
        <div v-if="!isOnLockedCampaign" class="btns">
          <a :href="playChapterUrl" target="_blank" rel="noreferrer"> <button-play-chapter /> </a>
          <a :href="solutionGuideUrl" target="_blank" rel="noreferrer"> <button-solution-guide /> </a>
        </div>
        <div v-else class="btns">
          <span
            v-tooltip.top="{
              content: `<h3>You need licenses to access this content!</h3><p>Please visit the <a href='/teachers/licenses'>My Licenses</a> page for more information.</p>`,
              classes: 'teacher-dashboard-tooltip',
              autoHide: false
            }"
          >
            <button-play-chapter
              :locked="isOnLockedCampaign"
            />
          </span>
          <span
            v-tooltip.top="{
              content: `<h3>You need licenses to access this content!</h3><p>Please visit the <a href='/teachers/licenses'>My Licenses</a> page for more information.</p>`,
              classes: 'teacher-dashboard-tooltip',
              autoHide: false
            }"
          >
            <button-solution-guide
              :locked="isOnLockedCampaign"
            />
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #chapter-info {
    display: flex;
    flex-direction: row;

    background-color: #f2f2f2;

    .img-container {
      max-width: 256px;
      width: 100%;

      margin-right: 30px;

      display: flex;
      align-items: center;
    }

    .time-row {
      display: flex;
      flex-direction: row;

      & > img {
        margin-left: 9px;
      }
    }

    h3 {
      @include font-h-4-nav-uppercase-black;
      color: $pitch;
      text-align: left;

      margin: 18px 0 5px;
    }

    p {
      @include font-p-4-paragraph-smallest-gray;
      color: $pitch;
      font-size: 16px;
      line-height: 20px;
      font-style: normal;
      font-weight: normal;
    }

    .chapter-summary {
      margin-right: 60px;
    }
  }

  .info-container {
    display: flex;
    flex-direction: column;
  }

  .stats-and-btns {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;

    margin-bottom: 18px;
    margin-right: 60px;

    & > div {
      /* Ensure containers are evenly distributed */
      flex: 1 1 auto;
    }

    .btns {
      display: flex;
      justify-content: space-around;

      &.locked a {
        cursor: default;
      }

      a {
        text-decoration: none;
      }
    }

    p {
      margin-bottom: 5px;
    }
  }

</style>
