import HackstackPathwayCard from './HackstackPathwayCard.vue'

export default {
  title: 'Pages/HackStack/Shared/PathwayCard',
  component: HackstackPathwayCard,
}

const Template = (args, { argTypes }) => ({
  components: { HackstackPathwayCard },
  props: Object.keys(argTypes),
  template: '<HackstackPathwayCard v-bind="$props" />',
})

export const Algebra = Template.bind({})
Algebra.args = {
  variant: 'algebra',
  label: 'Step 1',
  title: 'Learn',
  description: 'Build core algebra knowledge.',
  tagText: 'Traditional',
  tagType: 'traditional',
  imageSrc: '/images/pages/hackstack/algebra/lesson-flow-step-1.png',
}

export const Cyber = Template.bind({})
Cyber.args = {
  variant: 'cyber',
  label: 'Module 1',
  title: 'Foundations',
  description: 'Build cybersecurity fundamentals.',
  tagText: 'Cybersecurity',
  imageSrc: '/images/pages/hackstack/cyber/module-1.jpg',
  iconSrc: '/images/pages/hackstack/cyber/module-icon-1.png',
  showSeparator: false,
}
