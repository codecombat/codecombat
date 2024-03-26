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
  </div>
</template>

<script>
export default {
  name: 'FilterComponent',
  data () {
    return {
      search: '',
      showDone: false
    }
  },
  watch: {
    showDone (newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$emit('show-done', newVal)
      }
      console.log('showDone', newVal, oldVal)
    }
  },
  methods: {
    onUserSearch () {
      console.log('user', this.search, this.showDone)
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
