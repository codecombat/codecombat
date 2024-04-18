<template>
  <div class="low-usage">
    <h1 class="low-usage__title">
      Low Usage Users
    </h1>
    <filter-component
      @show-done="onShowDone"
      @user-search="onUserSearch"
    />
    <div class="count">
      {{ filteredLowUsageUsers.length }} users found
    </div>
    <data-component
      :users="filteredLowUsageUsers"
      @mark-done="onMarkDone"
      @undo-done="onUndoDone"
    />
  </div>
</template>

<script>
import DataComponent from './DataComponent'
import FilterComponent from './FilterComponent'
import { mapActions, mapGetters } from 'vuex'
import { isMarkedDone } from './low-usage-users-helper'
export default {
  name: 'MainDashboardView',
  components: {
    DataComponent,
    FilterComponent
  },
  data () {
    return {
      showDone: false,
      search: ''
    }
  },
  computed: {
    ...mapGetters({
      lowUsageUsers: 'lowUsageUsers/getLowUsageUsers'
    }),
    filteredLowUsageUsers () {
      let users = this.lowUsageUsers
      if (this.showDone) {
        users = users.filter(u => isMarkedDone(u))
      } else {
        users = users.filter(u => !isMarkedDone(u))
      }
      if (this.search) {
        if (this.search.includes('@')) {
          users = users.filter(user => user.email === this.search)
        } else {
          users = users.filter(user => user.userId === this.search)
        }
      }
      return users
    }
  },
  async created () {
    await this.fetchLowUsageUsers()
    console.log('low-usage-users', this.lowUsageUsers)
  },
  methods: {
    ...mapActions({
      fetchLowUsageUsers: 'lowUsageUsers/fetchLowUsageUsers',
      addAction: 'lowUsageUsers/addActionToUser'
    }),
    onShowDone (val) {
      this.showDone = val
    },
    onUserSearch (value) {
      this.search = value
    },
    onMarkDone (userId) {
      const lowUsageUserId = this.lowUsageUsers.find(user => user.userId === userId)._id
      this.addAction({ lowUsageUserId, action: 'done' })
    },
    onUndoDone (userId) {
      const lowUsageUserId = this.lowUsageUsers.find(user => user.userId === userId)._id
      this.addAction({ lowUsageUserId, action: 'undo-done' })
    }
  }
}
</script>

<style scoped lang="scss">
.low-usage {
  font-size: 62.5%;

  padding: 5rem;

  .count {
    font-size: 1.5rem;
  }
}

.low-usage__title {
  font-size: 24px;
  line-height: 30px;
  font-weight: bold;
  margin-bottom: 10px;
}
</style>
