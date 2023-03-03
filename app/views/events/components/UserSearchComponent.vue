<template>
  <div class="flex user-search">
    <input
      v-model="user"
      class="form-control"
      name="user"
      type="text"
    >
    <div
      v-if="!hideResult"
      class="user-lists"
    >
      <div
        v-for="u in userList"
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
      hideResult: true
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
      const searchValue = this.user.trim().toLowerCase()
      if (!searchValue || searchValue === this.lastSearchUser) {
        return
      }
      this.lastSearchUser = searchValue
      this.searchUser(`role:${this.role} ${searchValue}`)
      this.hideResult = false
    },
    selectUser (u) {
      this.setUser = true // flag user change by code
      this.user = u.name
      this.$emit('select', u._id)
      this.hideResult = true
    }
  }
}
</script>

<style lang="scss">
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
}
</style>
