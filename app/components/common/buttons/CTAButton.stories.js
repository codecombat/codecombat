// CTAButton.stories.js

import CTAButton from './CTAButton.vue'

export default {
  title: 'Buttons/CTAButton',
  component: CTAButton,
  argTypes: {
    href: { control: 'text' },
    target: { control: 'text' },
    rel: { control: 'text' },
    text: { control: 'text' }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { CTAButton },
  template: '<CTAButton v-bind="$props" >{{text}}</CTAButton>'
})

export const Default = Template.bind({})
Default.args = {
  href: 'https://codecombat.com/teachers/quote',
  target: '_blank',
  rel: 'noopener noreferrer',
  text: 'I’m an Educator'
}
