<script>
  import { mapActions, mapState } from 'vuex'

  export default {
    props: {
      teacher: {
        type: Object,
        default: () => ({})
      }
    },

    computed: Object.assign(
      {},
      mapState('classrooms', {
        classroomsLoading: function (s) {
          return s.loading.byTeacher[this.$props.teacher._id]
        },

        activeClassrooms: function (s) {
          const classrooms = s.classrooms.byTeacher[this.$props.teacher._id] || {}
          return classrooms.active || []
        },

        classroomStats: function () {
          let totalStudentCount = 0
          let activeStudentCount = 0
          let totalProjectsCreated = 0

          this.activeClassrooms.forEach((classroom) => {
            const classroomStats = classroom.stats || {}
            const studentStats = classroomStats.students || {}
            const studentCountStats = studentStats.count || {}

            const activeStudents = studentCountStats.active || 0
            const inactiveStudents = studentCountStats.inactive || 0
            const projectsCreated = classroomStats.projectsCreated || 0

            totalStudentCount += activeStudents + inactiveStudents
            activeStudentCount += activeStudents
            totalProjectsCreated += projectsCreated
          })

          return {
            totalStudents: totalStudentCount,
            activeStudents: activeStudentCount,
            projectsCreated: totalProjectsCreated
          }
        },

        teacherLastLogin: function () {
          const teacher = this.$props.teacher || {}
          const teacherActivity = teacher.activity || {}
          const loginActivity = teacherActivity.login || {}

          return loginActivity.last
        },

        licenseStats: function () {
          const teacherStats = this.$props.teacher.stats || {}
          const licenseStats = teacherStats.licenses || {}
          const usageStats = licenseStats.usage || {}

          return {
            licensesUsed: usageStats.used || 0,
            licensesTotal: usageStats.total || 0
          }
        }
      })
    ),

    created () {
      this.fetchClassroomsForTeacher(this.$props.teacher._id)
    },

    methods: mapActions({
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher'
    }),
  }
</script>

<style scoped>
    .teacher-row {
        display: flex;
        flex-direction: row;
        align-items: center;

        padding: 15px;

        height: 100px;

        line-height: normal;
    }

    .teacher-row:nth-child(2n) {
        background-color: #F5F5F5;
    }

    .teacher-row:nth-child(2n + 1) {
        background-color: #EBEBEB;
    }

    .teacher-info {
        width: 25%;
        flex-grow: 0;
        flex-shrink: 0;

        display: flex;
        flex-direction: column;

        justify-content: center;
    }

    .teacher-email {
        display: block;
        color: #000;

        text-decoration: underline;
        font-size: 18px
    }

    .last-login {
        font-size: 14px
    }

    .stats {
        flex-grow: 1;

        display: flex;
        flex-direction: row;

        align-items: center;
        justify-content: center;

        list-style: none;

        padding: 0;
    }

    .stats li {
        text-align: center;
        font-size: 12px;

        width: 140px
    }

    .stats li span {
        display: block;

        font-size: 24px;
    }

    .dashboard-link {
        margin-left: auto;
        color: #999;

        line-height: normal;
    }

    .dashboard-link:hover {
        text-decoration: none;
    }

    .stat-hidden {
        visibility: hidden;
    }
</style>

<template>
  <li class="teacher-row">
    <div class="teacher-info">
      <h4>{{ teacher.firstName }} {{ teacher.lastName }}</h4>
      <a class="teacher-email" :href="`mailto:${teacher.email}`">{{ teacher.email }}</a>

      <div class="last-login">
        <span>{{ $t('school_administrator.last_login') }}:</span>
        <span v-if="teacherLastLogin">{{ teacherLastLogin | moment("dddd, MMMM Do YYYY") }}</span>
      </div>
    </div>

    <ul class="stats">
      <li>
        <span>{{ licenseStats.licensesUsed }} / {{ licenseStats.licensesTotal }}</span>
        {{ $t('school_administrator.licenses_used') }}
      </li>

      <li>
        <span :class="{ 'stat-hidden': classroomsLoading }">{{ classroomStats.totalStudents }}</span>
        {{ $t('school_administrator.total_students') }}
      </li>

      <li>
        <span :class="{ 'stat-hidden': classroomsLoading }">{{ classroomStats.activeStudents }}</span>
        {{ $t('school_administrator.active_students') }}
      </li>

      <li>
        <span :class="{ 'stat-hidden': classroomsLoading }">{{ classroomStats.projectsCreated }}</span>
        {{ $t('school_administrator.projects_created') }}
      </li>
    </ul>

    <router-link
      class="dashboard-link glyphicon glyphicon-chevron-right"
      :to="`/school-administrator/teacher/${teacher._id}`"
    />
  </li>
</template>
