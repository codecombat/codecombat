import ContentBox from './ContentBox.vue'
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import LearnMoreButton from '../buttons/LearnMoreButton.vue'
import FadingImages from '../image-containers/FadingImages.vue'

export default {
  title: 'Boxes/ContentBox',
  component: ContentBox,
  argTypes: {
    arrangement: {
      control: { type: 'select' },
      options: ContentBox.arrangementOptions,
      defaultValue: ContentBox.arrangementOptions[0]
    },
    hasPadding: {
      control: 'boolean', defaultValue: false
    },
    mainImageBg: { control: 'boolean', defaultValue: false },
    image: {
      control: 'boolean',
      defaultValue: true
    },
    mainImageOriginal: {
      control: 'boolean',
      defaultValue: false
    },
    imageUrl: {
      control: 'text',
      defaultValue: '/images/pages/codequest/cc2-2.webp'
    },
    symbolImage: {
      control: 'boolean',
      defaultValue: true
    },
    title: {
      control: 'boolean',
      defaultValue: true
    },
    text: {
      control: 'boolean',
      defaultValue: true
    },
    button: {
      control: 'boolean',
      defaultValue: true
    },
    frameImage: {
      control: 'boolean',
      defaultValue: true
    },
    equalWidth: {
      control: 'boolean',
      defaultValue: false
    }
  }
}

export const Default = (args) => ({
  components: { ContentBox, MixedColorLabel, LearnMoreButton },
  props: Object.keys(args),
  template: `
    <content-box :main-image-original="mainImageOriginal" :arrangement="arrangement" :has-padding="hasPadding" :main-image-bg="mainImageBg" :equal-width="equalWidth">
      <template v-slot:image v-if="image">
          <img :src="imageUrl" />
      </template>
      <template v-slot:symbolImage v-if="symbolImage">
          <img src="/images/pages/codequest/cc2-s.webp" />
      </template>
      <template v-slot:title v-if="title">
            <mixed-color-label
                  text="Learn to __code__ and use __AI__, all through the __power of play__"
              />
      </template>
      <template v-slot:text v-if="text">
        Globally acclaimed for its cutting-edge research and innovation, UC Berkeley provides comprehensive and
            rigorous computer science programs. These programs enhance creative problem-solving skills and encourage
            a deeper understanding of computational theory, equipping individuals to be transformative leaders in
            the rapidly evolving tech industry.
      </template>
      <template v-slot:button v-if="button">
          <learn-more-button link="https://ozaria.com" target="_blank">Learn More</learn-more-button>
      </template>
      <template v-slot:frameImage v-if="frameImage">
          <img src="/images/pages/codequest/cc4-google.webp" />
      </template>
    </content-box>
  `
})

Default.args = {
  arrangement: 'vertical',
  hasPadding: false,
  mainImageBg: false,
  image: true,
  imageUrl: '/images/pages/codequest/cc2-2.webp',
  symbolImage: true,
  title: true,
  text: true,
  button: true,
  frameImage: true,
  mainImageOriginal: false
}

export const Horizontal = (args) => ({
  components: { ContentBox, MixedColorLabel, LearnMoreButton },
  props: Object.keys(args),
  template: `
    <content-box :main-image-original="mainImageOriginal" :arrangement="arrangement" :has-padding="hasPadding" :main-image-bg="mainImageBg" :equal-width="equalWidth">
      <template v-slot:image v-if="image">
          <img :src="imageUrl" />
      </template>
      <template v-slot:symbolImage v-if="symbolImage">
          <img src="/images/pages/codequest/cc2-s.webp" />
      </template>
      <template v-slot:title v-if="title">
            <mixed-color-label
                  text="Learn to __code__ and use __AI__, all through the __power of play__"
              />
      </template>
      <template v-slot:text v-if="text">
        Globally acclaimed for its cutting-edge research and innovation, UC Berkeley provides comprehensive and
            rigorous computer science programs. These programs enhance creative problem-solving skills and encourage
            a deeper understanding of computational theory, equipping individuals to be transformative leaders in
            the rapidly evolving tech industry.
      </template>
      <template v-slot:button v-if="button">
          <learn-more-button link="https://ozaria.com" target="_blank">Learn More</learn-more-button>
      </template>
      <template v-slot:frameImage v-if="frameImage">
          <img src="/images/pages/codequest/cc4-google.webp" />
      </template>
    </content-box>
  `
})

Horizontal.args = {
  arrangement: 'horizontal',
  hasPadding: false,
  mainImageBg: true,
  image: true,
  imageUrl: '/images/pages/codequest/cc2-2.webp',
  symbolImage: true,
  title: true,
  text: true,
  button: true,
  frameImage: true,
  mainImageOriginal: false
}

export const WithFadingImages = (args) => ({
  components: { ContentBox, MixedColorLabel, LearnMoreButton, FadingImages },
  props: Object.keys(args),
  template: `
      <content-box :arrangement="arrangement" :has-padding="hasPadding" :main-image-bg="mainImageBg" :equal-width="equalWidth">
        <template v-slot:image v-if="image">
            <FadingImages
            :images='[{"src":"/images/pages/codequest/coding/coding_1.jpg","alt":"Header image"},{"src":"/images/pages/codequest/coding/coding_2.jpg","alt":"Header image"},{"src":"/images/pages/codequest/coding/coding_3.jpg","alt":"Header image"}]'
            :initialIndex="0"
            :duration="2000"
        />
        </template>
        <template v-slot:symbolImage v-if="symbolImage">
            <img src="/images/pages/codequest/cc2-s.webp" />
        </template>
        <template v-slot:title v-if="title">
              <mixed-color-label
                    text="Learn to __code__ and use __AI__, all through the __power of play__"
                />
        </template>
        <template v-slot:text v-if="text">
          Globally acclaimed for its cutting-edge research and innovation, UC Berkeley provides comprehensive and
              rigorous computer science programs. These programs enhance creative problem-solving skills and encourage
              a deeper understanding of computational theory, equipping individuals to be transformative leaders in
              the rapidly evolving tech industry.
        </template>
        <template v-slot:button v-if="button">
            <learn-more-button link="https://ozaria.com" target="_blank">Learn More</learn-more-button>
        </template>
        <template v-slot:frameImage v-if="frameImage">
            <img src="/images/pages/codequest/cc4-google.webp" />
        </template>
      </content-box>
    `
})

WithFadingImages.args = {
  arrangement: 'vertical',
  hasPadding: false,
  mainImageBg: false,
  image: true,
  symbolImage: true,
  title: true,
  text: true,
  button: true,
  frameImage: true
}

export const OnlyImage = (args) => ({
  components: { ContentBox, MixedColorLabel, LearnMoreButton },
  props: Object.keys(args),
  template: `
    <content-box :arrangement="arrangement" :has-padding="hasPadding" :main-image-bg="mainImageBg" :equal-width="equalWidth">
      <template v-slot:image v-if="image">
          <img src="/images/pages/codequest/cc2-2.webp" />
      </template>
    </content-box>
  `
})
OnlyImage.args = {
  arrangement: 'vertical',
  hasPadding: false,
  mainImageBg: false,
  image: true,
  symbolImage: false,
  title: false,
  text: false,
  button: false,
  frameImage: false
}
