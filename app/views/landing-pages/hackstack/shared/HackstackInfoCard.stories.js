import HackstackInfoCard from './HackstackInfoCard.vue'

export default {
  title: 'Pages/HackStack/Shared/InfoCard',
  component: HackstackInfoCard,
  parameters: {
    layout: 'fullscreen',
  },
}

const Template = (args, { argTypes }) => ({
  components: { HackstackInfoCard },
  props: Object.keys(argTypes),
  template: '<HackstackInfoCard v-bind="$props" />',
})

export const Algebra = Template.bind({})
Algebra.args = {
  variant: 'algebra',
  imageSrc: '/images/pages/hackstack/trusted-standards.png',
  imageAlt: 'Trusted Standards',
  title: 'Trusted Standards',
  text: 'Curriculum aligned to classroom standards.',
  linkHref: 'https://codecombat.com/about',
  linkText: 'Learn more',
}

export const Cyber = Template.bind({})
Cyber.args = {
  variant: 'cyber',
  imageSrc: '/images/pages/hackstack/cyber/safety-shield.png',
  imageAlt: '',
  title: 'Safety First',
  text: 'Teach cybersecurity in a safe environment.',
  linkHref: 'https://codecombat.com/about',
  linkText: 'Learn more',
}
