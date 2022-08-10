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
      v-if="related.length"
      class="related__main"
    >
      <div
        v-for="user in related"
        :key="user.userId"
        class="related__main__user"
      >
        <div class="row related__user">
          <div class="col-md-6">
            <div class="related__user__text">
              {{ user.email }}
            </div>
          </div>
          <div
            class="col-md-3"
          >
            <div
              v-if="!user.verified"
              class="related__user__verified"
            >
              <button class="btn btn-warning">
                Send Verify Email
              </button>
            </div>
            <div
              v-else
              class="related__user__not__verified"
            >
              Verified
            </div>
          </div>
          <div class="col-md-3">
            <div class="related__user__switch">
              <button
                class="btn btn-success"
                :disabled="!user.verified"
                @click="() => onSwitch({ email: user.email })"
              >
                Switch
              </button>
            </div>
          </div>
        </div>
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
  methods: {
    onSwitch ({ email }) {
      this.$emit('switchUser', { email })
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

  &__user {
    margin-bottom: 1rem;
    background-color: #f0f8ff;
    padding: 1rem;
    &__verified {
      display: inline-block;
    }
    &__not__verified {
      text-align: center;
      color: #73A839;
    }
    &__switch {
      display: inline-block;
    }
    &__text {
      font-size: 1.6rem;
    }
  }
}
</style>
