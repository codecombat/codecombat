<script>
  import TeacherDashboardPanel from '../../../store/TeacherDashboardPanel'
  import { mapState, mapMutations } from 'vuex'

  import StudentInfo from './components/StudentInfo'
  import ConceptCheckInfo from './components/ConceptCheckInfo'
  import PracticeLevel from './components/PracticeLevel'
  import CapstoneLevel from './components/CapstoneLevel'
  import DraggableOrdering from './components/DraggableOrdering'
  import InsertCode from './components/InsertCode'
  import DraggableStatementCompletion from './components/DraggableStatementCompletion'

  export default {
    components: {
      StudentInfo,
      ConceptCheckInfo,
      PracticeLevel,
      CapstoneLevel,
      DraggableOrdering,
      DraggableStatementCompletion,
      InsertCode
    },

    computed: {
      ...mapState({
        isOpen: state => state.teacherDashboardPanel.open,
        panelHeader: state => state.teacherDashboardPanel.panelHeader,
        studentInfo: state => state.teacherDashboardPanel.studentInfo,
        conceptCheck: state => state.teacherDashboardPanel.conceptCheck,
        panelSessionContent: state => state.teacherDashboardPanel.panelSessionContent
      })
    },

    beforeCreate () {
      this.$store.registerModule('teacherDashboardPanel', TeacherDashboardPanel)
    },

    destroyed () {
      this.$store.unregisterModule('teacherDashboardPanel')
    },

    methods: {
      ...mapMutations({
        togglePanel: 'teacherDashboardPanel/togglePanel'
      })
    }
  }
</script>

<template>
  <div v-show="isOpen" id="panel">
    <div class="header">
      <h3>{{ panelHeader }}</h3>
      <div
        class="close-btn"
        @click="togglePanel"
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
        :concept-check="conceptCheck"
      />
      <practice-level
        v-if="panelSessionContent && panelSessionContent.type === 'PRACTICE_LEVEL'"
        :panel-session-content="panelSessionContent"
      />
      <capstone-level
        v-if="panelSessionContent && panelSessionContent.type === 'CAPSTONE_LEVEL'"
        :panel-session-content="panelSessionContent"
      />
      <draggable-ordering
        v-if="panelSessionContent && panelSessionContent.type === 'DRAGGABLE_ORDERING'"
        :panel-session-content="panelSessionContent"
      />
      <draggable-statement-completion
        v-if="panelSessionContent && panelSessionContent.type === 'DRAGGABLE_STATEMENT_COMPLETION'"
        :panel-session-content="panelSessionContent"
      />
      <insert-code
        v-if="panelSessionContent && panelSessionContent.type === 'INSERT_CODE'"
        :panel-session-content="panelSessionContent"
      />
    </div>
    <div class="footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #panel {
    height: 698px;

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
  }
</style>
