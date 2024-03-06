<template>
  <div
    id="dashboard-toggle"
    class="btn-group"
    data-toggle="buttons"
  >
    <label
      class="btn btn-primary"
      :disabled="isNewDashboard"
      @click="saveValue(true)"
    >
      <input
        id="option1"
        type="radio"
        name="options"
        autocomplete="off"
      > {{ $t('teacher_dashboard.switch_on') }}
    </label>
    <label
      class="btn btn-primary"
      :disabled="isOldDashboard"
      @click="saveValue(false)"
    >
      <input
        id="option2"
        type="radio"
        name="options"
        autocomplete="off"
      > {{ $t('teacher_dashboard.switch_off') }}
    </label>
  </div>
</template>

<script>
export default Vue.extend({
  name: 'DashboardToggle',
  data () {
    return {
      dashboardStatus: me.isNewDashboardActive()
    }
  },
  computed: {
    isOldDashboard () {
      return !this.dashboardStatus
    },
    isNewDashboard () {
      return this.dashboardStatus
    }
  },
  watch: {
    dashboardStatus (newValue, oldValue) {
      if (newValue !== oldValue) {
        this.dashboardStatus = newValue
      }
    }
  },
  mounted () {
    if (this.isNewDashboard) {
      document.getElementById('option1').checked = true
    } else {
      document.getElementById('option2').checked = true
    }
  },
  methods: {
    async saveValue (newValue) {
      me.set('aceConfig', { ...me.get('aceConfig'), newDashboard: newValue })
      await me.save()
      this.dashboardStatus = me.isNewDashboardActive()
    }
  }
})
</script>
<style scoped lang="scss">
#dashboard-toggle {
    label {
        margin-left: 0;
    }
}
</style>
