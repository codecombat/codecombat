<template>
  <two-column-block :reverse="reverse">
    <template #column-one>
      <content-box :main-image-bg="true">
        <template #image>
          <img :src="image">
        </template>
      </content-box>
    </template>
    <template #column-two>
      <h3 v-if="title">
        {{ title }}
      </h3>
      <p><mixed-color-label :text="text" /></p>
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
    reverse: {
      type: Boolean,
      required: false,
      default: false
    }
  }
}
</script>

<style scoped lang="scss">
</style>
