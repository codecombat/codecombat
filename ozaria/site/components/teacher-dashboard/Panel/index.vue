<script>
import { mapMutations, mapGetters } from 'vuex'

import AiScenario from './components/AiScenario'
import StudentInfo from './components/StudentInfo'
import ConceptCheckInfo from './components/ConceptCheckInfo'
import PracticeLevel from './components/PracticeLevel'
import CapstoneLevel from './components/CapstoneLevel'
import DraggableOrdering from './components/DraggableOrdering'
import InsertCode from './components/InsertCode'
import DraggableStatementCompletion from './components/DraggableStatementCompletion'
import ContentIcon from '../common/icons/ContentIcon'
import { getGameContentDisplayType } from 'ozaria/site/common/ozariaUtils.js'
import { secondsToMinutesAndSeconds } from 'core/utils'

export default {
  components: {
    StudentInfo,
    ConceptCheckInfo,
    PracticeLevel,
    CapstoneLevel,
    DraggableOrdering,
    DraggableStatementCompletion,
    InsertCode,
    ContentIcon,
    AiScenario
  },

  computed: {
    ...mapGetters({
      panelFooter: 'teacherDashboardPanel/panelFooter',
      isOpen: 'teacherDashboardPanel/isOpen',
      panelHeader: 'teacherDashboardPanel/panelHeader',
      studentInfo: 'teacherDashboardPanel/studentInfo',
      conceptCheck: 'teacherDashboardPanel/conceptCheck',
      panelSessionContents: 'teacherDashboardPanel/panelSessionContents',
      getTrackCategory: 'teacherDashboard/getTrackCategory',
      panelProjectContent: 'teacherDashboardPanel/panelProjectContent'
    }),

    footerLinkText () {
      if (this.panelFooter?.icon) {
        return `View ${getGameContentDisplayType(this.panelFooter.icon)}`
      } else {
        return ''
      }
    },

    formattedPracticeThreshold () {
      if (!this.studentInfo.practiceThresholdMinutes) {
        return null
      }
      return secondsToMinutesAndSeconds(this.studentInfo.practiceThresholdMinutes * 60)
    }
  },

  methods: {
    ...mapMutations({
      closePanel: 'teacherDashboardPanel/closePanel',
      setSelectedProgressKey: 'teacherDashboardPanel/setSelectedProgressKey'
    }),

    handleClosePanel () {
      this.closePanel()
      this.setSelectedProgressKey(undefined)
    },

    clickFooterLink () {
      window.tracker?.trackEvent('Track Progress: Progress Modal Footer Link Clicked', { category: this.getTrackCategory, label: this.panelFooter.icon })
    },

    getComponentName (type) {
      switch (type) {
      case 'PRACTICE_LEVEL':
        return 'PracticeLevel'
      case 'CAPSTONE_LEVEL':
        return 'CapstoneLevel'
      case 'DRAGGABLE_ORDERING':
        return 'DraggableOrdering'
      case 'DRAGGABLE_STATEMENT_COMPLETION':
        return 'DraggableStatementCompletion'
      default:
        return null
      }
    }
  }
}
</script>

<template>
  <div
    v-show="isOpen"
    id="panel"
  >
    <div class="header">
      <h3>{{ panelHeader }}</h3>
      <div
        class="close-btn"
        @click="handleClosePanel"
      >
        <img src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Exit.svg">
      </div>
    </div>
    <div class="body">
      <student-info
        :name="studentInfo.name"
        :completed="studentInfo.completedContent"
      />
      <concept-check-info
        v-if="conceptCheck"
        :concept-check="conceptCheck"
        :practice-threshold="formattedPracticeThreshold"
      />
      <component
        :is="getComponentName(panelSessionContent.type)"
        v-for="panelSessionContent in panelSessionContents"
        :key="panelSessionContent.id"
        :panel-session-content="panelSessionContent"
      />
      <ai-scenario
        v-if="panelProjectContent && panelProjectContent.aiScenario"
        :ai-scenario="panelProjectContent.aiScenario"
        :ai-projects="panelProjectContent.aiProjects"
      />
    </div>
    <div class="footer">
      <content-icon
        v-if="panelFooter.icon"
        class="content-icon"
        :icon="panelFooter.icon"
      />
      <a
        :href="panelFooter.url"
        target="_blank"
        @click="clickFooterLink"
      >
        {{ footerLinkText }}
      </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #panel {
    height: 100vh;

    position: fixed;
    right: 0;
    bottom: 0;

    background-color: white;

    z-index: 20000;

    display: flex;
    flex-direction: column;
    justify-content: space-between;

    box-shadow: -10px -10px 30px rgba(0, 0, 0, 0.25), 10px 10px 30px rgba(0, 0, 0, 0.43);
  }

  .close-btn {
    cursor: pointer;
  }

  .header {
    height: 45px;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;

    padding: 0 22px;

    // TODO: Make responsive for screen smaller than 660px wide.
    max-width: 660px;
    width: 660px;

    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

    h3 {
      @include font-p-3-small-button-text-black;
    }
  }

  .body {
    height: 100%;
    flex: 1 1 0px;

    overflow-y: scroll;

    max-width: 660px;
  }

  .footer {
    height: 45px;
    box-shadow: 0px -4px 4px rgba(0,0,0,0.06);

    display: flex;
    justify-content: center;
    align-items: center;

    a {
      font-family: Work Sans;
      font-style: normal;
      font-weight: normal;
      font-size: 16px;
      line-height: 24px;
      letter-spacing: 0.3px;

      color: #413c55;
      cursor: pointer;
      margin: 0 0 0 10px;
    }
  }

  .content-icon {
    width: 25px;
    height: 25px;
  }
</style>
