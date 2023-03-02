<template>
  <div class="flex">
    <input
      v-model="user"
      class="form-control"
      name="user"
      type="text"
    >
    <div class="user-lists">
      <div
        v-for="u in userList"
        :key="u._id"
      >
        <span>{{ u.name }}</span>
        <span>{{ u.firstName }}</span>
        <span>{{ u.role }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import _ from 'lodash'
export default {
  name: 'UserSearchComponent',
  props: {
    role: {
      type: String,
      default: 'student'
    }
  },
  data () {
    return {
      user: '',
      lastSearchUser: '',
      setUser: false,
      hideResult: false
    }
  },
  computed: {
    ...mapGetters({
      userList: 'users/getUserSearchResult'
    }),
    debouncedSearch () {
      return _.debounce(this.search, 1000)
    }
  },
  watch: {
    user () {
      if (this.setUser) {
        this.setUser = false
      } else {
        this.hideResult = false
        this.debouncedSearch()
      }
    }
  },
  methods: {
    ...mapActions({
      searchUser: 'users/fetchUsersByNameOrSlug'
    }),
    search () {
      console.log('search ', this.user)
      const searchValue = this.user.trim().toLowerCase()
      if (!searchValue || searchValue === this.lastSearchUser) {
        return
      }
      this.lastSearchUser = searchValue
      this.searchUser(`role:${this.role} ${searchValue}`)
    },
    selectUser (u) {
      this.setUser = true // flag user change by code
      this.user = u.name
      this.hideResult = true
    }
  }
}
</script>

<style>
</style>
