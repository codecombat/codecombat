<script>
import ProgressLabels from '../common/progress/progressLabels'
import StudentRow from './StudentRow'
import { playDevLevel } from 'app/core/urls'
import { broadName } from 'models/User'
import { mapGetters } from 'vuex'
import utils from 'core/utils'
import _ from 'lodash'

  export default {
    components: {
      'progress-labels': ProgressLabels,
      'student-row': StudentRow
    },
    props: {
      capstoneLevel: {
        type: Object,
        default: () => {}
      },
      levelSessionsByUser: {
        type: Object,
        default: () => {}
      },
      members: {
        type: Array,
        default: () => []
      }
    },
    computed: {
      ...mapGetters({
        getTrackCategory: 'teacherDashboard/getTrackCategory',
        loading: 'teacherDashboard/getLoadingState',
        classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
        selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      }),

      selectedCourse () {
        return this.classroomCourses.find((c) => c._id === this.selectedCourseId) || {}
      },      

    sortedMembers () {
      const sortedMembers = [...this.members]
      sortedMembers.sort((a, b) => {
        return broadName(a).localeCompare(broadName(b))
      })
      return sortedMembers
    },

      capstoneSession () {
        return (member) => {
          // if(utils.isCodeCombat){
          //   if(this.levelSessionsByUser[member._id] ) {
          //     debugger
          //   }
          //   const levelSessions = Object.values(this.levelSessionsByUser[member._id] || {})
          //   const lastLevelSession = _.last(levelSessions)
          //   return lastLevelSession
          // }
          return (this.levelSessionsByUser[member._id] || {})[this.capstoneLevel.original]
        }
      },
      completionStatus () {
        return (member) => {
          const capstoneSession = this.capstoneSession(member)
          if (capstoneSession) {
            if ((capstoneSession.state || {}).complete) {
              return 'complete'
            } else {
              return 'progress'
            }
          } else {
            return ''
          }
        }
      },
      goalStatus () { 
        return (member) => {
          const capstoneSession = this.capstoneSession(member)
          if (capstoneSession && (capstoneSession.state || {}).goalStates) {
            const goalStatusList = []
            if(this.levelGoals && this.levelGoals.length > 0){
              // debugger
            }
            this.levelGoals.forEach((goal) => {
              const goalStatus = {
                goal: goal,
                completed: (capstoneSession.state.goalStates[goal.id] || {}).status === 'success'
              }
              goalStatusList.push(goalStatus)
            })
            return goalStatusList
          } else {
            return []
          }
        }
      },
      sessionCode () {
        return (member) => {
          const capstoneSession = this.capstoneSession(member)
          return (((capstoneSession || {}).code || {})['hero-placeholder'] || {}).plan
        }
      },
      sessionLanguage () {
        return (member) => {
          const capstoneSession = this.capstoneSession(member)
          return (capstoneSession || {}).codeLanguage
        }
      },
      projectUrl () {
        return (member) => {
          const capstoneSession = this.capstoneSession(member)
          if (capstoneSession) {
            return playDevLevel({ level: this.capstoneLevel, session: capstoneSession, course: this.selectedCourse })
          } else {
            return ''
          }
        }
      },
      levelGoals () {
        const goals = []
        console.log('this.capstoneLevel', this.capstoneLevel?.goals)
        console.log('this.capstoneLevel.additionalGoals', this.capstoneLevel?.additionalGoals)
        if(this.capstoneLevel.goals){
          goals.push(this.capstoneLevel.goals)
        }
        if(this.capstoneLevel.additionalGoals){
          this.capstoneLevel.additionalGoals.forEach(goal => {
            goals.push(goal.goals)
          })
        }
        return _.flatten(goals) 
      },
      studentName () {
        return (member) => {
          return broadName(member)
        }
      }
    }
  }
</script>

<template>
  <div v-if="sortedMembers.length">
    <div class="header">
      <progress-labels class="progress-labels" />
    </div>
    <student-row
      v-for="member in sortedMembers"
      :key="member._id"
      :student-name="studentName(member)"
      :status="completionStatus(member)"
      :code="sessionCode(member)"
      :language="sessionLanguage(member)"
      :project-url="projectUrl(member)"
      :goals="goalStatus(member)"
      :track-category="getTrackCategory"
    />
  </div>
  <div v-else-if="!loading">
    <h1 class="capstone-no-students-yet">
      {{ $t('teacher.no_student_assigned') }}
    </h1>
  </div>
  <div v-else>
    <h1 class="capstone-no-students-yet">
      {{ $t('common.loading') }}
    </h1>
  </div>
</template>

<style lang="scss" scoped>
.header {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  align-items: center;
  margin: 20px 0px;
}

.dropdown {
  width: 170px;
}

.progress-labels {
  flex: none;
}

.capstone-no-students-yet {
  margin-top: 50px;
}
</style>
