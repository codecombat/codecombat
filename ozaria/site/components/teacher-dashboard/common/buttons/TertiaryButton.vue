
<script>
export default Vue.extend({
  props: {
    inactive: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    onClick () {
      if (!this.inactive) {
        this.$emit('click')
      }
    }
  }
})
</script>

<template>
  <button
    :class="{ disabled: inactive }"
    :disabled="inactive"
    @click="onClick"
  >
    <slot />
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

button {
  border: 2px solid $dusk-dark;
  border-radius: 1px;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  background-image: unset;
  color: $dusk-dark;

  &:hover {
    background-color: $dusk-dark;
    transition: background-color .35s;
    color: #ffffff;
  }

  &.disabled {
    border: 2px solid #ADADAD;
    color: #ADADAD;
    cursor: default;
    background-color: unset;
  }
}
</style>
