<script>
  /**
   * A classrooms progress table.
   * TODO: Connect to a Vuex store.
   */

  import TableModuleHeader from './TableModuleHeader'
  import TableModuleGrid from './TableModuleGrid'
  import TableStudentList from './TableStudentList'
  import ScrollArrow from '../customButtons/ScrollArrow'

  // --REMOVE_MOCK START
  const mockGenerateStudentSessions = (length) => {
    const sessions = []
    let completed = 3
    for (let i = 0; i < length; i++) {
      const mockSession = {}
      if (completed === 3) {
        mockSession.status = 'complete'
      } else if (completed === 2) {
        mockSession.status = 'progress'
      } else {
        mockSession.status = 'assigned'
      }
      if (Math.random() < 0.1) {
        completed--
      }

      if (Math.random() < 0.03 && mockSession.status === 'complete') {
        if (Math.random() < 0.5) {
          mockSession.flag = 'concept'
        } else {
          mockSession.flag = 'time'
        }
      }
      sessions.push(mockSession)
    }
    return sessions
  }

  const mockGenerateContentTypes = (length) => {
    const contentList = []
    for (let i = 0; i < length; i++) {
      const contentType = {
        type: ['cutscene', 'cinematic', 'capstone', 'practicelvl', 'challengelvl', 'interactive'][Math.floor(Math.random() * 6)]
      }
      contentType.displayName = `${contentType.type}: Display Name`
      contentType.description = `Description of ${contentType.type}. Some more description`
      contentList.push(contentType)
    }
    return contentList
  }

  const NUM_STUDENTS = 60

  const mockGenerateModule = (length, name) => {
    const MOCK_DATA = {
      displayName: name,
      contentList: mockGenerateContentTypes(length),
      studentSessions: {},
      classSummaryProgress: mockGenerateStudentSessions(length) // This will need to be crunched from the student sessions in Vuex.
    }
    for (let i = 1; i <= NUM_STUDENTS; i++) {
      MOCK_DATA.studentSessions[`Student ${i}`] = mockGenerateStudentSessions(length)
    }
    return MOCK_DATA
  }

  const mockGenerateStudentNames = () => {
    const STUDENT_NAMES = []
    for (let i = 1; i <= NUM_STUDENTS; i++) {
      STUDENT_NAMES.push({
        displayName: `Student ${i}`,
        checked: false
      })
    }
    return STUDENT_NAMES
  }
  // --REMOVE_MOCK END

  export default {
    components: {
      'table-module-header': TableModuleHeader,
      'table-module-grid': TableModuleGrid,
      'table-student-list': TableStudentList,
      ScrollArrow
    },
    data: () => ({
      students: mockGenerateStudentNames(),
      modules: [
        mockGenerateModule(19, 'Module 1: Algorithms & Syntax'),
        mockGenerateModule(15, 'Module 2: Debugging'),
        mockGenerateModule(30, 'Module 3: Loops'),
        mockGenerateModule(23, 'Module 4: Debugging and Loops')
      ]
    }),

    methods: {
      scrollRight () {
        $('#classTableFrame').animate({ scrollLeft: '+=400px' })
      },
      scrollLeft () {
        $('#classTableFrame').animate({ scrollLeft: '-=400px' })
      }
    }
  }
</script>

<template>
  <div id="outer-container">
    <div id="classTableFrame">
      <div id="stickyHeader">
        <div class="flex-container">
          <div class="leftOfHeader">
            <scroll-arrow :face-left="true" @click="scrollLeft()" />
            <div class="allStudents">
              <input type="checkbox">
              <p>All Students</p>
            </div>
          </div>

          <!-- Module Headers -->
          <table-module-header
            v-for="({ displayName, contentList, classSummaryProgress }) of modules"

            :key="`${displayName}`"
            :module-heading="displayName"
            :list-of-content="contentList"
            :class-summary-progress="classSummaryProgress"
          />
        </div>
      </div>
      <div class="size-container">
        <div class="table-row">
          <table-student-list :students="students" />

          <!-- List of student solutions per module -->
          <table-module-grid
            v-for="({ studentSessions, displayName }) of modules"
            :key="displayName"
            :student-sessions="studentSessions"
          />

          <!-- Fade on the right to signal more -->
          <div class="fade-out" />
        </div>
      </div>
    </div>
    <scroll-arrow class="arrow" @click="scrollRight()" />
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#outer-container {
  position: relative;

  & .arrow {
    position: absolute;
    top: 36px;
    right: 28px;
  }
}

#classTableFrame {
  width: calc(100vw - 70px);
  max-height: calc(100vh - 320px);
  overflow-y: scroll;
  overflow-x: scroll;
  margin: 22px 70px 22px 0;
}

.table-row {
  display: flex;
  flex-direction: row;
}

/*
 Required or flex box will shrink to fit in overflow
 which messes up sticky header and student row.
*/
.size-container {
  display: inline-block;
}

#stickyHeader {
  display: inline-block;
  position: sticky;
  position: -webkit-sticky; /* Safari */
  top: 0;
  z-index: 10;

  background-color: white;

  & .flex-container {
    display: flex;
    flex-direction: row;
    align-items: flex-end;
  }

  .leftOfHeader {
    width: 190px;
    min-width: 190px;
    height: 116px;

    position: sticky;
    position: -webkit-sticky; /* Safari */
    left: 0;

    background-color: white;

    display: flex;
    flex-direction: column;
    justify-content: flex-end;
    align-items: flex-end;
  }
}

.allStudents {
    display: flex;
    flex-direction: row;

    width: 190px;
    min-width: 190px;
    height: 38px;
    margin-bottom: 1px;

    padding: 0 0 0 30px;
    background-color: #fff9e3;
    border: 1px solid #c2a957;

    justify-content: normal;
    align-items: center;

    p, input {
      margin: 0;
    }

    p {
      margin-left: 10px;

      @include font-p-4-paragraph-smallest-gray;
      font-weight: 600;
      color: black;
    }
  }

  .fade-out {
    width: 80px;

    position: sticky;
    position: -webkit-sticky; /* Safari */
    right: 0;

    background: linear-gradient(270deg, rgba(205, 205, 204, 0.79) 0%, rgba(196, 196, 196, 0) 100%);
  }
</style>
