import ImageAndText from './ImageAndText.vue'
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import TwoColumnBlock from './TwoColumnBlock.vue'

export default {
  title: 'Example/ImageAndText',
  component: ImageAndText,
  subcomponents: { MixedColorLabel, TwoColumnBlock }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ImageAndText },
  template: '<image-and-text v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  title: 'Sample Title',
  text: 'Sample Text for the component goes here and can be as long as you want it to be. It will wrap to the next line if it is too long.',
  image: 'https://via.placeholder.com/150'
}
