<template>
  <loading-progress :loading-status="loadingStatuses">
    <div v-if="!loading">
      prepaids load ends
      <div
        class="btn btn-large"
        @click="downloads"
      >
        Exports
      </div>
    </div>
  </loading-progress>
</template>

<script>
import { mapActions, mapState } from 'vuex'
import LoadingProgress from 'app/views/core/LoadingProgress'

export default {
  name: 'LicensesTable',
  components: {
    LoadingProgress
  },
  data () {
    return {
      myId: undefined
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
    licenseStats () {
      if (this.loading) {
        return
      }
      return [...this.prepaids.available.map(this.mapPrepaid),
              ...this.prepaids.empty.map(this.mapPrepaid),
              ...this.prepaids.expired.map(this.mapPrepaid),
              ...this.prepaids.pending.map(this.mapPrepaid)]
    }
  },
  created () {
    if (!window.saveAs) {
      window.saveAs = require('file-saver/FileSaver.js')
    }
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
      let csvContent = 'license,startDate,school,teacherID,teacher,student,date,endDate\n'
      for (const license of this.licenseStats) {
        for (const joiner of license.joiners) {
          for (const student of joiner.students) {
            csvContent += `${license.id},${license.startDate},${joiner.school},${joiner.id},${joiner.name},${student.id},${student.date},${license.endDate}\n`
          }
        }
      }
      const file = new Blob([csvContent], { type: 'text/csv;charset=utf-8' })
      window.saveAs.saveAs(file, `License-stats-${new Date().toLocaleDateString()}.csv`)
    },
    mapPrepaid (prepaid) {
      /* const joiners = prepaid.joiners */
      /* const joinersWithId = window._.indexBy(joiners, 'userID') */
      const teachers = {}
      prepaid.redeemers.forEach((re) => {
        const teacher = this.teacherMap[re.teacherID]
        const trailRequest = teacher?._trialRequest || {}
        if (!(re.teacherID in teachers)) {
          teachers[re.teacherID] = {
            id: re.teacherID,
            school: trailRequest.organization,
            name: teacher?.firstName || teacher?.name,
            students: []
          }
        }
        teachers[re.teacherID].students.push({
          id: re.userID,
          date: new Date(re.date).toLocaleDateString()
        })
      })

      return {
        id: prepaid._id,
        startDate: new Date(prepaid.startDate).toLocaleDateString(),
        endDate: new Date(prepaid.endDate).toLocaleDateString(),
        joiners: Object.values(teachers)
      }
    }
  }

}
</script>
