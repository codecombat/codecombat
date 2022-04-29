<template>
  <div class="student-licenses-cmpt">
    <raw-pug-component :pug="teacherDashboardNavTemplate"></raw-pug-component>
    <div class="student-license-content">
      <div class="header">
        <div class="header__heading">{{ $t('payments.student_licenses') }}</div>
        <div class="header__subheading">
          {{ $t('payments.purchase_licenses_2') }}. {{ $t('new_home.learn_more') }} {{ $t('payments.about') }}
          <a href="">{{ $t('payments.applying_licenses') }}</a>
        </div>
      </div>

      <student-licenses-body-component
        :num-students="numStudentsVal"
      />
    </div>
  </div>
</template>

<script>
import RawPugComponent from 'app/views/common/RawPugComponent'
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import StudentLicensesBodyComponent from './StudentLicensesBodyComponent'
import { mapActions, mapGetters } from "vuex";

export default {
  name: 'PaymentStudentLicensesComponent',
  components: {
    RawPugComponent,
    StudentLicensesBodyComponent
  },
  data () {
    return {
      teacherDashboardNavTemplate
    }
  },
  computed: {
    ...mapGetters({
      'currentTrialRequest': 'trialRequest/properties'
    }),
    numStudentsVal () {
      const numStudents = this.currentTrialRequest?.numStudents
      return numStudents === '1-10' ? '<=10' : '10+'
    }
  },
  methods: {
    ...mapActions({
      'fetchCurrentTrialRequest': 'trialRequest/fetchCurrentTrialRequest'
    })
  },
  async created() {
    console.log('qwe', this.currentTrialRequest)
    await this.fetchCurrentTrialRequest()
    console.log('payyyy', this.currentTrialRequest)
  }
}
</script>

<style scoped lang="scss">
.student-licenses-cmpt {
  font-size: 62.5%;
}

.student-license-content {
  padding: 3rem 5rem 5rem;
}

.header {

  padding-bottom: 2rem;
  &__heading {
    font-family: 'Work Sans', serif;
    font-style: normal;
    font-weight: 700;
    font-size: 4rem;
    line-height: 3.2rem;
    /* or 80% */

    letter-spacing: 0.56px;

    color: #000000;

    margin-bottom: 1rem;
  }

  &__subheading {
    font-family: 'Work Sans', serif;
    font-style: normal;
    font-weight: 400;
    font-size: 2.2rem;
    line-height: 3rem;
    /* identical to box height, or 136% */


    color: #000000;
  }
}
</style>
