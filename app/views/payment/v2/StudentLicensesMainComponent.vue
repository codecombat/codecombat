<template>
  <div class="student-licenses-main">
    <raw-pug-component :pug="teacherDashboardNavTemplate"></raw-pug-component>
    <student-licenses-component />
  </div>
</template>

<script>
import StudentLicensesComponent from './StudentLicensesComponent'
import teacherDashboardNavTemplate from 'app/templates/courses/teacher-dashboard-nav.pug'
import RawPugComponent from 'app/views/common/RawPugComponent'

export default {
  name: 'StudentLicensesMainComponent',
  data () {
    return {
      teacherDashboardNavTemplate
    }
  },
  components: {
    StudentLicensesComponent,
    RawPugComponent
  }
}
</script>

<style scoped>

</style>
