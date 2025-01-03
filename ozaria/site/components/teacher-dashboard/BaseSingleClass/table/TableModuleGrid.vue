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
    ProgressDot,
  },
  props: {
    studentSessions: {
      required: true,
      type: Object,
    },
    hoveredLevels: {
      required: false,
      type: Array,
      default: () => [],
    },
    moduleNumber: {
      required: false,
      type: [Number, String],
      default: null,
    },
  },
  computed: {
    ...mapGetters({
      selectedProgressKey: 'teacherDashboardPanel/selectedProgressKey',
      getTrackCategory: 'teacherDashboard/getTrackCategory',
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      selectedOriginals: 'baseSingleClass/selectedOriginals',
      getContentForClassroom: 'gameContent/getContentForClassroom',
      classroomId: 'teacherDashboard/classroomId',
      getLevelSessionMap: 'levelSessions/getSessionsMapForClassroom',
      courseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      collapsedModules: 'teacherDashboard/getCollapsedModulesForCurrentCourse',

    }),

    collapsed () {
      return this.collapsedModules.includes(this.moduleNumber)
    },

    classroomGameContent () {
      return this.getContentForClassroom(this.classroomId)
    },

    levelSessionMap () {
      return this.getLevelSessionMap(this.classroomId)
    },

    cols () {
      return Object.values(this.studentSessions)[0]?.length || 0
    },

    cssVariables () {
      return {
        // This is the width or number of content pieces in the module.
        '--cols': this.cols,
        '--columnWidth': this.cols > 2 ? '28px' : (this.cols > 1 ? '42px' : '84px'),
      }
    },

    allStudentSessionsLinear () {
      // All student sessions get flattened and then returned as a 1 dimension array.
      return Object.entries(this.studentSessions).reduce((acc, [studentId, studentSessions]) => {
        return acc.concat(studentSessions.map(session => {
          return {
            ...session,
            studentId,
          }
        }))
      }, [])
    },
  },
  methods: {
    extraPracticeLevels (normalizedOriginalX, studentId) {
      const classroomsContent = this.classroomGameContent
      if (!classroomsContent) {
        return []
      }
      const courseId = this.courseId

      if (!classroomsContent || !courseId) {
        return []
      }

      const level = classroomsContent[courseId]?.modules[this.moduleNumber]?.find(content => {
        const { original, fromIntroLevelOriginal } = content
        const normalizedOriginal = original || fromIntroLevelOriginal
        return normalizedOriginal === normalizedOriginalX
      })

      if (level?.practiceLevels) {
        const sessionMap = this.levelSessionMap
        const sessions = sessionMap[studentId]

        if (sessions) {
          return level.practiceLevels.map(level => {
            const session = sessions[level.original]

            return {
              ...level,
              inProgress: Boolean(session),
              isCompleted: Boolean(session?.dateFirstCompleted),
            }
          })
        }
      }

      return level?.practiceLevels || []
    },
    cellClass (idx) {
      return {
        'gray-backer': Math.floor(idx / this.cols) % 2 === 1,
        'cell-style': true,
      }
    },

    getFlag (flag) {
      if (['concept', 'unsafe'].includes(flag)) {
        return 'red'
      }
      if (flag === 'time') {
        return 'gray'
      }
    },
  },
}
</script>

<template>
  <div
    class="moduleGrid"
    :class="{'collapsed': collapsed}"
    :style="cssVariables"
  >
    <!-- FLAT REPRESENTATION OF ALL SESSIONS -->
    <div
      v-for="({studentId, status, playTime, tooltipName, playedOn, completionDate, flag, clickHandler, selectedKey, normalizedType, isLocked, isSkipped, lockDate, lastLockDate, original, normalizedOriginal,fromIntroLevelOriginal, isPlayable, isOptional }, index) of allStudentSessionsLinear"
      :key="selectedKey"
      :class="cellClass(index)"
    >
      <ProgressDot
        :status="status"
        :border="getFlag(flag)"
        :click-progress-handler="clickHandler"
        :click-state="selectedProgressKey && selectedProgressKey === selectedKey"
        :content-type="normalizedType"
        :is-locked="isLocked"
        :is-skipped="isSkipped"
        :lock-date="lockDate"
        :is-playable="isPlayable"
        :last-lock-date="lastLockDate"
        :is-optional="isOptional"
        :track-category="getTrackCategory"
        :selected="selectedOriginals.includes(normalizedOriginal) && selectedStudentIds.includes(studentId)"
        :hovered="hoveredLevels.includes(normalizedOriginal) && selectedStudentIds.includes(studentId)"
        :play-time="playTime"
        :played-on="playedOn"
        :completion-date="completionDate"
        :tooltip-name="tooltipName"
        :normalized-original="normalizedOriginal"
        :module-number="moduleNumber"
        :student-id="studentId"
        :classroom-game-content="classroomGameContent"
        :level-session-map="levelSessionMap"
        :extra-practice-levels="extraPracticeLevels(normalizedOriginal, studentId)"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .moduleGrid {
    display: grid;
    grid-template-columns: repeat(var(--cols), var(--columnWidth));
    grid-template-rows: repeat(auto, 38px);

    border-right: 2px solid #d8d8d8;
  }

  .gray-backer {
    background-color: #f2f2f2;
  }

  .cell-style {
    border-bottom: 1px solid #d8d8d8;
    height: 29px;
    display: flex;
    justify-content: center;
  }

  .collapsed {
    width: 20px;
    min-width: 20px;
    > * {
      display: none;
    }
    border-bottom: 1px solid #d8d8d8;
  }
</style>
