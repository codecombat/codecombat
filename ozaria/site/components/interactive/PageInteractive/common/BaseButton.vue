<script>
  export default {
    props: {
      onClick: {
        type: Function,
        default: () => {}
      },

      enabled: {
        type: Boolean,
        default: true
      }
    }
  }
</script>

<template>
  <button
    class='ozaria-btn'

    :disabled="!enabled"

    @click="onClick"
  >
    <slot />
  </button>
</template>

<style scoped lang="sass">
  .ozaria-btn
    height: 45px
    width: 182px
    color: #F7F9F9
    background: #1FBAB4
    font-size: 18px
    font-weight: bold
    letter-spacing: 0.71px
    line-height: 24px
    text-align: center
    border: 0

    &:hover
      box-shadow: 0px 0px 15px 0px #5D73E1
</style>
