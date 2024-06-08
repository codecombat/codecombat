<template>
  <div class="filters">
    <div class="filter">
      <input
        v-model="search"
        type="text"
        class="filter__user form-control"
        placeholder="User email/id"
        @keyup.enter="onUserSearch"
      >
    </div>
    <div class="filter">
      <input
        id="filter-done"
        v-model="showDone"
        type="checkbox"
        class="filter__done"
      >
      <label for="filter-done">Marked as done</label>
    </div>
    <div class="filter">
      <input
        id="filter-sort"
        v-model="showSorted"
        type="checkbox"
        class="filter__done"
      >
      <label for="filter-sort">Sort by licenses</label>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FilterComponent',
  data () {
    return {
      search: '',
      showDone: false,
      showSorted: false
    }
  },
  watch: {
    showDone (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$emit('show-done', newVal)
      }
    },
    showSorted (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$emit('show-sort', newVal)
      }
    }
  },
  methods: {
    onUserSearch () {
      this.$emit('user-search', this.search)
    }
  }
}
</script>

<style scoped lang="scss">
.filters {
  display: flex;
  font-size: 1.5rem;

  .filter {
    padding: 5px;
    margin-right: 10px;
  }
}
</style>
