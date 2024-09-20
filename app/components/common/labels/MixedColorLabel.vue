<template>
  <span class="mixed-color-label">
    <span
      v-for="(word, index) in parsedWords"
      :key="index"
    >

      <a
        v-if="word.isPurple && word.link"
        :class="{
          inherit: inheritDefaultColor,
          'mixed-color-label__highlight': word.isPurple,
          'mixed-color-label__normal': !word.isPurple
        }"
        :href="word.link"
        :target="target"
        @click="$emit('link-clicked')"
      >{{ word.text }}</a>
      <span
        v-else
        :class="{
          inherit: inheritDefaultColor,
          'mixed-color-label__highlight': word.isPurple,
          'mixed-color-label__normal': !word.isPurple
        }"
      >{{
        word.text }}</span>
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
      default: '_blank'
    },
    inheritDefaultColor: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  computed: {
    parsedWords () {
      if (!this.text) return []
      const words = this.text.split(/__|\*\*/)
      return words.map((word, index) => {
        const urlMatch = word.match(/\[(.*?)\]/)
        const link = urlMatch ? urlMatch[1] : null
        const text = link ? word.replace(urlMatch[0], '') : word
        return { text, isPurple: index % 2 !== 0, link: link || this.link }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.mixed-color-label {
  &__normal {
    color: var(--color-dark-grey);
    &.inherit {
      color: inherit;
    }
  }

  &__highlight {
    color: var(--color-primary);
  }

  a {
    text-decoration: underline;
  }
}
</style>
