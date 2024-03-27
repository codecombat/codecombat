<template>
  <div class="low-usage">
    <h1 class="low-usage__title">
      Low Usage Users
    </h1>
    <filter-component
      @show-done="onShowDone"
      @user-search="onUserSearch"
    />
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
        // users = users
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
    console.log('users', this.lowUsageUsers)
  },
  methods: {
    ...mapActions({
      fetchLowUsageUsers: 'lowUsageUsers/fetchLowUsageUsers',
      addAction: 'lowUsageUsers/addActionToUser'
    }),
    onShowDone (val) {
      console.log('showdone', val)
      this.showDone = val
    },
    onUserSearch (value) {
      console.log('search', value)
      this.search = value
    },
    onMarkDone (userId) {
      console.log('mark done', userId, this.lowUsageUsers.find(user => user.userId === userId), this.lowUsageUsers)
      const lowUsageUserId = this.lowUsageUsers.find(user => user.userId === userId)._id
      this.addAction({ lowUsageUserId, action: 'done' })
    },
    onUndoDone (userId) {
      console.log('undo done', userId)
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
}
</style>
