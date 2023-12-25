<script>
import ProgressLabels from '../common/progress/progressLabels'
import StudentRow from './StudentRow'
import { playDevLevel } from 'app/core/urls'
import { broadName } from 'models/User'
import { mapGetters } from 'vuex'

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
      loading: 'teacherDashboard/getLoadingState'
    }),

    sortedMembers () {
      const sortedMembers = [...this.members]
      sortedMembers.sort((a, b) => {
        return broadName(a).localeCompare(broadName(b))
      })
      return sortedMembers
    },

    capstoneSession () {
      return (member) => {
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
          this.levelGoals.forEach((goal) => {
            const goalStatus = {
              goal,
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
          return playDevLevel({ level: this.capstoneLevel, session: capstoneSession })
        } else {
          return ''
        }
      }
    },
    levelGoals () {
      const goals = []
      goals.push(this.capstoneLevel.goals)
      this.capstoneLevel.additionalGoals.forEach(goal => {
        goals.push(goal.goals)
      })
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
