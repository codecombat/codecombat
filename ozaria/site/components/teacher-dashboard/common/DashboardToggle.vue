<template>
  <div
    id="dashboard-toggle"
    class="btn-group"
    data-toggle="buttons"
  >
    <label
      class="btn btn-primary"
      :disabled="isNewDashboard"
      @click="setLocalStorage(true)"
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
      @click="setLocalStorage(false)"
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
import utils from 'core/utils'
export default Vue.extend({
  name: 'DashboardToggle',
  computed: {
    isOldDashboard () {
      return localStorage.getItem(utils.getNewDashboardToggleKey()) !== 'true'
    },
    isNewDashboard () {
      return localStorage.getItem(utils.getNewDashboardToggleKey()) === 'true'
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
    setLocalStorage (newValue) {
      // todo: can we add me.id to key so that for admins it's easier
      localStorage.setItem(utils.getNewDashboardToggleKey(), newValue ? 'true' : 'false')
      window.location.reload()
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
