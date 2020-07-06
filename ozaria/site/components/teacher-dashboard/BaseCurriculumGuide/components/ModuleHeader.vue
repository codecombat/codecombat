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
        getCurrentModuleHeadingInfo: 'baseCurriculumGuide/getCurrentModuleHeadingInfo'
      }),

      getModuleInfo () {
        return this.getCurrentModuleHeadingInfo(this.moduleNum) || {}
      },

      getModuleTotalTimeInfo () {
        return this.getModuleInfo?.duration?.total
      }
    }
  }
</script>
<template>
  <div class="header">
    <div class="module-header">
      <h3>Module {{ moduleNum }}: {{ getCurrentModuleNames(moduleNum) }}</h3>
      <div v-if="getModuleTotalTimeInfo !== undefined" class="time-row"><p>Class Time: {{ getModuleTotalTimeInfo }} hour</p>
        <!-- TODO: With tooltips add time breakdown -->
        <!-- <icon-help /> -->
      </div>
    </div>
    <div class="buttons">
      <button-slides v-if="getModuleInfo.lessonSlidesUrl" :link="getModuleInfo.lessonSlidesUrl" />
      <button-project-req v-if="getModuleInfo.projectRubricUrl" :link="getModuleInfo.projectRubricUrl" />
      <button-exemplar v-if="getModuleInfo.exemplarProjectUrl" :link="getModuleInfo.exemplarProjectUrl" />
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
