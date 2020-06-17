<script>
  /**
   * A classrooms progress table.
   * TODO: Connect to a Vuex store.
   */

  import TableModuleHeader from './TableModuleHeader'
  import TableModuleGrid from './TableModuleGrid'
  import TableStudentList from './TableStudentList'
  import ScrollArrow from '../../common/buttons/ScrollArrow'

  export default {
    components: {
      'table-module-header': TableModuleHeader,
      'table-module-grid': TableModuleGrid,
      'table-student-list': TableStudentList,
      ScrollArrow
    },
    props: {
      // Order that students appear in the table.
      students: {
        type: Array,
        required: true
      },
      modules: {
        type: Array,
        required: true
      }
    },

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
              <input
                type="checkbox"

                @change="e => $emit('toggle-all-students', e)"
              >
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
    width: $studentNameWidth;
    min-width: $studentNameWidth;
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

    width: $studentNameWidth;
    min-width: $studentNameWidth;
    height: 38px;
    margin-bottom: 1px;

    padding: 0 0 0 20px;
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
