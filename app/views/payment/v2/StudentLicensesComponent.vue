<template>
  <div class="student-licenses-cmpt">
    <div class="student-license-content">
      <home-school-view
        v-if="me.get('role') === 'parent' && paymentGroupLoaded"
        :payment-group-id="paymentGroup._id"
        :price-info="paymentGroup.priceData[0]"
      />
      <student-licenses-body-component
        v-else-if="me.isTeacher() && paymentGroupLoaded"
        :num-students="numStudentsVal"
        :payment-group="paymentGroup"
      />
      <div
        v-else-if="!me.isTeacher()"
        class="no-permission"
      >
        You don't have permission to view this page.
      </div>
      <div
        v-else
        class="loading"
      >
        loading...
      </div>
    </div>
  </div>
</template>

<script>
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import StudentLicensesBodyComponent from './StudentLicensesBodyComponent'
import HomeSchoolView from '../student-license/HomeSchoolView'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'PaymentStudentLicensesComponent',
  components: {
    StudentLicensesBodyComponent,
    HomeSchoolView
  },
  data () {
    return {
      teacherDashboardNavTemplate,
      me,
      paymentGroupLoaded: false
    }
  },
  computed: {
    ...mapGetters({
      currentTrialRequest: 'trialRequest/properties',
      paymentGroup: 'paymentGroups/paymentGroup',
      teacherPrepaids: 'prepaids/getPrepaidsByTeacher'
    }),
    numStudentsVal () {
      const numStudents = this.currentTrialRequest?.numStudents
      return numStudents === '1-10' ? '<=10' : '10+'
    }
  },
  methods: {
    ...mapActions({
      fetchCurrentTrialRequest: 'trialRequest/fetchCurrentTrialRequest',
      fetchPaymentGroup: 'paymentGroups/fetch',
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher'
    })
  },
  async created () {
    if (!this.currentTrialRequest?.numStudents) { await this.fetchCurrentTrialRequest() }
    await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
    const prepaids = this.teacherPrepaids(me.get('_id'))
    // not including expired license in count since we don't show them in UI so it will be confusing
    if (features.china || (prepaids && ((prepaids.pending.length + prepaids.empty.length + prepaids.available.length) > 0)) || ['cambodia', 'viet-nam'].includes(me.get('country'))) {
      window.location.href = '/teachers/licenses/v0'
      return
    }
    if (me.get('role') === 'parent' && !['australia', 'taiwan', 'hong-kong', 'netherlands', 'indonesia', 'singapore', 'malaysia'].includes(me.get('country'))) {
      await this.fetchPaymentGroup('homeschool-coco')
    } else if (this.numStudentsVal === '<=10' && me.isTeacher()) {
      await this.fetchPaymentGroup('student-licenses-small-classroom-coco')
    }
    this.paymentGroupLoaded = true
  }
}
</script>

<style scoped lang="scss">
.student-license-content {
  padding: 3rem 5rem 5rem;
}
.loading {
  text-align: center;
  font-size: 30px;
}
.no-permission {
  text-align: center;
  color: #ff0000;
}
</style>
