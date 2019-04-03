<style scoped>
    .progress-dot {
        display: flex;
        align-items: center;
        justify-content: center;

        margin: 10px;

        width: 62px;
        height: 62px;

        border-radius: 50%;

        color: #FFF;
        font-size: 18px;

        background-color: rgb(153, 153, 153);
    }

    .progress-dot.started {
        background-color: #F2BE19;
    }

    .progress-dot.completed {
        background-color: #20572B;
    }
</style>

<template>
    <li>
        <v-popover
                popoverBaseClass="v-tooltip"
                trigger="hover"
                placement="top"
                :open-group="`${classroom._id}${course._id}`"
        >
            <div :class="[ 'progress-dot', { started: courseStarted, completed: courseCompleted } ]">
                {{ courseAcronym }}
            </div>

            <template slot="popover">
                {{ courseStats }}
            </template>
        </v-popover>
    </li>
</template>

<script>
  import { mapState } from 'vuex'

  export default {
    props: {
      course: Object,
      classroom: Object,
    },

    computed: Object.assign({},
      // TODO this could be loading (top level component prevents this now but may not in future).  Handle loading state here
      mapState('courses', {
        courses: function (state) {
          return state.byId
        }
      }),

      mapState('courseInstances', {
        // TODO this could be loading (top level component prevents this now but may not in future).  Handle loading state here
        courseInstancesLoading (state) {
          return state.loading.byTeacher[this.$props.classroom.ownerID]
        },

        courseInstance (state) {
          const instances = state.courseInstancesByTeacher[this.$props.classroom.ownerID] || []

          return instances
            .find(i => i.courseID === this.$props.course._id && i.classroomID === this.$props.classroom._id)
        }
      }),

      mapState('levelSessions', {
        // TODO this could be loading (top level component prevents this now but may not in future).  Handle loading state here
        levelSessionsLoading (state) {
          return state.loading.sessionsByClassroom[this.$props.classroom._id]
        },

        levelCompletionsByUser (state) {
          const levelSessionState = state.levelSessionsByClassroom[this.$props.classroom._id]

          if (levelSessionState) {
            return levelSessionState.levelCompletionsByUser
          }

          return {}
        }
      }),

      {
        // TODO course acronym could be controlled and sent from the backend
        courseAcronym: function () {
          const course = this.courses[this.$props.course._id]

          let prefix = 'CS';
          if (/game-dev/.test(course.slug)) {
            prefix = 'GD'
          } else if (/web-dev/.test(course.slug)) {
            prefix = 'WD'
          }

          let number = '1';
          const numberMatch = (course.slug || '').match(/(\d+)$/)
          if (numberMatch && numberMatch[1]) {
            number = numberMatch[1]
          }

          return `${prefix}${number}`
        },

        // TODO this should be moved to a stats store, calculated on the backend, or some combination of the two
        courseLevels: function () {
          const classroom = this.$props.classroom
          const course = (classroom.courses || []).find(c => c._id === this.$props.course._id)

          if (!course || !course.levels) {
            return []
          }

          return course.levels
              .filter(l => !l.practice && !l.assessment)
              .map(l => l.original)
        },

        courseStats: function () {
          const levelCompletionsByUser = this.levelCompletionsByUser
          const courseLevels = this.courseLevels
          const courseInstance = this.courseInstance || {}
          const courseMembers = courseInstance.members || [];

          let courseStarted = false
          let levelsCompleted = 0
          let studentsCompletingAllLevels = 0

          if (Object.keys(levelCompletionsByUser).length > 0 && courseLevels.length > 0 && courseMembers.length > 0) {
            // Calculate stats for each member
            for (const memberId of courseMembers) {
              // If there are no user stats there is nothing to calculate
              if (!levelCompletionsByUser[memberId]) {
                continue
              }

              // Calculate all levels completed for current user and add user stats to running totals
              let allLevelsCompleted = true
              for (const levelId of courseLevels) {
                const levelCompletion = levelCompletionsByUser[memberId][levelId]
                const levelCompletedByUser = (levelCompletion === true)

                if (typeof levelCompletion !== 'undefined') {
                  courseStarted = true
                }

                if (levelCompletedByUser) {
                  levelsCompleted += 1
                } else {
                  allLevelsCompleted = false
                }
              }

              if (allLevelsCompleted) {
                studentsCompletingAllLevels += 1
              }
            }
          }

          // TODO WIRE THIS UP TO UI
          return {
            started: courseStarted,
            totalLevelsCompleted: levelsCompleted,
            studentsCompletingAllLevels
          }
        },

        courseStarted: function () {
          return this.courseStats.started
        },

        percentCompleted: function () {
          const courseMembers = this.courseInstance.members || []

          return parseInt(
            this.courseStats.levelsCompleted / (courseMembers.length * this.courseLevels.length) * 100,
            10
          )
        },

        courseCompleted: function () {
          const courseMembers = this.courseInstance.members || []
          return this.courseStats.studentsCompletingAllLevels === courseMembers.length
        }
      })
  }
</script>
