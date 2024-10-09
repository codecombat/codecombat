<template>
  <component
    :is="tagType"
    v-bind="allProps"
  >
    <slot />
  </component>
</template>

<script>
export default {
  name: 'DynamicLink',
  props: {
    href: { type: String, default: null },
    target: {
      type: String,
      default: '_blank',
    },
  },
  computed: {
    tagType () {
      return this.href ? 'a' : 'span'
    },
    allProps () {
      return this.$props
    },
  },
}
</script>§