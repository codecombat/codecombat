<script>
/**
 * Represents the module grid of student sessions.
 * All student solutions get flattened into a list of cells that css grids
 * turns into our table.
 */
  import ProgressDot from '../../common/progress/progressDot'
  import { mapGetters } from 'vuex'
  export default {
    components: {
      ProgressDot
    },
    props: {
      studentSessions: {
        required: true,
        type: Object
      }
    },
    computed: {
      ...mapGetters({
        selectedProgressKey: 'teacherDashboardPanel/selectedProgressKey'
      }),

      cols () {
        return Object.values(this.studentSessions)[0]?.length || 0
      },

      cssVariables () {
        return {
          // This is the width or number of content pieces in the module.
          '--cols': this.cols
        }
      },

      allStudentSessionsLinear () {
        // All student sessions get flattened and then returned as a 1 dimension array.
        return (Object.values(this.studentSessions) || []).flat()
      }
    },
    methods: {
      cellClass (idx) {
        return {
          'gray-backer': Math.floor(idx / this.cols) % 2 === 1,
          'cell-style': true
        }
      },

      getFlag (flag) {
        if (flag === 'concept') {
          return 'red'
        }
        if (flag === 'time') {
          return 'gray'
        }
      }
    }
  }
</script>

<template>
  <div class="moduleGrid" :style="cssVariables">
    <!-- FLAT REPRESENTATION OF ALL SESSIONS -->
    <div :class="cellClass(index)" v-for="({ status, flag, clickHandler, selectedKey, normalizedType, isLocked }, index) of allStudentSessionsLinear" :key="selectedKey">
      <ProgressDot
        :status="status"
        :border="getFlag(flag)"
        :click-progress-handler="clickHandler"
        :click-state="selectedProgressKey && selectedProgressKey === selectedKey"
        :content-type="normalizedType"
        :isLocked="isLocked"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .moduleGrid {
    display: grid;
    grid-template-columns: repeat(var(--cols), 28px);
    grid-template-rows: repeat(auto, 38px);

    border-right: 2px solid #d8d8d8;
  }

  .gray-backer {
    background-color: #f2f2f2;
  }

  .cell-style {
    border-bottom: 1px solid #d8d8d8;
    height: 29px;
  }
</style>
