<template lang="pug">
  .container
    .row
      .col-xs-12
        h1
          span API Dashboard - {{clientName}}

        h2(v-if="licenseStatsLoading") Loading...
        h2(v-else="licenseDaysByMonth") License Days by Month
        table.table.table-condensed(v-if="!licenseStatsLoading")
           tr(class="odd")
             th.border Month
             th.border License days used
             th.border Users with active licenses
           tr(v-for="(stats, row) in licenseDaysByMonth" :class="{odd: row % 2 == 1, even: row % 2 == 0, sum: stats.month == 'Total'}")
             td.border {{stats.month}}
             td.border {{stats.licenseDaysUsed.toLocaleString()}}
             td.border(v-if="stats.activeLicenses") {{stats.activeLicenses.toLocaleString()}}

        h2(v-if="licenseDaysByMonthAndTeacher") License Days by Month and Teacher/Classroom
        table.table.table-condensed(v-if="licenseDaysByMonthAndTeacher")
           tr(class="odd")
             th.border Month
             th.border Teacher or classroom name
             th.border License days used
             th.border Users with active licenses
           tr(v-for="(stats, row) in licenseDaysByMonthAndTeacher" :class="{odd: row % 2 == 1, even: row % 2 == 0, sum: stats.teacher == 'Total'}")
             td.border {{stats.month}}
             td.border {{stats.teacher}}
             td.border {{stats.licenseDaysUsed.toLocaleString()}}
             td.border {{stats.activeLicenses.toLocaleString()}}
</template>

<script>
  import { mapActions, mapState, mapGetters } from 'vuex'
  module.exports = Vue.extend({
    computed: {
      ...mapState('apiClient', {
        licenseStatsLoading: function (s) {
          return s.loading.byLicense
        },
        licenseStats: function (s) {
          return s.licenseStats
        },
        clientId: function (s) {
          return s.clientId
        },
        clientName: function (s) {
          return me.get('name').replace(/[0-9]*$/g, '')
        }
      }),
      ...mapGetters(
        'me', [
          'isAnonymous',
          'isAPIClient'
        ]
      ),
      licenseDaysByMonth() {
        let byMonth = []
        let totalUsed = 0
        let months = _.keys(this.licenseStats.licenseDaysByMonth).sort()
        for(let month of months) {
          let stat = this.licenseStats.licenseDaysByMonth[month]
          byMonth.push({month, licenseDaysUsed: stat.daysUsed, activeLicenses: stat.noOfRedeemers})
          totalUsed += stat.daysUsed
        }
        if (byMonth.length) {
          byMonth.push({month: 'Total', licenseDaysUsed: totalUsed})
        }
        return byMonth
      },
      licenseDaysByMonthAndTeacher() {
        let byMonthAndTeacher = []
        let hadMoreThanOne = false
        let months = _.keys(this.licenseStats.licenseDaysByMonth).sort()
        for(let month of months) {
          let stat = this.licenseStats.licenseDaysByMonth[month]
          for(let teacher in stat.teachers) {
            let s = stat.teachers[teacher]
            byMonthAndTeacher.push({month, teacher, licenseDaysUsed: s.daysUsed, activeLicenses: s.noOfRedeemers})
          }
          if (_.size(stat.teachers) > 1) {
            hadMoreThanOne = true
          }
          byMonthAndTeacher.push({month, teacher: 'Total', licenseDaysUsed: stat.daysUsed, activeLicenses: stat.noOfRedeemers})
        }
        if (!hadMoreThanOne) {
          return null
        }
        return byMonthAndTeacher
      }
    },
    methods: {
      ...mapActions({
          fetchLicenseStats: 'apiClient/fetchLicenseStats',
          fetchPlayTimeStats: 'apiClient/fetchPlayTimeStats',
          fetchClientId: 'apiClient/fetchClientId'
      })
    },
    watch: {
      clientId: function (id) {
        if(id != '') {
          this.fetchLicenseStats(id)
        }
      }
    },
    created() {
      if(!this.isAPIClient) {
        window.location.href = '/'
      }
      this.fetchClientId()
      // current play time for apiclient is the total time of all students so i think
      // we doesn't need it now
      /* this.fetchPlayTimeStats() */
    }
  })
</script>

<style lang="scss" scoped>
  tr.odd {
    background-color: rgba(255, 196, 8, 0.1);
  }
  tr.sum {
    background-color:(rgba(31, 186, 180, 0.2) !important);
  }
</style>
