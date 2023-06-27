import teacherDashboardPanel from '../../../../store/TeacherDashboardPanel'

export default {
  beforeCreate () {
    if (!this.$store.hasModule('teacherDashboardPanel')) {
      this.$store.registerModule('teacherDashboardPanel', teacherDashboardPanel)
    }
  }
}
