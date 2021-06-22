<template lang="pug">
  #api-dashboard
   h1
     | api-dashboard
   table.table.table-condensed(v-if="licenseDaysByMonthAndTeacher")
      tr(class="odd")
        th.border Month
        th.border Teacher or classroom name
        th.border License days used
        th.border Users with active licenses
      tr(v-for="(stats, row) in licenseDaysByMonthAndTeacher" :class="{odd: row % 2 == 1, even: row % 2 == 0, sum: stats.teacher == '--sum--'}")
        td.border {{stats.month}}
        td.border {{stats.teacher}}
        td.border {{stats.licenseDaysUsed}}
        td.border {{stats.activeLicenses}}
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
         }
       }),
     ...mapGetters(
       'me', [
         'isAnonymous',
         'isAPIClient'
       ]
     ),
     licenseDaysByMonth() {
         let lbm = this.licenseDaysByMonth
         _.sort(lbm)
       return lbm
     },
     licenseDaysByMonthAndTeacher() {
       let byMonthAndTeacher = []
       for(let month in this.licenseStats.licenseDaysByMonth) {
         let stat = this.licenseStats.licenseDaysByMonth[month]
         for(let teacher in stat.teachers) {
           let s = stat.teachers[teacher]
           byMonthAndTeacher.push({month, teacher, licenseDaysUsed: s.daysUsed, activeLicenses: s.noOfRedeemers})
         }
         byMonthAndTeacher.push({month, teacher: '--sum--', licenseDaysUsed: stat.daysUsed, activeLicenses: stat.noOfRedeemers})
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
   components: {
   },
     watch: {
         clientId: function (id) {
             if(id != '') {
                 this.fetchLicenseStats(id)
             }
         }
     },
   created() {
     if(this.isAnonymous || !this.isAPIClient) {
         window.location.href = '/'
     }
       this.fetchClientId()
       // current play time for apiclient is the total time of all students so i think
       // we doesn't need it now
       /* this.fetchPlayTimeStats() */
   }
 })
</script>

<style lang="scss">
 tr.odd {
   background-color: rgba(255, 196, 8, 0.1);
 }
 tr.sum {
   background-color:(rgba(31, 186, 180, 0.2) !important);
 }
 
</style>
