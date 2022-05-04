<template>
  <div class="student-licenses-cmpt">
    <div class="student-license-content">

      <home-school-view
        :payment-group-id="paymentGroup._id"
        :price-info="paymentGroup.priceData[0]"
        v-if="me.get('role') === 'parent' && paymentGroupLoaded"
      />
      <student-licenses-body-component
        :num-students="numStudentsVal"
        :payment-group="paymentGroup"
        v-else-if="me.isTeacher() && paymentGroupLoaded"
      />
    </div>
  </div>
</template>

<script>
import RawPugComponent from 'app/views/common/RawPugComponent'
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import StudentLicensesBodyComponent from './StudentLicensesBodyComponent'
import HomeSchoolView from "../student-license/HomeSchoolView";
import { mapActions, mapGetters } from "vuex";

export default {
  name: 'PaymentStudentLicensesComponent',
  components: {
    RawPugComponent,
    StudentLicensesBodyComponent,
    HomeSchoolView
  },
  data () {
    return {
      teacherDashboardNavTemplate,
      me: me,
      paymentGroupLoaded: false
    }
  },
  computed: {
    ...mapGetters({
      'currentTrialRequest': 'trialRequest/properties',
      'paymentGroup': 'paymentGroups/paymentGroup'
    }),
    numStudentsVal () {
      const numStudents = this.currentTrialRequest?.numStudents
      // return '10+'
      return numStudents === '1-10' ? '<=10' : '10+'
    }
  },
  methods: {
    ...mapActions({
      'fetchCurrentTrialRequest': 'trialRequest/fetchCurrentTrialRequest',
      'fetchPaymentGroup': 'paymentGroups/fetch'
    })
  },
  async created() {
    console.log('qwe', this.currentTrialRequest)
    await this.fetchCurrentTrialRequest()
    console.log('payyyy', this.currentTrialRequest)
    if (me.get('role') === 'parent' && !['australia', 'taiwan', 'hong-kong', 'netherlands', 'indonesia', 'singapore', 'malaysia'].includes(me.get('country'))) {
      await this.fetchPaymentGroup('homeschool-coco')
    } else if (this.numStudentsVal === '<=10') {
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
</style>
