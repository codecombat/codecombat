<template>
  <loading-progress :loading-status="loadingStatuses">
    <div v-if="!loading">
      <div class="row">
        <h4>{{ $t('school_administrator.select_time_range') }}</h4>
      </div>
      <div class="row">
        <div class="form-control">
          <label for="startDate"> {{ $t('teacher.start_date') }}</label>
          <input
            v-model="startDate"
            type="date"
          >
        </div>
        <div class="form-control">
          <label for="endDate"> {{ $t('teacher.end_date') }}</label>
          <input
            v-model="endDate"
            type="date"
          >
        </div>
        <div
          class="btn btn-lg btn-navy-alt"
          @click="downloads"
        >
          {{ $t('school_administrator.export') }}
        </div>
      </div>
      <div class="table">
        <div class="preview note">
          {{ $t('school_administrator.preview') }}
        </div>
        <div class="row header">
          <span
            v-for="(h, i) in header"
            :key="`header-${i}-${h}`"
            class="item"
          >
            {{ h }}
          </span>
        </div>
        <div v-if="studentData.length === 0">
          {{ $t('school_administrator.empty_results') }}
        </div>
        <div
          v-for="(data, idx) in studentData.slice(0, lengthLimit)"
          :key="'row'+idx"
          class="row"
        >
          <span
            v-for="(it, index) in data"
            :key="`row-${idx}-item-${index}`"
            class="item"
          >
            {{ ([0, 3, 5].includes(index) && it) ? ('*' + it.slice(18)) : it }}
          </span>
        </div>
        <div v-if="studentData.length > lengthLimit">
          ...
        </div>
      </div>
    </div>
  </loading-progress>
</template>

<script>
import { mapActions, mapState } from 'vuex'
import LoadingProgress from 'app/views/core/LoadingProgress'
import moment from 'moment'
const saveAs = require('file-saver/FileSaver.js')

export default {
  name: 'LicensesTable',
  components: {
    LoadingProgress
  },
  data () {
    return {
      myId: undefined,
      lengthLimit: 200,
      startDate: moment().subtract(1, 'month').format('YYYY-MM-DD'),
      endDate: moment().format('YYYY-MM-DD')
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
    },
    header () {
      return 'license,startDate,school,teacherID,teacher,student,startDate,endDate,isActive'.split(',')
    },
    studentData () {
      const data = []
      for (const license of this.licenseStats) {
        for (const joiner of license.joiners) {
          for (const student of joiner.students) {
            data.push([license.id, license.startDate, joiner.school, joiner.id, joiner.name, student.id, student.startDate, student.endDate, student.active])
          }
        }
      }
      return data
    }
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
    mapPrepaid (prepaid) {
      const teachers = {}
      const remap = (re, active) => {
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
        const user = { id: re.userID, active }
        if (active) {
          user.startDate = new Date(re.date)
          user.endDate = new Date(prepaid.endDate)
          if (moment().isAfter(prepaid.endDate)) {
            user.active = false
          }
        } else {
          user.startDate = new Date(re.startDate)
          user.endDate = new Date(re.endDate)
        }
        const endDate = this.endDate + ' 23:59:59' // end of day
        if (moment(user.startDate).isBefore(endDate) && moment(user.endDate).isAfter(this.startDate)) {
          user.startDate = user.startDate.toLocaleDateString()
          user.endDate = user.endDate.toLocaleDateString()
          teachers[re.teacherID].students.push(user)
        }
      }
      (prepaid.redeemers || []).forEach((re) => {
        remap(re, true)
      });
      (prepaid.removedRedeemers || []).forEach((re) => {
        remap(re, false)
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

<style scoped lang="scss">
.table {
  margin-top: 10px;
  .row {
    display: flex;
    .item {
      &:nth-child(1), &:nth-child(4), &:nth-child(6) {
        flex-basis: 6em;
      }
      &:nth-child(2), &:nth-child(7), &:nth-child(8) {
        flex-basis: 8em;
      }
      &:nth-child(3), &:nth-child(5) {
        flex-basis: 9em;
      }
      &:nth-child(9) {
        flex-basis: 4em;
      }
    }
  }
  .header {
    font-weight: 800;
  }
  .row {
    &:nth-child(2n+1) {
      background-color: #ebebeb;
    }
    &:nth-child(2n) {
      background-color: #f5f5f5;
    }
  }
}
</style>
