<template>
  <div class="related">
    <div class="related__heading">
      <h3 class="related__heading__text">
        Related Users:
      </h3>
    </div>
    <div
      v-if="!related || related.length === 0"
      class="related__none"
    >
      <p class="related__none__text">
        No related users right now
      </p>
    </div>
    <div
      v-if="users.length"
      class="related__main"
    >
      <div
        v-for="user in users"
        :key="user.userId"
        class="related__main__user"
      >
        {{ user }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'RelatedUserComponent',
  props: {
    related: {
      type: Array,
      default: null
    }
  },
  data () {
    return {
      users: this.related
    }
  }
}
</script>

<style scoped lang="scss">
.related {
  &__none {
    &__text {
      color: #808080;
      font-size: 1.6rem;
    }
  }
}
</style>
