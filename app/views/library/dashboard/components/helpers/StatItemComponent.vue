<template>
  <div class="stat">
    <img
      :src="imgPath" :alt="`Icon for ${name}`"
      class="stat__img"
    >
    <div class="stat__info">
      <div class="stat__num">
        {{ value }}
      </div>
      <div class="stat__text">
        {{ name }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatItemComponent',
  props: {
    imgPath: {
      type: String
    },
    name: {
      type: String
    },
    value: {
      type: String
    }
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.stat {
  display: flex;
  align-items: center;
  padding: 1rem;
  &__img {
    height: 8rem;
    margin-right: 1rem;
  }

  &__info {
    color: $color-blue-2;
    font-family: Space Mono, serif;
    font-size: 3.5rem;
    font-style: normal;
    font-weight: 700;
    line-height: normal;
    text-transform: uppercase;
  }

  &__text {
    font-size: 1.8rem;
  }
}
</style>
