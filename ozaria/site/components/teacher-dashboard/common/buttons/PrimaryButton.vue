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
  background-color: $moon;
  border-radius: 1px;
  border-width: 0;
  color: $gray;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  background-image: unset;

  &:hover {
    background-color: $goldenlight;
    transition: background-color .35s;
    color: #ffffff;
  }

  &:disabled {
    background: #ADADAD;
    color: #000000;
    cursor: default;
  }
}
</style>
