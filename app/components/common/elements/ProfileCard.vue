<template>
  <p class="profile-card">
    <avatar-component
      v-if="image"
      :img="image"
      :alt="name"
    />
    <span class="profile-card__name">
      {{ name }}
    </span>
    <span
      v-if="name && title"
      class="profile-card__divider"
    >/</span>
    <span class="profile-card__title">
      {{ title }}
    </span>
  </p>
</template>

<script>
import AvatarComponent from './AvatarComponent.vue'

export default {
  name: 'ProfileCard',
  components: {
    'avatar-component': AvatarComponent
  },
  props: {
    name: {
      type: String,
      default: null,
      required: false
    },
    title: {
      type: String,
      default: null,
      required: false
    },
    image: {
      type: String,
      default: null,
      required: false
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.profile-card {
  color: $light-grey;

  &__name {
    @extend %font-16;
    color: $dark-grey;
    font-style: italic;
    font-weight: 700;
  }

  &__divider {
    @extend %font-16;
    color: $dark-grey;
    padding: 0 8px;
  }

  &__title {
    @extend %font-16;
    color: $light-grey;
    font-weight: 400;
  }
}
</style>
