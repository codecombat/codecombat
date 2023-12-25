<template>
  <div class="student-licenses-main">
    <raw-pug-component :pug="teacherDashboardNavTemplate" />
    <student-licenses-component />
  </div>
</template>

<script>
import StudentLicensesComponent from './StudentLicensesComponent'
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import RawPugComponent from 'app/views/common/RawPugComponent'

export default {
  name: 'StudentLicensesMainComponent',
  components: {
    StudentLicensesComponent,
    RawPugComponent
  },
  data () {
    return {
      teacherDashboardNavTemplate
    }
  }
}
</script>

<style scoped>

</style>
