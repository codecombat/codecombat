import MixedColorLabel from './MixedColorLabel.vue'

export default {
  title: 'Labels/MixedColorLabel',
  component: MixedColorLabel,
  argTypes: {
    text: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { MixedColorLabel },
  template: '<mixed-color-label v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  text: 'Learn to __code__ and use __AI__, all through the __power of play__'
}

export const Empty = Template.bind({})
Empty.args = {
}
Empty.parameters = {
  docs: {
    description: {
      story: 'If the text is empty, no error should be thrown, nothing is rendered.'
    }
  }
}

export const Linked = Template.bind({})
Linked.args = {
  text: 'Learn to __code__ and use __AI__, all through the __power of play__',
  link: 'https://codecombat.com',
  target: '_blank'
}
