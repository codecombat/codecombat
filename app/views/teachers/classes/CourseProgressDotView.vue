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
        font-size: 14px;
        font-weight: bold;

        line-height: 20px;

        background-color: rgb(153, 153, 153);
    }

    .progress-dot.started {
        background-color: #F2BE19;
    }

    .progress-dot.completed {
        background-color: #20572B;
    }
</style>

<style>
    .course-dot-progress-tooltip {
        z-index: 2000;
    }

    .course-dot-progress-tooltip .tooltip-inner {
        background-color: #FFF;
        color: #0E4C60;
        border: 1px solid #0E4C60;
        border-radius: 20px;
        padding: 10px 20px;
        font-size: 15px;
        line-height: 1.4;
    }

    .course-dot-progress-tooltip .arrow {
        width: 0;
        height: 0;
        border-style: solid;
        position: absolute;
        margin: 5px;
        border-color: #0E4C60;

        border-width: 5px 10px 0 10px;
        border-left-color: transparent !important;
        border-right-color: transparent !important;
        border-bottom-color: transparent !important;
        bottom: -5px;
        left: calc(50% - 10px);

        margin-top: 0;
        margin-bottom: 0;
    }

    .course-dot-progress-tooltip .arrow::after {
        content: ' ';

        width: 0;
        height: 0;
        border-style: solid;
        position: absolute;
        border-color: #FFF;

        border-width: 5px 10px 0 10px;
        border-left-color: transparent !important;
        border-right-color: transparent !important;
        border-bottom-color: transparent !important;
        top: -6px;
        left: calc(50% - 10px);

        margin-top: 0;
        margin-bottom: 0;
    }
</style>

<template>
    <li>
        <v-popover
                popover-base-class="course-dot-progress-tooltip"
                popover-arrow-class="arrow"
                trigger="hover"
                placement="top"
                :open-group="`${classroom._id}${course._id}`"
        >
            <div :class="[ 'progress-dot', { started: courseStarted, completed: courseCompleted } ]">
                {{ courseAcronym }}
            </div>

            <template slot="popover">
                <span v-if="levelSessionsLoading">
                    {{ $t('common.loading') }}
                </span>
                <div v-else>
                    {{ courseStats.studentsCompletingAllLevels }} / {{ classroom.members.length }}
                    {{ $t('courses.students')}}
                    <br />
                    {{ percentCompleted }}%
                    {{ $t('teacher.completed') }}
                </div>
            </template>
        </v-popover>
    </li>
</template>

<script>
  import { mapState } from 'vuex'

  import { courseAcronyms as COURSE_ACRONYMS } from 'core/utils'

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
          return COURSE_ACRONYMS[this.$props.course._id]
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

        // Port of course stat calculation in TeacherClassesView.coffee.  This should be moved into
        // background processor and the new stats should be displayed here and in TeacherClassesView.
        //
        // See https://github.com/codecombat/codecombat/pull/5191#discussion_r276024733 for additiona
        // implementations in Claassroom.coffee that may help.
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
            this.courseStats.totalLevelsCompleted / (courseMembers.length * this.courseLevels.length) * 100,
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
