<template>
  <div class="flex">
    <input
      v-model="user"
      name="user"
      type="text"
    >
    <div class="user-lists" />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
export default {
  name: 'UserSearchComponent',
  data () {
    return {
      user: '',
      lastSearchUser: ''
    }
  },
  computed: {
    ...mapGetters({
      userList: 'users/getUserSearchResult'
    })
  },
  methods: {
    ...mapActions({
      searchUser: 'users/fetchUsersByNameOrSlug'
    }),
    search () {
      const searchValue = this.user.trim().toLowerCase()
      if (!searchValue || searchValue === this.lastSearchUser) {
        return
      }
      this.lastSearchUser = searchValue
      this.searchUser(searchValue)
    }
  }
}
</script>

<style>
</style>
