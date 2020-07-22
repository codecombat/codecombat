<script>
  import ButtonSlides from './ButtonSlides'
  import ButtonProjectReq from './ButtonProjectReq'
  import ButtonExemplar from './ButtonExemplar'

  import IconHelp from '../../common/icons/IconHelp'
  import { mapGetters } from 'vuex'
  export default {
    components: {
      ButtonSlides,
      ButtonProjectReq,
      ButtonExemplar,
      IconHelp
    },
    props: {
      moduleNum: {
        required: true,
        type: String
      }
    },
    computed: {
      ...mapGetters({
        getCurrentModuleNames: 'baseCurriculumGuide/getCurrentModuleNames',
        getCurrentModuleHeadingInfo: 'baseCurriculumGuide/getCurrentModuleHeadingInfo',
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign'
      }),

      getModuleInfo () {
        return this.getCurrentModuleHeadingInfo(this.moduleNum) || {}
      },

      getModuleTotalTimeInfo () {
        return this.getModuleInfo?.duration?.total
      }
    },

    methods: {
      tooltipTimeContent () {
        const time = []

        if (this.getModuleInfo?.duration?.totalTimeRange) {
          time.push(`<p><b>Class Time (Range):</b> ${this.getModuleInfo?.duration?.totalTimeRange}</p>`)
        }

        if (this.getModuleInfo?.duration?.inGame) {
          time.push(`<p><b>In-Game Play Time:</b> ${this.getModuleInfo?.duration?.inGame}</p>`)
        }

        return time.join('')
      },

      projectRubricTooltipContent () {
        if (this.isOnLockedCampaign) {
          return `<h3>You need licenses to access this content!</h3><p>Please visit the <a href='/teachers/licenses'>My Licenses</a> page for more information.</p>`
        }
        return `<h3>Project Rubric</h3><p>Downloadable and modifiable scoring rubric for the Capstone Project</p>`
      },

      exemplarProjectTooltipContent () {
        if (this.isOnLockedCampaign) {
          return `<h3>You need licenses to access this content!</h3><p>Please visit the <a href='/teachers/licenses'>My Licenses</a> page for more information.</p>`
        }
        return `<h3>Exemplar Project</h3><p>Live view of the exemplar Capstone Project</p>`
      }
    }
  }
</script>
<template>
  <div class="header">
    <div class="module-header">
      <h3>Module {{ moduleNum }}: {{ getCurrentModuleNames(moduleNum) }}</h3>
      <div v-if="getModuleTotalTimeInfo !== undefined" class="time-row"><p>Class Time: {{ getModuleTotalTimeInfo }}</p>
        <icon-help
          v-if="tooltipTimeContent()"
          v-tooltip.top="{
            content: tooltipTimeContent,
            classes: 'teacher-dashboard-tooltip'
          }"
        />
      </div>
    </div>
    <div class="buttons">
      <!-- For this locked tooltip we use a span, as the disabled button doesn't trigger a tooltip. -->
      <template
        v-if="getModuleInfo.lessonSlidesUrl"
      >
        <span
          v-if="isOnLockedCampaign"
          v-tooltip.top="{
            content: `<h3>You need licenses to access this content!</h3><p>Please visit the <a href='/teachers/licenses'>My Licenses</a> page for more information.</p>`,
            classes: 'teacher-dashboard-tooltip lighter-p',
            autoHide: false
          }"
        >
        <button-slides
            :link="getModuleInfo.lessonSlidesUrl"
            :locked="true"
          />
        </span>
        <button-slides
          v-else
          :link="getModuleInfo.lessonSlidesUrl"
          :locked="isOnLockedCampaign"
          v-tooltip.top="{
            content: `<h3>Lesson Slides</h3><p>Downloadable, step-by-step presentation slides for guiding students through module learning objectives</p>`,
            classes: 'teacher-dashboard-tooltip lighter-p'
          }"
        />
      </template>

      <button-project-req
        v-if="getModuleInfo.projectRubricUrl"
        :link="getModuleInfo.projectRubricUrl"
        :locked="isOnLockedCampaign"
        v-tooltip.top="{
          content: projectRubricTooltipContent,
          classes: 'teacher-dashboard-tooltip lighter-p',
          autoHide: !isOnLockedCampaign
        }"
      />

      <button-exemplar
        v-if="getModuleInfo.exemplarProjectUrl"
        :link="getModuleInfo.exemplarProjectUrl"
        :locked="isOnLockedCampaign"

        v-tooltip.top="{
          content: exemplarProjectTooltipContent,
          classes: 'teacher-dashboard-tooltip lighter-p',
          autoHide: !isOnLockedCampaign
        }"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .header {
    height: 60px;

    display: flex;
    flex-direction: row;
    align-items: center;

    border: 0.5px solid #d8d8d8;
    box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.12);

    padding: 0 15px;

    .module-header {
      flex: 1 1 auto;
    }
    .buttons {
      flex: 2 2 auto;
      display: flex;
      align-items: center;
    }
  }

  .time-row {
    display: flex;
    flex-direction: row;

    & > img {
      margin-left: 9px;
    }
  }

  h3 {
    @include font-p-3-small-button-text-black;
    text-align: left;
    color: #333333;
    margin-bottom: 3px;
  }
  p {
    @include font-p-4-paragraph-smallest-gray;
    color: #131b25;
    margin-bottom: 0;
  }
</style>
