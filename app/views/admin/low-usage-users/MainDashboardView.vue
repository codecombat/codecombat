<template>
  <div class="low-usage">
    <h1 class="low-usage__title">
      Low Usage Users
    </h1>
    <filter-component />
    <data-component
      :users="lowUsageUsers"
    />
  </div>
</template>

<script>
import DataComponent from './DataComponent'
import FilterComponent from './FilterComponent'
import { mapActions, mapGetters } from 'vuex'
export default {
  name: 'MainDashboardView',
  components: {
    DataComponent,
    FilterComponent
  },
  computed: {
    ...mapGetters({
      lowUsageUsers: 'lowUsageUsers/getLowUsageUsers'
    })
  },
  async created () {
    await this.fetchLowUsageUsers()
    console.log('users', this.lowUsageUsers)
  },
  methods: {
    ...mapActions({
      fetchLowUsageUsers: 'lowUsageUsers/fetchLowUsageUsers'
    })
  }
}
</script>

<style scoped lang="scss">
.low-usage {
  font-size: 62.5%;

  padding: 5rem;
}
</style>
