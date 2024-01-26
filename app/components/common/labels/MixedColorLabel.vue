<template>
  <span class="mixed-color-label">
    <span
      v-for="(word, index) in parsedWords"
      :key="index"
    >

      <a
        v-if="word.isPurple && link"
        :class="{ 'mixed-color-label__highlight': word.isPurple, 'mixed-color-label__normal': !word.isPurple }"
        :href="link"
        :target="target"
      >{{ word.text }}</a>
      <span
        v-else
        :class="{ 'mixed-color-label__highlight': word.isPurple, 'mixed-color-label__normal': !word.isPurple }"
      >{{ word.text }}</span>
    </span>
  </span>
</template>

<script>
export default {
  name: 'MixedColorLabel',
  props: {
    text: {
      type: String,
      required: false,
      default: ''
    },
    link: {
      type: String,
      required: false,
      default: null
    },
    target: {
      type: String,
      required: false,
      default: null
    }
  },
  computed: {
    parsedWords () {
      if (!this.text) return []
      const words = this.text.split(/__|\*\*/)
      return words.map((word, index) => ({ text: word, isPurple: index % 2 !== 0 }))
    }
  }
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
.mixed-color-label {
  &__normal {
    color: $dark-grey;
  }

  &__highlight {
    color: $purple;
  }
}
</style>
