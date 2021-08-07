<script>
  /**
   * A classrooms progress table.
   * TODO: Connect to a Vuex store.
   */

  import { mapGetters } from 'vuex'
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
      },
      displayOnly: {
        type: Boolean,
        default: false
      }
    },

    data: () => ({
      isTouchingRight: false,
      isTouchingLeft: false
    }),

    computed: {
      ...mapGetters({
        selectedStudentIds: 'baseSingleClass/selectedStudentIds'
      }),
      getStudentSessionsData() {
        return this.modules.map(m => {
          return { moduleNum: m.moduleNum, studentSessions: m.studentSessions }
        })
      }
    },
    watch: {
      // Use this to trigger attaching the scroll callback
      // as the table is changing width.
      modules (newModules, lastModules) {
        const table = $('#classTableFrame')
        table.off('scroll')
        table.scroll(this.debouncedDetectMaxScrolledRight)

        this.debouncedDetectMaxScrolledRight()
      }
    },

    mounted () {
      this.debouncedDetectMaxScrolledRight = _.debounce(this.detectMaxScrolledRight, 100)
    },

    beforeDestroy () {
      $('#classTableFrame').off('scroll')
    },

    methods: {
      scrollRight () {
        $('#classTableFrame').animate({ scrollLeft: '+=400px' })
      },

      scrollLeft () {
        $('#classTableFrame').animate({ scrollLeft: '-=400px' })
      },

      detectMaxScrolledRight () {
        const table = $('#classTableFrame')
        this.isTouchingRight = table.scrollLeft() + table.innerWidth() >= table[0].scrollWidth
        this.isTouchingLeft = table.scrollLeft() <= 0.1
      },

      lockModule (moduleNum) {
        this.$emit('lock', { moduleNum })
      },

      unlockModule (moduleNum) {
        this.$emit('unlock', { moduleNum })
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
            <scroll-arrow
              :face-left="true"
              :inactive="isTouchingLeft"

              @click="scrollLeft()"
            />
            <div class="allStudents">
              <input
                type="checkbox"
                :checked="selectedStudentIds.length > 0 && selectedStudentIds.length === students.length"
                @change="e => $emit('toggle-all-students', e)"
              >
              <p>{{ $t('teacher.all_students') }}</p>
            </div>
          </div>

          <!-- Module Headers -->
          <table-module-header
            v-for="({ displayName, contentList, classSummaryProgress, moduleNum }) of modules"

            :key="`${displayName}`"
            :module-heading="displayName"
            :list-of-content="contentList"
            :class-summary-progress="classSummaryProgress"
            :display-only="displayOnly"

            @lock="lockModule(moduleNum)"
            @unlock="unlockModule(moduleNum)"
          />
        </div>
      </div>
      <div class="size-container">
        <div class="table-row">
          <table-student-list :students="students" :student-sessions-data="getStudentSessionsData" />

          <!-- List of student solutions per module -->
          <table-module-grid
            v-for="({ studentSessions, displayName }) of modules"
            :key="displayName"
            :student-sessions="studentSessions"
          />

          <!-- Fade on the right to signal more -->
          <div class="fade-out" :class="isTouchingRight ? 'hidden' : ''" />
        </div>
      </div>
    </div>
    <scroll-arrow
      class="arrow"
      :inactive="isTouchingRight"

      @click="scrollRight()"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#outer-container {
  position: relative;

  display: flex;
  justify-content: center;

  margin-top: 22px;
  overflow: hidden;

  & .arrow {
    position: absolute;
    top: 36px;
    right: 28px;
  }
}

#classTableFrame {
  width: calc(100vw - 70px);
  min-height: 560px;
  height: calc(100vh - 100px);
  /* Ensures that table never gets too wide. */
  max-width: 1850px;
  overflow-y: scroll;
  overflow-x: scroll;
  margin: 0 70px 22px 0;

  /* Counters the huge margin making space for tooltips */
  /* We also have to float everything on the page over this space */
  margin-top: $anti-tooltip-spacing;
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

  /*
    This is required to make room for the tooltips to appear on top.
    We then negate this from the parent container with a negative margin.
    The tooltips can now display above this header.
    Removing this will make all the tooltips drop to below as they will think
    they are being rendered off the top of the screen.
  */
  padding-top: $tooltip-spacing;

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

    /* Ensure that this sits in front of other content. */
    z-index: 2;
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
    margin-left: -80px; /* Prevents div protruding */
    opacity: 1;

    position: sticky;
    position: -webkit-sticky; /* Safari */
    right: 0;

    background: linear-gradient(270deg, rgba(205, 205, 204, 0.79) 0%, rgba(196, 196, 196, 0) 100%);
  }

  .fade-out.hidden {
    opacity: 0;
  }
</style>
