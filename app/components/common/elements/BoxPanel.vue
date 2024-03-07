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
          :signup-modal="item.signupModal"
          :data-start-on-path="item.signupModalPath"
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
                :ref="`video-${index}`"
                class="video-box"
                :video-id="item.video.videoId"
                :title="`Video to illustrate ${item.title}`"
                @loaded="onVideoLoaded(`video-${index}`, item.video.videoId)"
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
            v-if="item.link || item.signupModal"
            #button
          >
            <learn-more-button :link="item.link">
              {{ item.linkText || $t('home_v3.learn_more_text') }}
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
  },
  methods: {
    onVideoLoaded (refName, videoId, retries = 0) {
      this.$nextTick(() => {
        const videoBoxes = this.$refs[refName] || []
        videoBoxes.forEach(videoBox => {
          const containerHeight = videoBox.$el.offsetHeight
          const streamElement = videoBox.$el.firstElementChild
          const streamHeight = streamElement.offsetHeight
          if (!streamElement.offsetHeight) {
            setTimeout(() => {
              if (retries > 5) {
                // video is not loading, abort
                return
              }
              this.onVideoLoaded(refName, videoId, retries + 1)
            }, 1000)
            return
          }
          const scaleFactor = containerHeight / streamHeight
          const translateY = (streamHeight - containerHeight) / 2
          streamElement.style.transform = `scale(${scaleFactor}) translateY(${translateY * -1}px)`
        })
      })
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

.video-box {
  position: relative;

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: transparent;
    z-index: 1;
  }
}

</style>
