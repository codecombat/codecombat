<template lang="pug">
  #api-dashboard
   table.table.table-condensed(v-if="licenseDaysByMonth")
      tr
        th.border Month
        th.border License days used by {{clients[0].name}}
        th.border Users with active licenses
      tr(v-for="(stats, month) in licenseDaysByMonth")
        td.border {{month}}
        td.border {{stats.daysUsed}}
        td.border {{stats.noOfRedeemers}}
</template>

<script>
 import { mapActions, mapState, mapGetters } from 'vuex'
 module.exports = Vue.extend({
   props: {
   },
   data() {
     return {
       ...mapState('licenseStats', {
         licenseStatsLoading: function (s) {
           return s.loading.byLicense
         },
         licenseStats: function (s) {
           return s.licenseStats
         }
       }),
     }
   },
   computed: {
     ...mapGetters(
       'me', [
         'isAnonymous',
         'isLicensor'
       ]
     ),
     licenseDaysByMonth() {
       return this.licenseStats.licenseDaysByMonth
     }
   },
   methods: {
     ...mapActions({
       fetchLicenseStats: 'apiClient/fetchLicenseStats'
     })
   },
   components: {
   },
   mounted() {
     if(this.isAnonymous || !this.isLicensor) {
       /* window.location.href = '/' */
     }
     this.fetchLicenseStats('57fff652b0783842003fed00')
   }
 })
</script>

<style lang="sass">
</style>
