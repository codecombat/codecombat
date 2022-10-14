<template>
  <loading-progress :loading-status="loadingStatuses">
    <license-data-per-user :loading="loading" :prepaids="prepaids" :teacherMap="teacherMap" />
  </loading-progress>
</template>

<script>
import { mapActions, mapState } from 'vuex'
import LoadingProgress from 'app/views/core/LoadingProgress'
import LicenseDataPerUser from 'app/components/license/LicenseDataPerUser'

export default {
  name: 'LicensesTable',
  components: {
    LoadingProgress,
    LicenseDataPerUser
  },
  data () {
    return {
      myId: undefined,
    }
  },
  computed: {
    ...mapState('prepaids', {
      prepaidLoading: function (s) {
        return s.loading.byTeacher[this.myId]
      },
      prepaids: function (s) {
        return s.prepaids.byTeacher[this.myId]
      }
    }),
    ...mapState('schoolAdministrator', {
      teachersLoading: s => s.loading.teachers,
      administratedTeachers: s => s.administratedTeachers || []
    }),
    loadingStatuses () {
      return [this.prepaidLoading, this.teachersLoading]
    },
    loading () {
      return this.loadingStatuses.reduce((r, i) => r || i, false)
    },
    teacherMap () {
      const administratedTeachers = window._.indexBy(this.administratedTeachers, '_id')
      administratedTeachers[this.myId] = Object.assign({ _trialRequest: { organization: 'Yourself' } }, me.attributes)
      return administratedTeachers
    },
  },
  created () {
    this.myId = me.get('_id')
    this.fetchTeachers()
    this.fetchPrepaids({ teacherId: this.myId, includeShared: false })
  },
  methods: {
    ...mapActions({
      fetchTeachers: 'schoolAdministrator/fetchTeachers',
      fetchPrepaids: 'prepaids/fetchPrepaidsForTeacher'
    }),
    downloads () {
      let csvContent = `${this.header.join(',')}\n`
      this.studentData.forEach((row) => {
        csvContent += `${row.join(',')}\n`
      })
      const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
      saveAs.saveAs(file, `License-stats-${new Date().toLocaleDateString()}.csv`)
    },
  }

}
</script>
