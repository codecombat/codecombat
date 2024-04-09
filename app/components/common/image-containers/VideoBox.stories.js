import VideoBox from './VideoBox.vue'

export default {
  title: 'VideoBox',
  component: VideoBox,
  argTypes: {
    alt: { control: 'text' },
    src: { control: 'text' },
    padding: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { VideoBox },
  template: '<VideoBox v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  alt: 'Sample video',
  src: 'https://iframe.videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e?letterboxColor=transparent&preload=true&poster=https://videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e/thumbnails/thumbnail.jpg%3Ftime%3D2s&defaultTextTrack=en',
  padding: '56.25%'
}
