<script>
import { mapActions, mapGetters, mapState } from 'vuex'

import LoadingProgress from 'views/core/LoadingProgress'
import DashboardTeacherRow from './SchoolAdminTeacherListRow'

export default {

  components: {
    'loading-progress': LoadingProgress,
    'teacher-row': DashboardTeacherRow
  },
  data () {
    return {
      tooltipHtml: () => {
        const t = {}
        for (let i = 1; i < 10; i++) {
          t[i] = $.i18n.t(`school_administrator.totals_explanation_${i}`)
        }
        return `<p><b>${t[1]}</b></p><br><p><b>${t[2]}: </b>${t[3]}</p><br><p><b>${t[4]}: </b>${t[5]}</p><br><p><b>${t[6]}: </b>${t[7]}</p><p><b>${t[8]}: </b>${t[9]}</p>`
      }
    }
  },

  computed: Object.assign(
    {},
    mapState('schoolAdministrator', {
      teachersLoading: s => s.loading.teachers,
      administratedTeachers: s => s.administratedTeachers || []
    }),
    {
      ...mapGetters({
        getStatsByUser: 'userStats/getStatsByUser'
      }),

      groupedTeachers: function () {
        const groupedTeachers = {}

        for (const teacher of this.administratedTeachers) {
          const trialRequest = teacher._trialRequest || {}

          groupedTeachers[trialRequest.organization] = groupedTeachers[trialRequest.organization] || []
          groupedTeachers[trialRequest.organization].push(teacher)
        }

        return Object.freeze(groupedTeachers)
      },

      sortedGroupedAdministratedTeachers () {
        const groupLicenseUsedMap = {}
        const groupNameTeacherArr = []
        for (const [groupName, teachers] of Object.entries(this.groupedTeachers)) {
          let totalUsage = 0
          let enrolledStudents = 0
          for (const teacher of Object.values(teachers)) {
            const usage = teacher?.stats?.licenses?.usage?.used || 0
            teacher.userStats = this.getStatsByUser(teacher._id)
            enrolledStudents += teacher.userStats?.stats?.students?.totalInActiveClassrooms || 0
            totalUsage += usage
          }
          groupLicenseUsedMap[groupName] = totalUsage
          groupNameTeacherArr.push([groupName, teachers, enrolledStudents])
        }
        const sortByLicenseUsedCompare = (grpNameTeacher1, grpNameTeacher2) => {
          return groupLicenseUsedMap[grpNameTeacher1[0]] > groupLicenseUsedMap[grpNameTeacher2[0]] ? -1 : 1
        }
        groupNameTeacherArr.sort(sortByLicenseUsedCompare)

        // sort teachers inside a group based on license usage
        for (const groupNameTeachers of groupNameTeacherArr) {
          const teachers = groupNameTeachers[1]
          teachers.sort((teacher1, teacher2) => {
            const t1Usage = teacher1?.stats?.licenses?.usage?.used || 0
            const t2Usage = teacher2?.stats?.licenses?.usage?.used || 0
            return t1Usage > t2Usage ? -1 : 1
          })
        }
        return groupNameTeacherArr
      },
      me () {
        return me
      },
      outcomesReportUrl () {
        const params = me.isInternal() ? '?newReport=1' : ''
        return `/outcomes-report/school-admin/${me.get('_id')}${params}`
      }
    }
  ),

  created () {
    this.myId = me.get('_id')
    this.fetch()
  },

  methods: mapActions({
    fetch: 'schoolAdministrator/fetchTeachers'
  })
}
</script>

<template>
  <div>
    <h3
      v-if="me.get('_id').toString() === '63034d47767a600023e3b879'"
      style="text-align: right"
    >
      <a :href="'/school-administrator/licenses/stats'"> {{ $t('teacher.license_stats') }}</a>
    </h3>
    <h3>
      <span>{{ $t('school_administrator.my_teachers') }}</span>
      <a
        class="pull-right"
        :href="outcomesReportUrl"
        target="_blank"
      > {{ $t('outcomes.view_outcomes_report') }}</a>
    </h3>

    <loading-progress :loading-status="teachersLoading">
      <div class="content">
        <div
          v-tooltip="{
            content: tooltipHtml(),
            placement: 'top',
            classes: 'school-admin-tooltip',
          }"
          class="class-calculation-description"
        >
          {{ $t("school_administrator.totals_calculated") }}
          <span class="glyphicon glyphicon-question-sign" />
        </div>
        <ul
          v-for="group in sortedGroupedAdministratedTeachers"
          :key="group[0]"
          class="teacher-list"
        >
          <li class="group-title">
            <h4 v-if="group[0]">
              {{ group[0] }}
            </h4>
            <h4 v-else>
              {{ $t('school_administrator.other') }}
            </h4>
          </li>

          <teacher-row
            v-for="teacher in group[1]"
            :key="teacher.id"
            :teacher="teacher"
          />
        </ul>

        <div
          v-if="administratedTeachers.length === 0"
          class="no-teachers"
        >
          {{ $t('school_administrator.no_teachers') }}
        </div>
      </div>

      <div class="school-admin-details">
        {{ $t('school_administrator.add_additional_teacher') }}
      </div>
    </loading-progress>
  </div>
</template>

<style scoped>
    .teacher-list {
        margin: 0;
        margin-top: 15px;

        padding: 0;

        list-style: none;
    }

    .teacher-list .group-title {
        margin-bottom: 15px;
    }

    .school-admin-details {
        margin-top: 35px;

        text-align: center;

        font-size: 13px;
        color: #BBB;
        line-height: 20px;
    }

    .no-teachers {
        padding: 50px;
        text-align: center;
    }

    .class-calculation-description {
      float: right;
    }
</style>

<style lang="sass">
  .tooltip.school-admin-tooltip
    display: block !important
    z-index: 10000
    font-family: 'Open Sans', serif
    font-size: 16px
    border: solid 1px black

    .tooltip-inner
      background: white
      color: black
      border-radius: 1px
      padding: 5px 10px 4px
      min-width: 500px

    &[aria-hidden='true']
      visibility: hidden
      opacity: 0
      transition: opacity .15s, visibility .15s

    &[aria-hidden='false']
      visibility: visible
      opacity: 1
      transition: opacity .15s

    &[x-placement^="top"]
      margin-bottom: 5px

      .tooltip-arrow
        border-width: 5px 5px 0 5px
        border-left-color: transparent !important
        border-right-color: transparent !important
        border-bottom-color: transparent !important
        bottom: -5px
        left: calc(50% - 5px)
        margin-top: 0
        margin-bottom: 0

    &[x-placement^="bottom"]
      margin-top: 5px

      .tooltip-arrow
        border-width: 0 5px 5px 5px
        border-left-color: transparent !important
        border-right-color: transparent !important
        border-top-color: transparent !important
        top: -5px
        left: calc(50% - 5px)
        margin-top: 0
        margin-bottom: 0
</style>
