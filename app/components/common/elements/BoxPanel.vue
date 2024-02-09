<template>
  <div class="container">
    <h2
      v-if="title"
      class="text-h2"
    >
      {{ title }}
    </h2>
    <div
      class="row equal-height"
    >
      <div
        v-for="(item, index) in items"
        :key="index"
        :class="{
          'col-md-6': arrangement === 'vertical',
          'col-md-12': arrangement === 'horizontal'
        }"
      >
        <content-box
          class="box"
          :has-padding="item.hasPadding"
          :main-image-original="item.mainImageOriginal"
          :arrangement="arrangement"
          :main-image-bg="item.mainImageBg"
          :equal-width="item.equalWidth"
          :link="item.link"
          :middle-text="item.middleText"
          :middle-image="item.middleImage"
          :middle-image-alt="item.middleImageAlt"
        >
          <template #image>
            <div v-if="item.video">
              <video-box
                :alt="item.video.alt || `Video to illustrate ${item.title}`"
                :src="item.video.src"
                :padding="item.video.padding"
              />
            </div>
            <img
              v-else
              :src="item.image"
              :alt="`Image to illustrate ${item.title}`"
            >
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
import VideoBox from '../image-containers/VideoBox.vue'

const ARRANGEMENT_OPTIONS = ['horizontal', 'vertical']

export default {
  name: 'BoxPanel',
  components: {
    ContentBox,
    MixedColorLabel,
    LearnMoreButton,
    VideoBox
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
    },
    arrangement: {
      type: String,
      default: 'vertical',
      validator: function (value) {
        return ARRANGEMENT_OPTIONS.includes(value)
      }
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
  margin-bottom: 80px
}

</style>
