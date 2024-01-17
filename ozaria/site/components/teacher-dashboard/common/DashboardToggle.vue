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
      > On
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
      > Off
    </label>
  </div>
</template>

<script>
export default {
  name: 'DashboardToggle',
  computed: {
    isOldDashboard () {
      return localStorage.getItem('newDT') !== 'true'
    },
    isNewDashboard () {
      return localStorage.getItem('newDT') === 'true'
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
      localStorage.setItem('newDT', newValue ? 'true' : 'false')
      window.location.reload()
    }
  }
}
</script>
<style scoped lang="scss">
#dashboard-toggle {
    label {
        margin-left: 0;
    }
}
</style>
