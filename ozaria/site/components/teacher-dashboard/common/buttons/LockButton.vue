<script>
  export default {
    props: {
      inactive: {
        type: Boolean,
        default: false,
        required: false
      }
    }
  }
</script>

<template>
  <button
    :disabled="inactive"
    @click="$emit('click')"
  >
    <slot />
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

button {
  background-color: #F2F2F2;
  border-radius: 0px;
  border: 0.5px solid white;
  text-shadow: unset;
  @include font-p-3-small-button-text-black;
  font-size: 18px;
  line-height: 22px;
  font-weight: normal;
  font-style: normal;
  color: $pitch;
  background-image: unset;
  height: 35px;

  &:hover {
    background-color: $goldenlight;
    transition: background-color .35s;
    color: $pitch;
  }
}
</style>
