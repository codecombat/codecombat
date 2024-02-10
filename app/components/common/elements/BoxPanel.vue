<template>
  <div class="container">
    <h2
      v-if="title"
      class="text-h2"
    >
      {{ title }}
    </h2>
    <div class="row equal-height">
      <div
        v-for="(item, index) in items"
        :key="index"
        class="col-md-6"
      >
        <content-box
          class="box"
          :has-padding="item.hasPadding"
          :main-image-original="item.mainImageOriginal"
        >
          <template #image>
            <img :src="item.image">
          </template>
          <template #title>
            {{ item.title }}
          </template>
          <template #text>
            <mixed-color-label :text="item.text" />
          </template>
          <template
            v-if="item.link"
            #button
          >
            <learn-more-button :link="item.link">
              {{ item.linkText || 'Learn More' }}
            </learn-more-button>
          </template>
          <template
            v-if="item.frameImage"
            #frameImage
          >
            <img :src="item.frameImage">
          </template>
        </content-box>
      </div>
    </div>
  </div>
</template>

<script>
import ContentBox from './ContentBox.vue'
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import LearnMoreButton from '../buttons/LearnMoreButton.vue'

export default {
  name: 'BoxPanel',
  components: {
    ContentBox,
    MixedColorLabel,
    LearnMoreButton
  },
  props: {
    title: {
      type: String,
      required: false,
      default: null
    },
    items: {
      type: Array,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
.equal-height {
    display: flex;
    flex-wrap: wrap;
    row-gap: 40px;
}

.box {
    height: 100%;
}

.text-h2 {
  text-align: center;
}

</style>
