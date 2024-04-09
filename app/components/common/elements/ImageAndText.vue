<template>
  <two-column-block :reverse="reverse">
    <template #column-one>
      <content-box :main-image-bg="true">
        <template #image>
          <img
            v-if="image"
            :src="image"
            :alt="alt || `Image to illustrate ${title}`"
          >
          <slot
            v-else
            name="image"
          />
        </template>
      </content-box>
    </template>
    <template #column-two>
      <h3
        v-if="title"
        class="text-h3"
      >
        {{ title }}
      </h3>
      <p>
        <mixed-color-label
          :text="text"
          :link="link"
        />
      </p>
      <slot />
    </template>
  </two-column-block>
</template>

<script>
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import TwoColumnBlock from './TwoColumnBlock'
import ContentBox from './ContentBox.vue'
export default {
  name: 'ImageAndText',
  components: {
    TwoColumnBlock,
    MixedColorLabel,
    ContentBox
  },
  props: {
    title: {
      type: String,
      required: false,
      default: null
    },
    text: {
      type: String,
      required: false,
      default: null
    },
    image: {
      type: String,
      required: false,
      default: null
    },
    alt: {
      type: String,
      required: false,
      default: null
    },
    reverse: {
      type: Boolean,
      required: false,
      default: false
    },
    link: {
      type: String,
      required: false,
      default: null
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.text-h3 {
  @extend %font-36;
  margin-bottom: 40px;
  color: $dark-grey;
}
</style>
