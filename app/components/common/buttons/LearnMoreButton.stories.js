import LearnMoreButton from './LearnMoreButton.vue'

export default {
  title: 'Buttons/LearnMoreButton',
  component: LearnMoreButton,
  argTypes: {
    link: { control: 'text' },
    target: {
      control: { type: 'select' },
      options: ['_blank', '_self', '_parent', '_top']
    },
    hasArrow: { control: 'boolean' }
  }
}

export const Default = (args) => ({
  components: { LearnMoreButton },
  props: Object.keys(args),
  template: '<LearnMoreButton :link="link" :target="target" :hasArrow="hasArrow">Learn More</LearnMoreButton>'
})

Default.args = {
  link: 'https://ozaria.com',
  target: '_blank',
  hasArrow: true
}
