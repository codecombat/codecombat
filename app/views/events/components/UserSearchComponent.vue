<template>
  <div class="flex user-search">
    <input
      v-model="user"
      class="form-control"
      name="user"
      type="text"
      :placeholder="placeholder"
    >
    <div
      v-if="!hideResult"
      class="user-lists"
    >
      <div
        v-if="filteredUserList.length === 0"
        class="no-result"
      >
        {{ noResults }}
      </div>
      <div
        v-for="u in filteredUserList"
        :key="u._id"
        @click="selectUser(u)"
        class="user-line"
      >
        <span>{{ u.name }}</span>
        <span>{{ u.firstName }}</span>
        <span>{{ u.role }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapMutations, mapActions } from 'vuex'
import _ from 'lodash'
export default {
  name: 'UserSearchComponent',
  props: {
    placeholder: {
      type: String,
      default: ''
    },
    role: {
      type: String,
      default: 'student'
    },
    permissions: {
      type: String,
      default: undefined
    },
    noResults: {
      type: String,
      default: 'No results...'
    },
    value: {
      type: String,
      default: ''
    },
    userList: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      user: '',
      lastSearchUser: '',
      setUser: false,
      hideResult: true
    }
  },
  computed: {
    ...mapGetters({
      userSearchList: 'users/getUserSearchResult'
    }),
    debouncedSearch () {
      return _.debounce(this.search, 1000)
    },
    filteredUserList () {
      if (this.userList.length === 0) return this.userSearchList
      const commonIds = _.intersection(this.userSearchList.map(u => u._id), this.userList.map(u => u._id))
      return _.filter(this.userSearchList, u => commonIds.includes(u._id))
    }
  },
  watch: {
    user () {
      if (this.setUser) {
        this.setUser = false
      } else if (!this.user) {
        this.$emit('clear-search')
        this.hideResult = true
      } else {
        this.hideResult = false
        this.debouncedSearch()
      }
    },
    value (newValue) {
      if (this.user === newValue) return
      this.setUser = true
      this.user = newValue
      this.resetSearchedUser()
    }
  },
  methods: {
    ...mapActions({
      searchUser: 'users/fetchUsersByNameOrSlug'
    }),
    ...mapMutations({
      resetSearchedUser: 'users/resetSearchedResult'
    }),
    search () {
      const searchValue = this.user.trim().toLowerCase()
      if (!searchValue || searchValue === this.lastSearchUser) {
        return
      }
      this.lastSearchUser = searchValue
      this.searchUser({ q: searchValue, role: this.role, permissions: this.permissions })
      this.hideResult = false
    },
    selectUser (u) {
      this.setUser = true // flag user change by code
      this.user = u.name
      this.$emit('select', u)
      this.hideResult = true
    }
  }
}
</script>

<style lang="scss" scoped>
.user-search {
  position: relative;

  .user-lists {
    position: absolute;
    z-index: 5;
    width: 100%;
    background: white;
    box-shadow: 0 5px 10px 2px #ddd;
    border-radius: 3px;
    min-height: 100px;

    .user-line {
      margin: 10px 15px;
      cursor: pointer;
      display: flex;
      justify-content: space-between;
    }
  }

  .no-result {
    color: #666;
  }
}
</style>
