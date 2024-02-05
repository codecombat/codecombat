<template>
  <div
    class="two-column-block"
    :class="{ reverse: reverse }"
  >
    <div class="column-one">
      <slot name="column-one" />
    </div>
    <div class="column-two">
      <slot name="column-two" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'TwoColumnBlock',
  props: {
    reverse: {
      type: Boolean,
      required: false,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
.two-column-block {
    display: flex;
    flex-direction: column;
    gap: 30px;
    margin: 100px auto;

    @media (min-width: 768px) {
      flex-direction: row;

      &.reverse {
        flex-direction: row-reverse;
      }
    }

    .column-one,
    .column-two {
        flex: 1;
    }
}
</style>
