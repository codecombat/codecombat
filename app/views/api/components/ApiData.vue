<template lang="pug">
  .panel
    h2(v-if="loading") Loading...
    .tab-select
      .tab(@click="tab = 'byMonth'" :class="{active: tab === 'byMonth'}") By Time
      .tab(@click="tab = 'byStudent'" :class="{active: tab === 'byStudent'}") By Student
    template(v-if="tab === 'byMonth'")
      h2(v-if="licenseDaysByMonth && viewport === 'full'") License Days by Month
      table.table.table-condensed(v-if="!licenseStatsLoading && viewport === 'full'")
        tr(class="odd")
          th.month.border {{ $t('library.month') }}
          th.number.border {{ $t('library.license_days_used') }}
          th.number.border {{ $t('library.users_active_licenses') }}
          th.number.border {{ $t('library.new_signups') }}
          th.number.border {{ $t('library.lines_code') }}
          th.number.border {{ $t('library.programs_written') }}
          th.number.border {{ $t('library.time_spent_min') }}
        tr(v-for="(stats, row) in licenseDaysByMonth" :class="{odd: row % 2 == 1, even: row % 2 == 0, sum: stats.month == 'Total'}")
          td.month.border {{stats.month}}
          td.number.border {{stats.licenseDaysUsed.toLocaleString()}}
          td.number.border {{ stats.activeLicenses?.toLocaleString() || '-' }}
          td.number.border {{ stats.newSignups || '-' }}
          td.number.border {{ stats.progress?.linesOfCode || '-' }}
          td.number.border {{ stats.progress?.programs || '-' }}
          td.number.border {{ parseInt(stats.progress?.playtime / 60) || '-' }}

      .age-stats(v-if="ageStats.length > 0")
        d3-bar-chart(:datum="ageStats", :config="this.ageChartConfig()", title="Users Age Split", source="Age ranges")

      h2(v-if="licenseDaysByMonthAndTeacher && viewport=='full'") License Days by Month and Teacher/Classroom
      table.table.table-condensed(v-if="licenseDaysByMonthAndTeacher")
        tr(class="odd")
          th.month.border {{ $t('library.month') }}
          th.name.border {{ $t('library.teacher_classroom_name') }}
          th.number.border {{ $t('library.license_days_used') }}
          th.number.border {{ $t('library.users_active_licenses') }}
        tr(v-for="(stats, row) in licenseDaysByMonthAndTeacher" :class="{odd: row % 2 == 1, even: row % 2 == 0, sum: stats.teacher == 'Total'}")
          td.month.border {{stats.month}}
          td.name.border {{stats.teacher}}
          td.number.border {{stats.licenseDaysUsed.toLocaleString()}}
          td.number.border {{stats.activeLicenses.toLocaleString()}}

    template(v-else)
      license-data-per-user(:loading="loading" :prepaids="prepaids" :teacherMap="teacherMap")

</template>

<script>
import { mapActions, mapState, mapGetters } from 'vuex'
import LicenseDataPerUser from 'app/components/license/LicenseDataPerUser'
import { D3BarChart } from 'vue-d3-charts'
module.exports = Vue.extend({
  components: {
    LicenseDataPerUser,
    D3BarChart
  },
  props: ['viewport'],
  data () {
    return {
      tab: 'byMonth'
    }
  },
  computed: {
    ...mapState('apiClient', {
      licenseStatsLoading: function (s) {
        return s.loading.byLicense
      },
      teacherLoading: function (s) {
        return s.loading.teachers
      },
      licenseStats: function (s) {
        return s.licenseStats
      },
      clientId: function (s) {
        return s.clientId
      },
      clientName: function (s) {
        return me.get('name').replace(/[0-9]*$/g, '')
      },
      createdTeachers: s => s.createdTeachers || []
    }),
    ...mapState('prepaids', {
      prepaidLoading: function (s) {
        return s.loading.byTeacher[this.myId]
      },
      prepaids: function (s) {
        return s.prepaids.byTeacher[this.myId]
      }
    }),
    ...mapGetters(
      'me', [
        'isAnonymous',
        'isAPIClient'
      ]
    ),
    loadingStatuses () {
      return [this.licenseStatsLoading, this.teachersLoading, this.prepaidLoading]
    },
    loading () {
      return this.loadingStatuses.reduce((r, i) => r || i, false)
    },
    teacherMap () {
      const createdTeachers = window._.indexBy(this.createdTeachers, '_id')
      createdTeachers[this.myId] = Object.assign({ _trialRequest: { organization: 'Yourself' } }, me.attributes)
      return createdTeachers
    },
    licenseDaysByMonth () {
      const byMonth = []
      let totalUsed = 0
      const months = _.keys(this.licenseStats.licenseDaysByMonth).sort().reverse()
      for (const month of months) {
        const stat = this.licenseStats.licenseDaysByMonth[month]
        byMonth.push({ month, licenseDaysUsed: stat.daysUsed, activeLicenses: stat.noOfRedeemers, progress: stat.progress, newSignups: stat.newSignups, ageStats: stat.ageStats })
        totalUsed += stat.daysUsed
      }
      if (byMonth.length) {
        byMonth.push({ month: 'Total', licenseDaysUsed: totalUsed })
      }
      return byMonth
    },
    licenseDaysByMonthAndTeacher () {
      const byMonthAndTeacher = []
      let hadMoreThanOne = false
      let months = _.keys(this.licenseStats.licenseDaysByMonth).sort().reverse()
      if (this.viewport != 'full') {
        months = months.slice(0, 1)
      }
      for (const month of months) {
        const stat = this.licenseStats.licenseDaysByMonth[month]
        for (const teacher in stat.teachers) {
          const s = stat.teachers[teacher]
          byMonthAndTeacher.push({ month, teacher, licenseDaysUsed: s.daysUsed, activeLicenses: s.noOfRedeemers })
        }
        if (_.size(stat.teachers) > 1) {
          hadMoreThanOne = true
        }
        byMonthAndTeacher.push({ month, teacher: 'Total', licenseDaysUsed: stat.daysUsed, activeLicenses: stat.noOfRedeemers })
      }
      if (!hadMoreThanOne) {
        return null
      }
      return byMonthAndTeacher
    },
    ageStats () {
      const data = []
      const stats = this.licenseStats?.ageStats
      const totalUsersWithAge = Object.values(this.licenseStats?.ageStats || {})?.reduce((acc, cnt) => acc + cnt, 0)
      for (const age in stats) {
        const ageStr = age === '13-15' ? 'Under 15' : age
        data.push({ ageRange: ageStr, usersNum: stats[age], '% of users': Math.round((stats[age] / totalUsersWithAge) * 100) })
      }
      return data
    }
  },
  methods: {
    ...mapActions({
      fetchLicenseStats: 'apiClient/fetchLicenseStats',
      fetchPlayTimeStats: 'apiClient/fetchPlayTimeStats',
      fetchClientId: 'apiClient/fetchClientId',
      fetchPrepaids: 'prepaids/fetchPrepaidsForAPIClient',
      fetchTeachers: 'apiClient/fetchTeachers'
    }),
    ageChartConfig () {
      return {
        key: 'ageRange',
        values: ['% of users'],
        axis: {
          yTicks: 10,
          yFormat: '.0f',
          yTitle: 'Percentage of users',
          xTitle: 'Age Ranges',
          xFormat: '.0f',
          xTicks: 0
        }
      }
    }
  },
  watch: {
    clientId: function (id) {
      if (id !== '') {
        this.fetchTeachers(id)
        this.fetchPrepaids({ teacherId: this.myId, clientId: id })
        this.fetchLicenseStats(id)
      }
    }
  },
  created () {
    this.myId = me.get('_id')
    const geccId = '61e7e20658f1020024bd8cf7'
    if (this.myId.toString() === geccId) {
      this.tab = 'byStudent'
    }

    this.fetchClientId()
    // current play time for apiclient is the total time of all students so i think
    // we doesn't need it now
    /* this.fetchPlayTimeStats() */
  }
})
</script>

<style lang="scss" scoped>
.panel {
  color: black;
}
.tab-select {
  margin: 10px;
  font-size: 24px;
  font-weight: 400;

  display: flex;
  align-items: center;
  justify-content: space-around;
  background: #eee;

  .tab {
    border-radius: 5px;
    padding: 5px;
    cursor: pointer;

    &.active{
      border: 2px solid black;
    }

  }
}
td.number, th.number {
  padding-right: 1em;
}
th, td {
  text-align: center;
}
tr.odd {
  background-color: rgba(255, 196, 8, 0.1);
}
tr.sum {
  background-color:(rgba(31, 186, 180, 0.2) !important);
}
</style>
