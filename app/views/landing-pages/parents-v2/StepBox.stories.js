import StepBox from './StepBox.vue'
import TextBubble from './image-components/TextBubble.vue'

export default {
  title: 'Parents/StepBox',
  component: StepBox,
  argTypes: {
    title: { control: 'text' },
    subtitle: { control: 'text' },
    imageAlt: { control: 'text' },
    imageSrc: { control: 'text' },
    footerText: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { StepBox, TextBubble },
  template: `<StepBox v-bind="$props">
    <template #icon>
        <TextBubble />
    </template>
  </StepBox>`
})

export const Default = Template.bind({})
Default.args = {
  title: 'Live Instructions',
  subtitle: 'Engage',
  imageAlt: 'Image',
  imageSrc: '/images/pages/parents/steps/step_1.png',
  footerText: 'What kind of loops exist in the real world?'
}