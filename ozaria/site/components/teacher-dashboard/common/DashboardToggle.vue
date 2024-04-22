<template>
  <div
    id="dashboard-toggle"
    class="dashboard-toggle"
  >
    <div
      v-if="showTitle"
      class="dashboard-toggle__title"
    >
      {{ $t('teacher_dashboard.dashboard_version') }}
    </div>
    <div
      class="btn-group"
      data-toggle="buttons"
    >
      <label
        class="btn btn-primary"
        :class="{ [`btn-${size}`]: true, active: isNewDashboard}"
        :disabled="isNewDashboard"
        @click="saveValue(true)"
      >
        <input
          id="option1"
          type="radio"
          name="options"
          autocomplete="off"
          :checked="isNewDashboard"
        > {{ $t('teacher_dashboard.version_new') }}
      </label>
      <label
        class="btn btn-primary"
        :class="{ [`btn-${size}`]: true, active: isOldDashboard}"
        :disabled="isOldDashboard"
        @click="saveValue(false)"
      >
        <input
          id="option2"
          type="radio"
          name="options"
          autocomplete="off"
          :checked="isOldDashboard"
        > {{ $t('teacher_dashboard.version_old') }}
      </label>
    </div>
  </div>
</template>

<script>
export default Vue.extend({
  name: 'DashboardToggle',
  props: {
    size: {
      type: String,
      default: 'md'
    },
    showTitle: {
      type: Boolean,
      default: false
    },
    reloadLocation: {
      type: String,
      default: '/teachers/classes'
    }
  },
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
  methods: {
    async saveValue (newValue) {
      window.tracker.trackEvent('Dashboard Version Switched', {
        category: 'Teachers',
        value: newValue
      })
      me.set('features', {
        ...me.get('features'),
        isNewDashboardActive: newValue
      })
      await me.save()
      this.dashboardStatus = me.isNewDashboardActive()
      if (this.reloadLocation) {
        if (window.location.pathname === this.reloadLocation) {
          window.location.reload()
        } else {
          window.location.href = this.reloadLocation
        }
      }
    }
  }
})
</script>
<style scoped lang="scss">
.dashboard-toggle {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-direction: column;
    &__title {
        font-size: 11px;
        line-height: 13px;
        font-weight: normal;
    }
    .btn-group label {
        margin-left: 0;
    }
    .active {
      text-decoration: underline;
    }
}
</style>
