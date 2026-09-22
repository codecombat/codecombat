<script>
export default Vue.extend({
  props: {
    inactive: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onClick () {
      if (!this.inactive) {
        this.$emit('click')
      }
    },
  },
})
</script>

<template>
  <button
    :class="['purple-btn', { disabled: inactive }]"
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
@import "ozaria/site/components/teacher-dashboard/common/purple-button";
</style>
